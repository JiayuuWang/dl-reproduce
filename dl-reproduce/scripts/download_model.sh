#!/bin/bash
# ============================================
# 模型/数据下载脚本模板
# 用法: 
#   bash scripts/download_model.sh [model_id] [output_dir]
#   bash scripts/download_model.sh huggingface meta-llama/Llama-2-7b-hf ./models
# ============================================

# 默认参数
SOURCE=${1:-huggingface}
MODEL_ID=${2:-}
OUTPUT_DIR=${3:-"./models"}

# 帮助信息
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "用法: bash download_model.sh <source> <model_id> <output_dir>"
    echo ""
    echo "参数:"
    echo "  source    下载来源: huggingface, github, url (默认: huggingface)"
    echo "  model_id  模型标识符"
    echo "           - huggingface: username/model-name"
    echo "           - github: username/repo"
    echo "           - url: 直接下载链接"
    echo "  output_dir 输出目录 (默认: ./models)"
    echo ""
    echo "示例:"
    echo "  bash download_model.sh huggingface meta-llama/Llama-2-7b-hf ./models"
    echo "  bash download_model.sh github facebook/opt-125m ./opt模型"
    echo "  bash download_model.sh url https://example.com/model.bin ./"
    exit 0
fi

# 交互式输入
if [ -z "$MODEL_ID" ]; then
    echo "=========================================="
    echo "     模型/数据下载脚本"
    echo "=========================================="
    echo ""
    
    echo "选择下载来源:"
    echo "  [1] HuggingFace Hub"
    echo "  [2] GitHub 仓库"
    echo "  [3] 直接 URL"
    echo "  [4] Kaggle"
    read -p "请选择 [1-4]: " CHOICE
    
    case $CHOICE in
        1) SOURCE="huggingface";;
        2) SOURCE="github";;
        3) SOURCE="url";;
        4) SOURCE="kaggle";;
        *) echo "无效选择"; exit 1;;
    esac
    
    if [ "$SOURCE" != "kaggle" ]; then
        read -p "请输入模型/数据标识符: " MODEL_ID
    fi
    
    read -p "输出目录 [默认: ./models]: " INPUT_DIR
    OUTPUT_DIR=${INPUT_DIR:-"./models"}
fi

echo ""
echo "来源: $SOURCE"
echo "标识符: $MODEL_ID"
echo "输出: $OUTPUT_DIR"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# ============================================
# HuggingFace 下载
# ============================================
download_huggingface() {
    echo "📥 从 HuggingFace 下载..."
    
    # 检查是否已安装
    pip show huggingface_hub >/dev/null 2>&1 || pip install huggingface_hub
    
    # 检查是否登录
    TOKEN=$(python -c "from huggingface_hub import HfApi; print(HfApi().token)" 2>/dev/null)
    if [ -z "$TOKEN" ] || [ "$TOKEN" = "None" ]; then
        echo "⚠️ 未登录 HuggingFace，部分模型可能无法下载"
        echo "   登录: huggingface-cli login"
    fi
    
    # 下载模型
    python -c "
from huggingface_hub import snapshot_download
import os

try:
    snapshot_download(
        repo_id='$MODEL_ID',
        local_dir='$OUTPUT_DIR',
        local_dir_use_symlinks=False
    )
    print('下载完成!')
except Exception as e:
    print(f'错误: {e}')
    print('尝试单个文件下载...')
"
}

# ============================================
# GitHub 下载
# ============================================
download_github() {
    echo "📥 从 GitHub 下载..."
    
    # 尝试使用 git clone
    if command -v git &> /dev/null; then
        # 提取用户名和仓库名
        REPO_URL="https://github.com/$MODEL_ID.git"
        git clone "$REPO_URL" "$OUTPUT_DIR"
    else
        # 使用 GitHub API 下载 zip
        curl -L "https://github.com/$MODEL_ID/archive/refs/heads/main.zip" -o "$OUTPUT_DIR.zip"
        unzip "$OUTPUT_DIR.zip" -d "$OUTPUT_DIR"
    fi
}

# ============================================
# URL 下载
# ============================================
download_url() {
    echo "📥 从 URL 下载..."
    
    # 提取文件名
    FILENAME=$(basename "$MODEL_ID")
    
    # 选择下载工具
    if command -v curl &> /dev/null; then
        curl -L "$MODEL_ID" -o "$OUTPUT_DIR/$FILENAME"
    elif command -v wget &> /dev/null; then
        wget "$MODEL_ID" -O "$OUTPUT_DIR/$FILENAME"
    else
        echo "错误: 需要 curl 或 wget"
        exit 1
    fi
}

# ============================================
# Kaggle 下载
# ============================================
download_kaggle() {
    echo "📥 从 Kaggle 下载..."
    
    # 检查 kaggle CLI
    pip show kaggle >/dev/null 2>&1 || pip install kaggle
    
    # 检查认证
    if [ ! -f "$HOME/.kaggle/kaggle.json" ]; then
        echo "错误: 需要 Kaggle API 密钥"
        echo "1. 访问 https://www.kaggle.com/account"
        echo "2. 点击 'Create New API Token'"
        echo "3. 将 kaggle.json 放到 ~/.kaggle/"
        exit 1
    fi
    
    if [ -z "$MODEL_ID" ]; then
        read -p "请输入 Kaggle 数据集 (e.g., username/dataset-name): " MODEL_ID
    fi
    
    kaggle datasets download -d "$MODEL_ID" -p "$OUTPUT_DIR" --unzip
}

# ============================================
# 执行下载
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
        echo "未知来源: $SOURCE"
        exit 1
        ;;
esac

# ============================================
# 验证下载
# ============================================
echo ""
echo "=========================================="
echo "验证下载..."
echo "=========================================="

if [ -d "$OUTPUT_DIR" ]; then
    echo "📁 输出目录内容:"
    ls -lh "$OUTPUT_DIR"
    echo ""
    echo "✅ 下载完成！"
else
    echo "❌ 下载失败，请检查错误信息"
    exit 1
fi
