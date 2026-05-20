import torch
import os
import evaluate
import numpy as np
import pandas as pd
import wandb
from pathlib import Path
from datasets import Dataset, DatasetDict, Audio
from transformers import (
    AutoFeatureExtractor,
    AutoModelForAudioClassification,
    TrainingArguments,
    Trainer,
    EarlyStoppingCallback
)
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

# ==========================================
# 0. Configuration
# ==========================================
MANIFEST_PATH = "/content/drive/MyDrive/processed2_dataset/manifest.csv"
OUTPUT_DIR    = "/content/drive/MyDrive/Grad-project-implement/models"
WANDB_PROJECT = "arabic-phoneme-classification"

# You can easily swap these out to test which is better!
# Option 1: facebook/wav2vec2-base
# Option 2: openai/whisper-tiny (or base)
# Option 3: MIT/ast-finetuned-audioset-10-10-0.4593
MODEL_ID = "facebook/wav2vec2-base"

TARGET_PHONEMES = ['ث', 'ر', 'س', 'ش', 'ل', 'و', 'ي']
ID2LABEL = {i: label for i, label in enumerate(TARGET_PHONEMES)}
LABEL2ID = {label: i for i, label in enumerate(TARGET_PHONEMES)}

# Training Hyperparams
BATCH_SIZE = 32
LEARNING_RATE = 3e-5
EPOCHS = 20

# ==========================================
# 1. WandB Login
# ==========================================
# This will trigger a login prompt if you are not already logged in.
# On Colab, you can set the WANDB_API_KEY environment variable beforehand.
wandb.login()

# ==========================================
# 2. Load and Prepare Dataset
# ==========================================
print("Loading dataset from manifest...")
if not os.path.exists(MANIFEST_PATH):
    raise FileNotFoundError(f"Manifest not found at {MANIFEST_PATH}. Did you run the preprocessing pipeline?")

df = pd.read_csv(MANIFEST_PATH)

# Convert labels to integers
df['label_id'] = df['label'].map(LABEL2ID)

# Split back into Hugging Face DatasetDict based on our splits
train_df = df[df['split'] == 'train'].reset_index(drop=True)
val_df   = df[df['split'] == 'val'].reset_index(drop=True)
test_df  = df[df['split'] == 'test'].reset_index(drop=True)

raw_datasets = DatasetDict({
    "train": Dataset.from_pandas(train_df),
    "validation": Dataset.from_pandas(val_df),
    "test": Dataset.from_pandas(test_df)
})

# We must cast the file_path column to an Audio feature so HF automatically reads the WAV files
raw_datasets = raw_datasets.cast_column("file_path", Audio(sampling_rate=16000))

# ==========================================
# 3. Feature Extraction
# ==========================================
print(f"Loading feature extractor for {MODEL_ID}...")
feature_extractor = AutoFeatureExtractor.from_pretrained(MODEL_ID)

def preprocess_function(examples):
    # HF audio objects load the array and sampling rate
    audio_arrays = [x["array"] for x in examples["file_path"]]

    # Process audio through the model's feature extractor (padding/truncating as needed)
    inputs = feature_extractor(
        audio_arrays,
        sampling_rate=16000,
        max_length=16000,     # exactly 1 second
        truncation=True,
        padding="max_length"
    )
    # Add the labels
    inputs["label"] = examples["label_id"]
    return inputs

print("Extracting features (this might take a few minutes)...")
encoded_datasets = raw_datasets.map(preprocess_function, batched=True, batch_size=32, remove_columns=raw_datasets["train"].column_names)

# ==========================================
# 4. Model Setup
# ==========================================
print("Initializing model...")
model = AutoModelForAudioClassification.from_pretrained(
    MODEL_ID,
    num_labels=len(TARGET_PHONEMES),
    label2id=LABEL2ID,
    id2label=ID2LABEL,
    ignore_mismatched_sizes=True # Important if the pre-trained model had a different number of classes
)

# Initialize WandB Run
run_name = f"{MODEL_ID.split('/')[-1]}-lr{LEARNING_RATE}-bs{BATCH_SIZE}"
wandb.init(project=WANDB_PROJECT, name=run_name, config={
    "model": MODEL_ID,
    "batch_size": BATCH_SIZE,
    "learning_rate": LEARNING_RATE,
    "epochs": EPOCHS
})

# ==========================================
# 5. Metrics Definition
# ==========================================
accuracy_metric = evaluate.load("accuracy")
f1_metric = evaluate.load("f1")

def compute_metrics(eval_pred):
    predictions = np.argmax(eval_pred.predictions, axis=1)
    labels = eval_pred.label_ids

    acc = accuracy_metric.compute(predictions=predictions, references=labels)
    f1 = f1_metric.compute(predictions=predictions, references=labels, average="weighted")

    return {
        "accuracy": acc["accuracy"],
        "f1": f1["f1"]
    }
# ==========================================
# 6. Training Setup
# ==========================================
training_args = TrainingArguments(
    output_dir=OUTPUT_DIR,
    eval_strategy="epoch",
    save_strategy="epoch",
    learning_rate=LEARNING_RATE,
    per_device_train_batch_size=BATCH_SIZE,
    per_device_eval_batch_size=BATCH_SIZE,
    num_train_epochs=EPOCHS,
    warmup_ratio=0.1,
    logging_steps=10,
    load_best_model_at_end=True,
    metric_for_best_model="f1",
    report_to="wandb", # Tell HF to log everything to WandB automatically!
    run_name=run_name,
    fp16=torch.cuda.is_available(), # Use mixed precision if GPU is available (faster)
)

trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=encoded_datasets["train"],
    eval_dataset=encoded_datasets["validation"],
    compute_metrics=compute_metrics,
    callbacks=[EarlyStoppingCallback(early_stopping_patience=3)] # Stop if validation stops improving
)

# ==========================================
# 7. Start Training
# ==========================================
print("Starting training...")
trainer.train()

# ==========================================
# 8. Evaluation & Confusion Matrix
# ==========================================
print("Evaluating on test set...")
test_results = trainer.evaluate(encoded_datasets["test"], metric_key_prefix="test")
print("Test Results:", test_results)

# Generate Predictions for Confusion Matrix
predictions = trainer.predict(encoded_datasets["test"])
y_pred = np.argmax(predictions.predictions, axis=1)
y_true = predictions.label_ids

# Print detailed Classification Report
print("\nClassification Report:")
print(classification_report(y_true, y_pred, target_names=TARGET_PHONEMES))

# Plot Confusion Matrix and log to WandB
cm = confusion_matrix(y_true, y_pred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=TARGET_PHONEMES, yticklabels=TARGET_PHONEMES)
plt.xlabel('Predicted')
plt.ylabel('True')
plt.title(f'Confusion Matrix - {MODEL_ID}')

# Log the plot directly to WandB
wandb.log({"confusion_matrix_plot": wandb.Image(plt)})
plt.close()

# Save final model locally
final_model_path = os.path.join(OUTPUT_DIR, "best_model")
trainer.save_model(final_model_path)
feature_extractor.save_pretrained(final_model_path)
print(f"Best model saved to {final_model_path}")

# End WandB run
wandb.finish()
