#!/bin/bash
# ============================================
# 环境检测脚本 - 深度学习项目复现
# 用法: bash reference/environment_check.sh
# ============================================

echo "=========================================="
echo "       深度学习环境检测报告"
echo "=========================================="
echo ""

# 1. 系统信息
echo "📦 系统信息"
echo "-------------------------------------------"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "系统: $NAME $VERSION"
fi
echo "内核: $(uname -r)"
echo "架构: $(uname -m)"
echo ""

# 2. Python 环境
echo "🐍 Python 环境"
echo "-------------------------------------------"
if command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1)
    echo "Python: $PYTHON_VERSION"
    echo "路径: $(which python)"
else
    echo "❌ Python 未安装"
fi
echo ""

# 3. 包管理器
echo "📦 包管理器"
echo "-------------------------------------------"
if command -v pip &> /dev/null; then
    echo "pip: $(pip --version)"
fi
if command -v pip3 &> /dev/null; then
    echo "pip3: $(pip3 --version)"
fi
if command -v conda &> /dev/null; then
    echo "conda: $(conda --version)"
    conda info --envs
fi
if command -v uv &> /dev/null; then
    echo "uv: $(uv --version)"
fi
echo ""

# 4. CUDA 环境
echo "🔧 CUDA 环境"
echo "-------------------------------------------"
if command -v nvcc &> /dev/null; then
    NVCC_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/')
    echo "nvcc: $NVCC_VERSION"
else
    echo "⚠️ nvcc 未安装或未在 PATH 中"
fi

if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "GPU 信息:"
    nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version,cuda_version --format=csv
else
    echo "⚠️ nvidia-smi 未找到（可能无 NVIDIA GPU 或驱动未安装）"
fi
echo ""

# 5. 关键 Python 包
echo "📚 已安装的关键包"
echo "-------------------------------------------"
check_package() {
    python -c "import $1; print('$1: ' + $1.__version__)" 2>/dev/null || echo "$1: ❌ 未安装"
}

check_package torch
check_package torchvision
check_package transformers
check_package numpy
check_package pandas
check_package matplotlib
check_package tqdm
echo ""

# 6. 网络检测
echo "🌐 网络环境检测"
echo "-------------------------------------------"
check_network() {
    if ping -c 1 -W 3 $1 >/dev/null 2>&1; then
        echo "✅ $1: 可连接"
    else
        echo "❌ $1: 无法连接"
    fi
}

check_network pypi.org
check_network huggingface.co
check_network github.com
echo ""

# 7. 建议
echo "💡 建议"
echo "-------------------------------------------"

# CUDA 检查
if ! command -v nvidia-smi &> /dev/null; then
    echo "• 未检测到 NVIDIA GPU 或驱动，可能需要 CPU 模式运行"
fi

# Python 版本建议
PYTHON_MAJOR=$(python -c 'import sys; print(sys.version_info.major)' 2>/dev/null)
PYTHON_MINOR=$(python -c 'import sys; print(sys.version_info.minor)' 2>/dev/null)
if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -gt 11 ]; then
    echo "• Python 3.${PYTHON_MINOR} 版本较新，部分旧项目可能不兼容"
fi

# 虚拟环境检查
if [ -z "$VIRTUAL_ENV" ] && [ -z "$CONDA_DEFAULT_ENV" ]; then
    echo "• 建议使用虚拟环境（conda 或 venv）进行项目隔离"
fi

echo ""
echo "=========================================="
echo "          检测完成"
echo "=========================================="
