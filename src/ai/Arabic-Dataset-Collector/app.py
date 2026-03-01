import streamlit as st
import numpy as np
import librosa
import io
import time
from scipy.io.wavfile import write
from datetime import datetime
import dropbox

# =========================
# CONFIG
# =========================

SAMPLE_RATE = 16000
DURATION = 1
MIN_RMS_THRESHOLD = 0.01
MIN_INTERVAL_BETWEEN_SUBMITS = 60  # seconds rate limit

DROPBOX_ACCESS_TOKEN = st.secrets["DROPBOX_ACCESS_TOKEN"]  # خلي الـ token هنا
dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

# =========================
# DATA STRUCTURE
# =========================

structure = {
    "س": ["sukun","fatha","kasra","damma"],
    "س_لثغه": ["sukun","fatha","kasra","damma"],
    "ث": ["fatha","kasra","damma"],
    "ش": ["fatha","kasra","damma"],
    "ر": ["sukun","fatha","kasra","damma"],
    "ر_لثغه": ["sukun","fatha","kasra","damma"],
    "و": ["fatha","kasra","damma"],
    "ي": ["fatha","kasra","damma"],
    "ل": ["fatha","kasra","damma"]
}

TOTAL_REQUIRED = sum(len(v) for v in structure.values())

# =========================
# SESSION STATE
# =========================

if "recordings" not in st.session_state:
    st.session_state.recordings = {}

if "last_submit_time" not in st.session_state:
    st.session_state.last_submit_time = 0

# =========================
# UI
# =========================

st.title("Arabic Speech Data Collector - Dropbox Version")

patient_id = st.text_input("Patient ID")

st.markdown("""
### تعليمات:
- اقرأ الحرف مرة واحدة فقط
- لا تضف أي كلمة قبله أو بعده
- انتظر العد 1..2..3 ثم انطق
- المدة تقريباً ثانية
""")

# =========================
# AUDIO VALIDATION
# =========================

def validate_audio(audio):
    rms = np.sqrt(np.mean(audio**2))
    if rms < MIN_RMS_THRESHOLD:
        return False, "الصوت منخفض جداً أو لم يتم النطق"
    return True, None

# =========================
# PROCESS AUDIO
# =========================

def process_audio(audio_bytes):
    audio, sr = librosa.load(io.BytesIO(audio_bytes), sr=SAMPLE_RATE, mono=True)
    audio = librosa.util.normalize(audio)
    if len(audio) > SAMPLE_RATE:
        audio = audio[:SAMPLE_RATE]
    else:
        padding = SAMPLE_RATE - len(audio)
        audio = np.pad(audio, (0, padding))
    return audio

# =========================
# DROPBOX HELPERS
# =========================

def create_folder_if_not_exists(path):
    try:
        dbx.files_get_metadata(path)
    except dropbox.exceptions.ApiError:
        dbx.files_create_folder_v2(path)

def upload_file(file_bytes, dropbox_path):
    dbx.files_upload(file_bytes, dropbox_path)
    return dropbox_path

# =========================
# RECORDING UI
# =========================

completed = 0

for letter, harakat in structure.items():
    st.subheader(letter)

    for haraka in harakat:
        key = f"{letter}__{haraka}"
        audio_file = st.audio_input(f"سجل {letter} - {haraka}", key=key)

        if audio_file is not None:
            audio_bytes = audio_file.read()
            audio_array, _ = librosa.load(io.BytesIO(audio_bytes), sr=None, mono=True)

            valid, error = validate_audio(audio_array)

            if valid:
                st.session_state.recordings[key] = audio_bytes
                st.success("تم التسجيل")
            else:
                st.error(error)

        if key in st.session_state.recordings:
            completed += 1

# =========================
# PROGRESS
# =========================

st.progress(completed / TOTAL_REQUIRED)
st.write(f"{completed} / {TOTAL_REQUIRED} تسجيل مكتمل")

# =========================
# SUBMIT
# =========================

if st.button("إنهاء ورفع البيانات"):

    current_time = time.time()

    if current_time - st.session_state.last_submit_time < MIN_INTERVAL_BETWEEN_SUBMITS:
        st.error("يرجى الانتظار قبل إعادة الإرسال")
        st.stop()

    if not patient_id:
        st.error("أدخل Patient ID")
        st.stop()

    if completed != TOTAL_REQUIRED:
        st.error("يجب تسجيل كل الحروف أولاً")
        st.stop()

    progress_bar = st.progress(0)
    count = 0

    for key, audio_bytes in st.session_state.recordings.items():
        letter, haraka = key.split("__")
        processed = process_audio(audio_bytes)

        buffer = io.BytesIO()
        write(buffer, SAMPLE_RATE, processed.astype(np.float32))
        buffer.seek(0)

        # إنشاء فولدرات داخل Dropbox
        letter_folder = f"/{letter}"
        haraka_folder = f"{letter_folder}/{haraka}"
        create_folder_if_not_exists(letter_folder)
        create_folder_if_not_exists(haraka_folder)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{patient_id}_{letter}_{haraka}_{timestamp}.wav"
        dropbox_path = f"{haraka_folder}/{filename}"

        try:
            upload_file(buffer.read(), dropbox_path)
        except Exception as e:
            st.error("Upload Error:")
            st.write(str(e))
            raise e

        count += 1
        progress_bar.progress(count / TOTAL_REQUIRED)

    st.session_state.last_submit_time = current_time
    st.session_state.recordings = {}

    st.success("🎉 تم رفع جميع الملفات بنجاح")
