import streamlit as st
import dropbox
from datetime import datetime
import tempfile
import base64

st.set_page_config(page_title="Audio Recorder", layout="wide")
st.title("تسجيل صوتي مباشر ورفع على Dropbox")

# ---------------- Dropbox ----------------
DROPBOX_ACCESS_TOKEN = "حطي هنا Access Token بتاعك"
dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

def upload_to_dropbox(file_bytes, filename=None):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if not filename:
        filename = f"audio_{timestamp}.wav"
    dropbox_path = f"/{filename}"  # داخل App folder تلقائي
    dbx.files_upload(file_bytes, dropbox_path)
    return dropbox_path

# ---------------- تسجيل الصوت ----------------
st.markdown("### اضغط على الزرار وسجل صوتك مباشرة من المتصفح:")

# HTML + JS لتسجيل الصوت
RECORD_HTML = """
<script>
let recorder;
let audioStream;
let chunks = [];
let recording = false;

function startRecording() {
    navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
        audioStream = stream;
        recorder = new MediaRecorder(stream);
        recorder.ondataavailable = e => chunks.push(e.data);
        recorder.onstop = e => {
            let blob = new Blob(chunks, { 'type' : 'audio/wav; codecs=opus' });
            let reader = new FileReader();
            reader.readAsDataURL(blob);
            reader.onloadend = function() {
                let base64data = reader.result.split(',')[1];
                const pyFunc = window.parent.streamlitWebRTC;
                window.parent.postMessage({func:'upload_audio', data: base64data}, '*')
            }
        }
        recorder.start();
        recording = true;
        document.getElementById("status").innerText = "Recording...";
    });
}

function stopRecording() {
    recorder.stop();
    audioStream.getTracks().forEach(track => track.stop());
    document.getElementById("status").innerText = "Recording stopped.";
}

</script>
<button onclick="startRecording()">ابدأ التسجيل</button>
<button onclick="stopRecording()">أوقف التسجيل</button>
<p id="status">Ready</p>
"""

st.components.v1.html(RECORD_HTML, height=150)

# ---------------- رفع الصوت من Base64 ----------------
if 'upload_audio' not in st.session_state:
    st.session_state.upload_audio = None

def decode_and_upload_audio(base64_data):
    file_bytes = base64.b64decode(base64_data)
    dropbox_path = upload_to_dropbox(file_bytes)
    st.success(f"تم رفع التسجيل على Dropbox: {dropbox_path}")
    st.markdown(f"[رابط الملف على Dropbox](https://www.dropbox.com/home{dropbox_path})")

# هذا الجزء سيتم تشغيله عندما يتم إرسال البيانات من JS
if st.session_state.upload_audio:
    decode_and_upload_audio(st.session_state.upload_audio)
