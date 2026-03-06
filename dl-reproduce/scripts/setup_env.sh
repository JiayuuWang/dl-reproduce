#!/bin/bash
# ============================================
# 环境配置模板脚本
# 用法: bash scripts/setup_env.sh [project_name]
# ============================================

# 默认项目名
PROJECT_NAME=${1:-my_project}

echo "=========================================="
echo "     深度学习环境配置脚本"
echo "=========================================="
echo "项目名: $PROJECT_NAME"
echo ""

# ============================================
# 1. 检测当前环境
# ============================================
echo "📋 Step 1: 检测当前环境..."
echo "-------------------------------------------"

# Python 版本
PYTHON_VERSION=$(python --version 2>&1 | grep -oP '\d+\.\d+')
echo "Python: $PYTHON_VERSION"

# CUDA 版本
if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/')
    echo "CUDA: $CUDA_VERSION"
else
    echo "CUDA: 未检测到"
fi

# GPU
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader)
    echo "GPU: $GPU_NAME ($GPU_MEM)"
else
    echo "GPU: 未检测到"
fi

echo ""

# ============================================
# 2. 检测网络环境
# ============================================
echo "🌐 Step 2: 检测网络环境..."
echo "-------------------------------------------"

# 测试 pypi 连接
if ping -c 1 -W 2 pypi.org >/dev/null 2>&1; then
    echo "国际网络: 正常"
    USE_MIRROR=false
else
    echo "国际网络: 不稳定，使用国内镜像"
    USE_MIRROR=true
fi

# 设置镜像
if [ "$USE_MIRROR" = true ]; then
    PIP_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"
    echo "pip 镜像: 清华镜像"
fi
echo ""

# ============================================
# 3. 创建虚拟环境
# ============================================
echo "🔧 Step 3: 创建虚拟环境..."
echo "-------------------------------------------"

# 选择环境管理器
if command -v conda &> /dev/null; then
    echo "使用 conda 创建环境..."
    conda create -n "$PROJECT_NAME" python=3.10 -y
    conda activate "$PROJECT_NAME"
    ENV_CREATED=true
elif command -v python &> /dev/null; then
    echo "使用 venv 创建环境..."
    python -m venv venv
    source venv/bin/activate
    ENV_CREATED=true
else
    echo "❌ 未找到 conda 或 python"
    exit 1
fi

echo ""

# ============================================
# 4. 安装基础依赖
# ============================================
echo "📦 Step 4: 安装基础依赖..."
echo "-------------------------------------------"

# 设置 pip 参数
if [ "$USE_MIRROR" = true ]; then
    PIP_EXTRA="-i $PIP_MIRROR"
fi

# 升级 pip
pip install --upgrade pip $PIP_EXTRA

# 安装 PyTorch
echo "安装 PyTorch..."
if command -v nvcc &> /dev/null; then
    # CUDA 版本
    CUDA_MAJOR=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/' | cut -d. -f1)
    if [ "$CUDA_MAJOR" = "11" ]; then
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 $PIP_EXTRA
    elif [ "$CUDA_MAJOR" = "12" ]; then
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 $PIP_EXTRA
    fi
else
    pip install torch torchvision torchaudio $PIP_EXTRA
fi

# 安装基础库
echo "安装基础库..."
pip install numpy pandas scikit-learn matplotlib seaborn tqdm $PIP_EXTRA

# 安装深度学习相关
echo "安装深度学习库..."
pip install transformers datasets accelerate $PIP_EXTRA

echo ""

# ============================================
# 5. 安装项目依赖
# ============================================
echo "📋 Step 5: 安装项目依赖..."
echo "-------------------------------------------"

if [ -f "requirements.txt" ]; then
    echo "找到 requirements.txt，安装项目依赖..."
    pip install -r requirements.txt $PIP_EXTRA
elif [ -f "setup.py" ]; then
    echo "找到 setup.py，安装项目..."
    pip install -e . $PIP_EXTRA
elif [ -f "pyproject.toml" ]; then
    echo "找到 pyproject.toml，安装项目..."
    pip install -e . $PIP_EXTRA
else
    echo "⚠️ 未找到项目依赖文件"
fi

echo ""

# ============================================
# 6. 验证环境
# ============================================
echo "✅ Step 6: 验证环境..."
echo "-------------------------------------------"

python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB')
"

python -c "import transformers; print(f'transformers: {transformers.__version__}')"

echo ""

# ============================================
# 完成
# ============================================
echo "=========================================="
echo "✅ 环境配置完成！"
echo "=========================================="
echo ""
echo "激活环境命令:"
if command -v conda &> /dev/null; then
    echo "  conda activate $PROJECT_NAME"
else
    echo "  source venv/bin/activate"
fi
echo ""
echo "安装额外包:"
echo "  pip install <package> $PIP_EXTRA"
echo ""
