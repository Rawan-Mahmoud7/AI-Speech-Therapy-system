import streamlit as st
import dropbox
from datetime import datetime
import tempfile

st.set_page_config(page_title="Audio Recorder", layout="wide")
st.title("تسجيل صوتي ورفع على Dropbox من أي جهاز")

# --------- Dropbox Access ----------
DROPBOX_ACCESS_TOKEN = st.secrets["DROPBOX_ACCESS_TOKEN"]
dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

# --------- رفع الملف على Dropbox ----------
def upload_to_dropbox(file_bytes, filename=None):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if not filename:
        filename = f"audio_{timestamp}.wav"
    dropbox_path = f"/{filename}"  # كل الملفات جوه App Folder تلقائي
    dbx.files_upload(file_bytes, dropbox_path)
    return dropbox_path

# --------- واجهة المستخدم ----------
st.markdown("### 1️⃣ سجل صوتك على جهازك أولاً")

uploaded_file = st.file_uploader(
    "اختر ملف صوتي (wav, mp3, m4a) من جهازك",
    type=["wav", "mp3", "m4a"]
)

if uploaded_file is not None:
    st.audio(uploaded_file, format='audio/wav')
    if st.button("رفع الملف على Dropbox"):
        dropbox_path = upload_to_dropbox(uploaded_file.read())
        st.success(f"تم رفع الملف على Dropbox بنجاح في: {dropbox_path}")
        st.markdown(f"[رابط الملف على Dropbox](https://www.dropbox.com/home{dropbox_path})")
