import streamlit as st
import dropbox
import numpy as np
import librosa
import io
import time
from datetime import datetime
from scipy.io.wavfile import write

# ==============================
# CONFIG
# ==============================

SAMPLE_RATE = 16000
RECORD_SECONDS = 1
MIN_RMS_THRESHOLD = 0.01
MIN_INTERVAL_BETWEEN_SUBMITS = 30

DROPBOX_ACCESS_TOKEN = st.secrets["DROPBOX_ACCESS_TOKEN"]
dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

# ==============================
# SESSION STATE
# ==============================

if "recordings" not in st.session_state:
    st.session_state.recordings = {}

if "last_submit_time" not in st.session_state:
    st.session_state.last_submit_time = 0

# توليد Speaker ID تلقائي مرة واحدة للجلسة
if "speaker_id" not in st.session_state:
    st.session_state.speaker_id = datetime.now().strftime("%Y%m%d_%H%M%S")

# ==============================
# UI
# ==============================

st.title("Arabic Speech Data Collector")

speaker_type = st.radio(
    "نوع المتكلم",
    ["نطق طبيعي", "لثغة في س", "لثغة في ر", "لثغة في س و ر"]
)

st.markdown("""
- التسجيل مدته ثانية واحدة فقط
- اقرأ الحرف مرة واحدة
- لا تضف كلمات إضافية
""")

# ==============================
# STRUCTURE
# ==============================

structure = {
    "س": ["sukun","fatha","kasra","damma"],
    "ر": ["sukun","fatha","kasra","damma"],
    "ث": ["fatha","kasra","damma"],
    "ش": ["fatha","kasra","damma"],
    "و": ["fatha","kasra","damma"],
    "ي": ["fatha","kasra","damma"],
    "ل": ["fatha","kasra","damma"]
}

if speaker_type == "لثغة في س":
    structure["س_لثغه"] = structure.pop("س")

elif speaker_type == "لثغة في ر":
    structure["ر_لثغه"] = structure.pop("ر")

elif speaker_type == "لثغة في س و ر":
    structure["س_لثغه"] = structure.pop("س")
    structure["ر_لثغه"] = structure.pop("ر")

TOTAL_REQUIRED = sum(len(v) for v in structure.values())

# ==============================
# AUDIO FUNCTIONS
# ==============================

def validate_audio(audio):
    rms = np.sqrt(np.mean(audio**2))
    return rms >= MIN_RMS_THRESHOLD

def process_audio(audio_bytes):
    audio, _ = librosa.load(io.BytesIO(audio_bytes), sr=SAMPLE_RATE, mono=True)
    target_len = SAMPLE_RATE * RECORD_SECONDS

    if len(audio) > target_len:
        audio = audio[:target_len]
    else:
        audio = np.pad(audio, (0, target_len - len(audio)))

    return audio

# ==============================
# RECORDING
# ==============================

completed = 0

for letter, harakat in structure.items():

    st.subheader(letter)

    for haraka in harakat:

        key = f"{letter}__{haraka}"
        audio_file = st.audio_input(f"{letter} - {haraka}", key=key)

        if audio_file is not None:

            raw_bytes = audio_file.read()
            audio_array, _ = librosa.load(io.BytesIO(raw_bytes), sr=None, mono=True)

            if validate_audio(audio_array):

                processed = process_audio(raw_bytes)
                buffer = io.BytesIO()
                write(buffer, SAMPLE_RATE, processed.astype(np.float32))
                buffer.seek(0)

                st.session_state.recordings[key] = buffer.read()
                st.success("✔ تم التسجيل")

            else:
                st.error("الصوت منخفض جدًا")

        if key in st.session_state.recordings:
            completed += 1

st.progress(completed / TOTAL_REQUIRED)
st.write(f"{completed} / {TOTAL_REQUIRED}")

# ==============================
# SUBMIT
# ==============================

if st.button("رفع البيانات"):

    current_time = time.time()

    if current_time - st.session_state.last_submit_time < MIN_INTERVAL_BETWEEN_SUBMITS:
        st.error("انتظر قليلاً قبل إعادة الإرسال")
        st.stop()

    if completed != TOTAL_REQUIRED:
        st.error("سجل كل الحروف أولاً")
        st.stop()

    progress_bar = st.progress(0)
    count = 0

    base_folder = f"/ArabicSpeechDataset/{speaker_type}"

    speaker_id = st.session_state.speaker_id

    for key, audio_bytes in st.session_state.recordings.items():

        letter, haraka = key.split("__")

        filename = f"{speaker_id}.wav"
        full_path = f"{base_folder}/{letter}/{haraka}/{filename}"

        dbx.files_upload(
            audio_bytes,
            full_path,
            mode=dropbox.files.WriteMode.overwrite
        )

        count += 1
        progress_bar.progress(count / TOTAL_REQUIRED)

    st.session_state.last_submit_time = current_time
    st.session_state.clear()
    st.rerun()

    st.success("🎉 تم رفع الجلسة كاملة بنجاح!")
