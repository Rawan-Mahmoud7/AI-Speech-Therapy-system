"""
Arabic Speech Pipeline
=======================
تنظيف وتعديل ملفات صوتية لتدريب نموذج تصنيف الأصوات العربية
الحروف المستهدفة: ث  ر  س  ش  ل  و  ي
"""

import os
import re
import glob
import librosa
import numpy as np
from IPython.display import display, Audio
import soundfile as sf
import pandas as pd
import torch
import torch.nn.functional as F
from tqdm import tqdm
from pathlib import Path
from sklearn.model_selection import train_test_split
from transformers import Wav2Vec2Processor, Wav2Vec2Model
from audiomentations import (
    Compose, AddGaussianNoise, PitchShift, TimeStretch,
    Gain, Shift, BandPassFilter, AddBackgroundNoise, ClippingDistortion
)

# =============================================================
# ① الإعدادات  (كل الأرقام والمسارات هنا)
# =============================================================
DATASETS = [
    "/content/drive/MyDrive/Audio_dataset/ArabicSpeechDataset",
    "/content/drive/MyDrive/Audio_dataset/kaggle_alphabet_dataset",
]
OUTPUT_DIR   = "/content/drive/MyDrive/processed2_dataset"
BG_NOISE_DIR = "/content/drive/MyDrive/assets/Background noise"

TARGET_PHONEMES = ['ث', 'ر', 'س', 'ش', 'ل', 'و', 'ي']
SAMPLE_RATE     = 16_000
N_SAMPLES       = SAMPLE_RATE          # 1 ثانية بالظبط
AUGS_PER_FILE   = 5
MAX_ATTEMPTS    = 40
augs = Compose([
    AddGaussianNoise(min_amplitude=0.01, max_amplitude=0.01, p=0.1),
    PitchShift(min_semitones=-1, max_semitones=1, p=0.3),
    TimeStretch(min_rate=0.8, max_rate=1.4, p=0.20),
    Gain(min_gain_db=-10.0, max_gain_db=5.0, p=0.10),
    Shift(min_shift=0.1, max_shift=0.2, p=0.20),
    BandPassFilter(min_center_freq=2500, max_center_freq=3000, p=0.10),
    AddBackgroundNoise(BG_NOISE_DIR, min_snr_db=10, max_snr_db=10, p=0.1) if os.path.isdir(BG_NOISE_DIR) else Gain(p=0),
    ClippingDistortion(10, 20, p=0.10),
])
# =============================================================
# ② استخراج الحرف من مسار الملف
#    يدعم البنيتين:
#    ArabicSpeechDataset   →  حرف / حركة / files
#    kaggle_alphabet_dataset → حرف / حرف+حركة / files
# =============================================================
def get_label(filepath):
    parts = Path(filepath).parts
    for part in reversed(parts[:-1]):                # kip الاسم بتاع الملف نفسه
        clean = re.sub(r'[\u064B-\u065F\u0670]', '', part.strip())   # شيل التشكيل
        if clean in TARGET_PHONEMES:
            return clean
    return None

# =============================================================
# ③ تجميع كل الملفات الصوتية
# =============================================================
def discover_files():
    all_files = []
    for dataset in DATASETS:
        for ext in ('*.wav'):
            all_files += glob.glob(os.path.join(dataset, '**', ext), recursive=True)
    return all_files

# =============================================================
# ④ تنظيف الصوت
#    resample → mono → peak-normalize → pad/truncate لثانية واحدة
# =============================================================
def clean_audio(filepath):
    try:
        audio, _ = librosa.load(filepath, sr=SAMPLE_RATE, mono=True)

        if len(audio) == 0 or np.max(np.abs(audio)) == 0:
            return None   # ملف فاضي أو صامت

        # Peak normalize → القيم بين -1 و 1
        audio = audio / np.max(np.abs(audio))

        # Padding لو أقصر من ثانية
        if len(audio) < N_SAMPLES:
            pad = N_SAMPLES - len(audio)
            audio = np.pad(audio, (pad // 2, pad - pad // 2))
        elif len(audio) > N_SAMPLES:
            # لو أطول من ثانية، اعرض الصوت للمستخدم
            print(f"\n🎧 اسمع الملف ده: {os.path.basename(filepath)}")

            # العرض ده بيشتغل في Jupter Notebook / Colab
            display(Audio(audio, rate=SAMPLE_RATE))

            while True:
                choice = input("الملف أطول من ثانية. (1) قص من الأول، (2) قص من الآخر، (3) مسح/تجاهل: ").strip()
                if choice == '1':
                    audio = audio[:N_SAMPLES]
                    break
                elif choice == '2':
                    audio = audio[-N_SAMPLES:]
                    break
                elif choice == '3':
                    return None
                else:
                    print("اختيار غير صحيح. أرجو إدخال 1 أو 2 أو 3.")

        return audio.astype(np.float32)

    except Exception as e:
        print(f"حدث خطأ في قراءة الملف {filepath}: {e}")
        return None   # ملف بايظ → تجاهله


# =============================================================
# ⑥ Wav2Vec2 للـ Embeddings والمقارنة بالـ Cosine Similarity
# =============================================================
print("Loading Wav2Vec2 model...")
device    = "cuda" if torch.cuda.is_available() else "cpu"
processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
w2v_model = Wav2Vec2Model.from_pretrained("facebook/wav2vec2-base-960h").eval().to(device)

def get_embedding(audio):
    inputs = processor(audio, sampling_rate=SAMPLE_RATE, return_tensors="pt")
    with torch.no_grad():
        hidden = w2v_model(inputs.input_values.to(device)).last_hidden_state
    return hidden.mean(dim=1).squeeze()

def cosine_sim(a, b):
    # a and b should be 1D tensors, F.cosine_similarity expects 2D (batch_size, dims)
    # so we add a batch dimension of size 1 and get the first item
    return F.cosine_similarity(a.unsqueeze(0), b.unsqueeze(0)).item()

# =============================================================
# ⑦ فلترة الـ Augmentations بالـ Similarity
#    - يقارن كل نسخة بالأصل (0.93 ≤ sim ≤ 0.97)
#    - يقارن بكل النسخ المقبولة قبله (sim < 0.97)
# =============================================================
def generate_augmentations(original_audio, original_emb, label, label_dir, base_name):
    accepted = []
    accepted_embs = []

    for attempt in range(MAX_ATTEMPTS):
        if len(accepted) == AUGS_PER_FILE:
            break

        # تطبيق التعديل
        aug_audio = augs(samples=original_audio.copy(), sample_rate=SAMPLE_RATE)

        # ضمان الطول ثانية واحدة بعد التعديل
        if len(aug_audio) < N_SAMPLES:
            pad = N_SAMPLES - len(aug_audio)
            aug_audio = np.pad(aug_audio, (pad // 2, pad - pad // 2))
        else:
            aug_audio = aug_audio[:N_SAMPLES]

        aug_emb = get_embedding(aug_audio)

        # شرط الجودة: مش أقل من 0.93 ومش أكتر من 0.97 مقارنةً بالأصل
        sim_to_original = cosine_sim(aug_emb, original_emb)
        if not (0.93 <= sim_to_original <= 0.97):
            continue

        # شرط التنوع: مش مشابه لأي نسخة معدلة اتقبلت قبله
        too_similar = any(cosine_sim(aug_emb, prev) > 0.97 for prev in accepted_embs)
        if too_similar:
            continue

        # حفظ النسخة المعدلة
        idx = len(accepted) + 1
        save_path = os.path.join(label_dir, f"aug_{idx}_{base_name}.wav")
        sf.write(save_path, aug_audio, SAMPLE_RATE)

        accepted.append(save_path)
        accepted_embs.append(aug_emb)

    if len(accepted) < AUGS_PER_FILE:
        print(f"  ⚠ {base_name}: تم قبول {len(accepted)}/{AUGS_PER_FILE} فقط بعد {MAX_ATTEMPTS} محاولة")

    return accepted

# =============================================================
# ⑧ البرنامج الرئيسي
# =============================================================
def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    all_rows = []   # بيانات الـ manifest

    # ③ جمع الملفات
    all_files = discover_files()
    print(f"تم العثور على {len(all_files)} ملف. جاري المعالجة...\n")

    for filepath in tqdm(all_files, desc="🔧 Processing"):

        # استخرج الحرف من المسار
        label = get_label(filepath)
        if label is None:
            continue

        label_dir = os.path.join(OUTPUT_DIR, label)
        os.makedirs(label_dir, exist_ok=True)

        # ④ تنظيف الصوت
        audio = clean_audio(filepath)
        if audio is None:
            continue

        # احفظ النسخة الأصلية المنظفة
        base_name = os.path.splitext(os.path.basename(filepath))[0]
        clean_path = os.path.join(label_dir, f"{base_name}_clean.wav")
        sf.write(clean_path, audio, SAMPLE_RATE)
        all_rows.append({"file_path": clean_path, "label": label, "type": "original"})

        # ⑦ توليد الـ Augmentations
        original_emb = get_embedding(audio)
        aug_paths = generate_augmentations(audio, original_emb, label, label_dir, base_name)

        for p in aug_paths:
            all_rows.append({"file_path": p, "label": label, "type": "augmented"})

    # =============================================================
    # Manifest CSV + Stratified 80 / 10 / 10 Split
    # =============================================================
    df = pd.DataFrame(all_rows)

    originals = df[df["type"] == "original"].copy()
    augmented = df[df["type"] == "augmented"].copy()

    try:
        train, temp = train_test_split(originals, test_size= v, stratify=originals["label"], random_state=42)
        val, test   = train_test_split(temp,      test_size=0.5, stratify=temp["label"],      random_state=42)
    except ValueError:
        # لو الداتا صغيرة جداً ومتعملش stratify
        train, temp = train_test_split(originals, test_size=0.2, random_state=42)
        val, test   = train_test_split(temp,      test_size=0.5, random_state=42)

    train["split"]    = "train"
    val["split"]      = "val"
    test["split"]     = "test"
    augmented["split"] = "train"          # الـ augmentations للـ train فقط

    manifest = pd.concat([train, augmented, val, test])
    manifest = manifest[["file_path", "label", "split"]]
    manifest_path = os.path.join(OUTPUT_DIR, "manifest.csv")
    manifest.to_csv(manifest_path, index=False, encoding="utf-8-sig")

    # ملخص
    print("\n✅ انتهى!")
    print(f"   الملفات الأصلية : {len(originals)}")
    print(f"   الملفات المعدلة : {len(augmented)}")
    print(f"   إجمالي الـ CSV  : {len(manifest)} صف")
    print(f"   تم الحفظ في     : {manifest_path}")

if __name__ == "__main__":
    main()
