import streamlit as st
import dropbox
from datetime import datetime

st.title("🔴 Dropbox Audio Test")

# هتحطي التوكن في Secrets مش هنا
DROPBOX_ACCESS_TOKEN = st.secrets["DROPBOX_ACCESS_TOKEN"]

dbx = dropbox.Dropbox(DROPBOX_ACCESS_TOKEN)

st.write("اضغط وسجل، وبعدين ارفع عشان نجرب التخزين")

audio_file = st.audio_input("سجل صوتك")

if audio_file is not None:
    st.audio(audio_file)

    if st.button("رفع التسجيل"):
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"/test_{timestamp}.wav"

            dbx.files_upload(
                audio_file.read(),
                filename,
                mode=dropbox.files.WriteMode.overwrite
            )

            st.success("✅ التسجيل اتحفظ في Dropbox بنجاح!")
            st.write("اسم الملف:", filename)

        except Exception as e:
            st.error("حصل خطأ:")
            st.write(str(e))
