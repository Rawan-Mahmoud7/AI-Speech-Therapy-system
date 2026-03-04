import streamlit as st
import dropbox
import numpy as np
import librosa
import io
import time
import uuid
from datetime import datetime
from scipy.io.wavfile import write
# ==============================
# CONFIG
# ==============================

SAMPLE_RATE = 16000
RECORD_SECONDS = 1
MIN_RMS_THRESHOLD = 0.01
MIN_INTERVAL_BETWEEN_SUBMITS = 30

dbx = dropbox.Dropbox(
    app_key=st.secrets["DROPBOX_APP_KEY"],
    app_secret=st.secrets["DROPBOX_APP_SECRET"],
    oauth2_refresh_token=st.secrets["DROPBOX_REFRESH_TOKEN"],
)

# ==============================
# SESSION STATE
# ==============================

if "recordings" not in st.session_state:
    st.session_state.recordings = {}

if "last_submit_time" not in st.session_state:
    st.session_state.last_submit_time = 0

if "speaker_id" not in st.session_state:
    st.session_state.speaker_id = f"speaker_{uuid.uuid4().hex[:12]}"

# ==============================
# UI
# ==============================

st.title("Arabic Speech Data Collector")

speaker_type = st.radio(
    "نوع المتكلم",
    ["نطق طبيعي", "لثغة في س","لثغة في ر" , "لثغة في س / ر"]
)

st.markdown("""
- التسجيل مدته ثانية واحدة بس ياريت المكان يبقي هادي والنطق يبقي في الثانيه ميزدش التسجيل عن ثانيه 
- اقرأ الحرف مرة واحدة
- 'انطق الحرف صوت الحرف مش الكلمه مثال 'س' مش 'سين 
-  لا تضف كلمات إضافية
- اضغط علي علامه المايك عشان تعيد التسجيل لو مش مظبوط 
""")

# ==============================
# STRUCTURE
# ==============================

structure = {
    "س": ["سكون","فتحه","كسره","ضمه"],
    "ر": ["سكون","فتحه","كسره","ضمه"],
    "ث": ["فتحه","كسره","ضمه"],
    "ش": ["فتحه","كسره","ضمه"],
    "و": ["فتحه","كسره","ضمه"],
    "ي": ["فتحه","كسره","ضمه"],
    "ل": ["فتحه","كسره","ضمه"]
}

if speaker_type == "لثغة في س":
    structure["س_لثغه"] = structure.pop("س")

elif speaker_type == "لثغة في ر":
    structure["ر_لثغه"] = structure.pop("ر")

elif speaker_type == "لثغة في س / ر":
    structure["س_لثغه"] = structure.pop("س")
    structure["ر_لثغه"] = structure.pop("ر")

TOTAL_REQUIRED = sum(len(v) for v in structure.values())

# ==============================
# AUDIO FUNCTIONS
# ==============================
def validate_audio(audio):

    if len(audio) == 0:
        return False, "مفيش صوت واضح"

    audio = audio.astype(np.float32)

    if np.max(np.abs(audio)) > 0:
        audio = audio / np.max(np.abs(audio))

    global_rms = np.sqrt(np.mean(audio**2))
    if global_rms < 0.01:
        return False, "الصوت ضعيف جدًا"

    frame_size = 400
    hop_size = 160

    energies = []

    for i in range(0, len(audio) - frame_size, hop_size):
        frame = audio[i:i+frame_size]
        frame_rms = np.sqrt(np.mean(frame**2))
        energies.append(frame_rms)

    if len(energies) == 0:
        return False, "التسجيل قصير جدًا"

    energies = np.array(energies)

    threshold = np.mean(energies) * 1.2
    speech_frames = energies > threshold

    speech_ratio = np.sum(speech_frames) / len(energies)

    if speech_ratio < 0.2:
        return False, "الصوت قصير أو أغلبه صمت"

    return True, None

def process_audio_clean(audio_bytes, sample_rate=16000):

    # Decode + Resample + Mono
    audio, sr = librosa.load(
        io.BytesIO(audio_bytes),
        sr=sample_rate,      
        mono=True
    )

    audio = audio - np.mean(audio)

    audio, _ = librosa.effects.trim(
        audio,
        top_db=30   
    )

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
            processed = process_audio_clean(raw_bytes)
            is_valid, msg = validate_audio(processed)
            if not is_valid:
                st.warning(msg)
            else:
                buffer = io.BytesIO()
                write(buffer, SAMPLE_RATE, processed.astype(np.float32))
                buffer.seek(0)
            
                st.session_state.recordings[key] = buffer.read()
                st.success("✔ تم التسجيل")
           
            
        if key in st.session_state.recordings:
            completed += 1

st.progress(completed / TOTAL_REQUIRED)
st.write(f"{completed} / {TOTAL_REQUIRED}")

# ==============================
# SUBMIT
# ==============================
def ensure_folder(path):
    try:
        dbx.files_get_metadata(path)
    except dropbox.exceptions.ApiError:
        dbx.files_create_folder_v2(path)
        
if st.button("SUBMIT"):

    current_time = time.time()

    if current_time - st.session_state.last_submit_time < MIN_INTERVAL_BETWEEN_SUBMITS:
        st.error("انتظر قليلاً قبل إعادة الإرسال")
        st.stop()

    if completed != TOTAL_REQUIRED:
        st.error("سجل كل الحروف الاول")
        st.stop()

    progress_bar = st.progress(0)
    count = 0

    base_folder = f"/ArabicSpeechDataset/{speaker_type}"
    ensure_folder(base_folder)
    speaker_id = st.session_state.speaker_id
    for letter, harakat in structure.items():
        ensure_folder(f"{base_folder}/{letter}")
    for haraka in harakat:
        ensure_folder(f"{base_folder}/{letter}/{haraka}")

    for key, audio_bytes in st.session_state.recordings.items():

        letter, haraka = key.split("__")

        filename = f"{speaker_id}_{letter}_{haraka}_{int(time.time())}.wav"
        folder_path = f"{base_folder}/{letter}/{haraka}"
        full_path = f"{folder_path}/{filename}"
        
        dbx.files_upload(
            audio_bytes,
            full_path,
            mode=dropbox.files.WriteMode.overwrite
        )

        count += 1
        progress_bar.progress(count / TOTAL_REQUIRED)

    st.session_state.last_submit_time = current_time
    st.session_state.recordings = {}
    st.session_state.clear()

    #st.success("🎉 تم رفع البيانات كاملة بنجاح!")
