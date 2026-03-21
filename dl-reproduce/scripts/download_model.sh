#!/bin/bash
# ============================================
# Model/Data Download Script Template
# Usage:
#   bash scripts/download_model.sh [model_id] [output_dir]
#   bash scripts/download_model.sh huggingface meta-llama/Llama-2-7b-hf ./models
# ============================================

# Default parameters
SOURCE=${1:-huggingface}
MODEL_ID=${2:-}
OUTPUT_DIR=${3:-"./models"}

# Help information
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: bash download_model.sh <source> <model_id> <output_dir>"
    echo ""
    echo "Parameters:"
    echo "  source    Download source: huggingface, github, url (default: huggingface)"
    echo "  model_id  Model identifier"
    echo "           - huggingface: username/model-name"
    echo "           - github: username/repo"
    echo "           - url: Direct download link"
    echo "  output_dir Output directory (default: ./models)"
    echo ""
    echo "Examples:"
    echo "  bash download_model.sh huggingface meta-llama/Llama-2-7b-hf ./models"
    echo "  bash download_model.sh github facebook/opt-125m ./opt-model"
    echo "  bash download_model.sh url https://example.com/model.bin ./"
    exit 0
fi

# Interactive input
if [ -z "$MODEL_ID" ]; then
    echo "=========================================="
    echo "     Model/Data Download Script"
    echo "=========================================="
    echo ""

    echo "Select download source:"
    echo "  [1] HuggingFace Hub"
    echo "  [2] GitHub Repository"
    echo "  [3] Direct URL"
    echo "  [4] Kaggle"
    read -p "Select [1-4]: " CHOICE

    case $CHOICE in
        1) SOURCE="huggingface";;
        2) SOURCE="github";;
        3) SOURCE="url";;
        4) SOURCE="kaggle";;
        *) echo "Invalid selection"; exit 1;;
    esac

    if [ "$SOURCE" != "kaggle" ]; then
        read -p "Enter model/data identifier: " MODEL_ID
    fi

    read -p "Output directory [default: ./models]: " INPUT_DIR
    OUTPUT_DIR=${INPUT_DIR:-"./models"}
fi

echo ""
echo "Source: $SOURCE"
echo "Identifier: $MODEL_ID"
echo "Output: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# ============================================
# HuggingFace Download
# ============================================
download_huggingface() {
    echo "Downloading from HuggingFace..."

    # Check if installed
    pip show huggingface_hub >/dev/null 2>&1 || pip install huggingface_hub

    # Check if logged in
    TOKEN=$(python -c "from huggingface_hub import HfApi; print(HfApi().token)" 2>/dev/null)
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "None" ]; then
        echo "Warning: Not logged in to HuggingFace, some models may not be downloadable"
        echo "   Login: huggingface-cli login"
    fi

    # Download model
    python -c "
from huggingface_hub import snapshot_download
import os

try:
    snapshot_download(
        repo_id='$MODEL_ID',
        local_dir='$OUTPUT_DIR',
        local_dir_use_symlinks=False
    )
    print('Download complete!')
except Exception as e:
    print(f'Error: {e}')
    print('Trying single file download...')
"
}

# ============================================
# GitHub Download
# ============================================
download_github() {
    echo "Downloading from GitHub..."

    # Try using git clone
    if command -v git &> /dev/null; then
        # Extract username and repo name
        REPO_URL="https://github.com/$MODEL_ID.git"
        git clone "$REPO_URL" "$OUTPUT_DIR"
    else
        # Download zip using GitHub API
        curl -L "https://github.com/$MODEL_ID/archive/refs/heads/main.zip" -o "$OUTPUT_DIR.zip"
        unzip "$OUTPUT_DIR.zip" -d "$OUTPUT_DIR"
    fi
}

# ============================================
# URL Download
# ============================================
download_url() {
    echo "Downloading from URL..."

    # Extract filename
    FILENAME=$(basename "$MODEL_ID")

    # Choose download tool
    if command -v curl &> /dev/null; then
        curl -L "$MODEL_ID" -o "$OUTPUT_DIR/$FILENAME"
    elif command -v wget &> /dev/null; then
        wget "$MODEL_ID" -O "$OUTPUT_DIR/$FILENAME"
    else
        echo "Error: curl or wget required"
        exit 1
    fi
}

# ============================================
# Kaggle Download
# ============================================
download_kaggle() {
    echo "Downloading from Kaggle..."

    # Check kaggle CLI
    pip show kaggle >/dev/null 2>&1 || pip install kaggle

    # Check authentication
    if [ ! -f "$HOME/.kaggle/kaggle.json" ]; then
        echo "Error: Kaggle API credentials required"
        echo "1. Visit https://www.kaggle.com/account"
        echo "2. Click 'Create New API Token'"
        echo "3. Place kaggle.json in ~/.kaggle/"
        exit 1
    fi

    if [ -z "$MODEL_ID" ]; then
        read -p "Enter Kaggle dataset (e.g., username/dataset-name): " MODEL_ID
    fi

    kaggle datasets download -d "$MODEL_ID" -p "$OUTPUT_DIR" --unzip
}

# ============================================
# Execute Download
# ============================================
case $SOURCE in
    huggingface)
        download_huggingface
        ;;
    github)
        download_github
        ;;
    url)
        download_url
        ;;
    kaggle)
        download_kaggle
        ;;
    *)
        echo "Unknown source: $SOURCE"
        exit 1
        ;;
esac

# ============================================
# Verify Download
# ============================================
echo ""
echo "=========================================="
echo "Verifying download..."
echo "=========================================="

if [ -d "$OUTPUT_DIR" ]; then
    echo "Output directory contents:"
    ls -lh "$OUTPUT_DIR"
    echo ""
    echo "Download complete!"
else
    echo "Download failed, please check error messages"
    exit 1
fi
