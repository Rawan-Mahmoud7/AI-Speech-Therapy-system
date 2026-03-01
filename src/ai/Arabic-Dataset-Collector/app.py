import streamlit as st
from streamlit_webrtc import webrtc_streamer, AudioProcessorBase, WebRtcMode
import av
import numpy as np
from pydub import AudioSegment
import tempfile
import dropbox
from datetime import datetime

st.title("تسجيل صوتي ورفع على Dropbox من الموبايل أو الكمبيوتر")

# ---------------- Dropbox Access ----------------
DROPBOX_ACCESS_TOKEN = st.secrets["DROPBOX_ACCESS_TOKEN"]
dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

# ---------------- تسجيل الصوت ----------------
class AudioRecorder(AudioProcessorBase):
    def __init__(self):
        self.frames = []

    def recv(self, frame: av.AudioFrame):
        self.frames.append(frame.to_ndarray())
        return frame

webrtc_ctx = webrtc_streamer(
    key="audio-recorder",
    mode=WebRtcMode.SENDRECV,
    audio_processor_factory=AudioRecorder,
    media_stream_constraints={"audio": True, "video": False},
    async_processing=True,
)

# ---------------- رفع الصوت ----------------
def upload_to_dropbox(file_path):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dropbox_path = f"/audio_{timestamp}.wav"  # كل ملف داخل App folder تلقائي
    with open(file_path, "rb") as f:
        dbx.files_upload(f.read(), dropbox_path)
    return dropbox_path

# ---------------- واجهة المستخدم ----------------
if webrtc_ctx.audio_processor:
    if st.button("حفظ ورفع التسجيل"):
        frames = webrtc_ctx.audio_processor.frames
        if frames:
            audio_array = np.concatenate(frames, axis=1)
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                temp_file_path = f.name
                sound = AudioSegment(
                    audio_array.tobytes(),
                    frame_rate=48000,
                    sample_width=audio_array.dtype.itemsize,
                    channels=1
                )
                sound.export(temp_file_path, format="wav")
            # رفع على Dropbox
            dropbox_path = upload_to_dropbox(temp_file_path)
            st.success(f"تم رفع التسجيل على Dropbox في: {dropbox_path}")
