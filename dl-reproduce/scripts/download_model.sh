#!/bin/bash
# ============================================
# Model/Data Download Script
# Usage:
#   bash scripts/download_model.sh huggingface meta-llama/Llama-2-7b-hf ./models
#   bash scripts/download_model.sh url https://example.com/model.bin ./
#   bash scripts/download_model.sh github user/repo ./
#   bash scripts/download_model.sh kaggle user/dataset ./data
# ============================================

SOURCE=${1:-huggingface}
MODEL_ID=${2:-}
OUTPUT_DIR=${3:-"./models"}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ -z "$MODEL_ID" ]; then
    echo "Usage: bash download_model.sh <source> <identifier> [output_dir]"
    echo ""
    echo "Sources:"
    echo "  huggingface  <org/model>         Download from HuggingFace Hub"
    echo "  url          <direct_url>        Download from direct URL"
    echo "  github       <user/repo>         Clone from GitHub"
    echo "  kaggle       <user/dataset>      Download from Kaggle"
    echo ""
    echo "Examples:"
    echo "  bash download_model.sh huggingface meta-llama/Llama-2-7b-hf ./models/llama2"
    echo "  bash download_model.sh url https://example.com/model.bin ./"
    exit 0
fi

echo "=========================================="
echo "  Download: $MODEL_ID"
echo "  Source: $SOURCE → $OUTPUT_DIR"
echo "=========================================="

mkdir -p "$OUTPUT_DIR"

# ============================================
# HuggingFace Download
# ============================================
download_huggingface() {
    # Ensure huggingface_hub is installed
    pip show huggingface_hub > /dev/null 2>&1 || pip install huggingface_hub

    # Check auth for gated models
    python -c "
from huggingface_hub import HfApi
try:
    token = HfApi().token
    if token:
        print('HuggingFace: Authenticated')
    else:
        print('HuggingFace: Not logged in (gated models will fail)')
        print('  → Run: huggingface-cli login')
except:
    print('HuggingFace: Auth check failed')
" 2>/dev/null

    # Check for HF mirror
    if [ -n "$HF_ENDPOINT" ]; then
        echo "Using HF mirror: $HF_ENDPOINT"
    fi

    # Download with resume support
    python -c "
from huggingface_hub import snapshot_download
import sys

try:
    path = snapshot_download(
        repo_id='$MODEL_ID',
        local_dir='$OUTPUT_DIR',
        resume_download=True,
        max_workers=4,
    )
    print(f'Downloaded to: {path}')
except Exception as e:
    error_msg = str(e)
    if '401' in error_msg or '403' in error_msg:
        print(f'ACCESS DENIED: {e}')
        print()
        print('This is likely a gated model. To fix:')
        print('1. Visit https://huggingface.co/$MODEL_ID and accept the license')
        print('2. Run: huggingface-cli login')
        print('3. Retry this download')
    elif '404' in error_msg:
        print(f'NOT FOUND: {e}')
        print('Check the model ID — it should be like \"org/model-name\"')
    else:
        print(f'Error: {e}')
    sys.exit(1)
"
}

# ============================================
# GitHub Download
# ============================================
download_github() {
    REPO_URL="https://github.com/$MODEL_ID.git"

    if command -v git &> /dev/null; then
        echo "Cloning $REPO_URL (shallow)..."
        git clone --depth 1 "$REPO_URL" "$OUTPUT_DIR"
    else
        echo "git not found — downloading zip..."
        ZIP_URL="https://github.com/$MODEL_ID/archive/refs/heads/main.zip"
        if command -v curl &> /dev/null; then
            curl -L "$ZIP_URL" -o "${OUTPUT_DIR}.zip"
        elif command -v wget &> /dev/null; then
            wget "$ZIP_URL" -O "${OUTPUT_DIR}.zip"
        fi
        unzip "${OUTPUT_DIR}.zip" -d "$OUTPUT_DIR"
    fi
}

# ============================================
# Direct URL Download
# ============================================
download_url() {
    FILENAME=$(basename "$MODEL_ID")

    if command -v curl &> /dev/null; then
        curl -L -C - "$MODEL_ID" -o "$OUTPUT_DIR/$FILENAME"  # -C - enables resume
    elif command -v wget &> /dev/null; then
        wget -c "$MODEL_ID" -O "$OUTPUT_DIR/$FILENAME"  # -c enables resume
    else
        echo "ERROR: curl or wget required"
        exit 1
    fi
}

# ============================================
# Kaggle Download
# ============================================
download_kaggle() {
    pip show kaggle > /dev/null 2>&1 || pip install kaggle

    if [ ! -f "$HOME/.kaggle/kaggle.json" ]; then
        echo "ERROR: Kaggle API key required"
        echo "1. Go to https://www.kaggle.com/settings → API → Create New Token"
        echo "2. Save kaggle.json to ~/.kaggle/"
        echo "3. chmod 600 ~/.kaggle/kaggle.json"
        exit 1
    fi

    kaggle datasets download -d "$MODEL_ID" -p "$OUTPUT_DIR" --unzip
}

# ============================================
# Execute
# ============================================
case $SOURCE in
    huggingface) download_huggingface ;;
    github)      download_github ;;
    url)         download_url ;;
    kaggle)      download_kaggle ;;
    *)           echo "Unknown source: $SOURCE"; exit 1 ;;
esac

# ============================================
# Verify
# ============================================
echo ""
echo "=========================================="
if [ -d "$OUTPUT_DIR" ]; then
    FILE_COUNT=$(find "$OUTPUT_DIR" -type f | wc -l)
    TOTAL_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
    echo "Download complete: $FILE_COUNT files, $TOTAL_SIZE"
    echo "Location: $OUTPUT_DIR"
else
    echo "Download FAILED — check errors above"
    exit 1
fi
echo "=========================================="
