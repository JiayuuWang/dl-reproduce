#!/bin/bash
# ============================================
# Environment Check Script - Deep Learning Project Reproduction
# Usage: bash reference/environment_check.sh
# ============================================

echo "=========================================="
echo "       Deep Learning Environment Check Report"
echo "=========================================="
echo ""

# 1. System Information
echo "System Information"
echo "-------------------------------------------"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME $VERSION"
fi
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

# 2. Python Environment
echo "Python Environment"
echo "-------------------------------------------"
if command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1)
    echo "Python: $PYTHON_VERSION"
    echo "Path: $(which python)"
else
    echo "Python not found"
fi
echo ""

# 3. Package Manager
echo "Package Manager"
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

# 4. CUDA Environment
echo "CUDA Environment"
echo "-------------------------------------------"
if command -v nvcc &> /dev/null; then
    NVCC_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/')
    echo "nvcc: $NVCC_VERSION"
else
    echo "nvcc not found or not in PATH"
fi

if command -v nvidia-smi &> /dev/null; then
    echo ""
    echo "GPU Information:"
    nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version,cuda_version --format=csv
else
    echo "nvidia-smi not found (may not have NVIDIA GPU or driver installed)"
fi
echo ""

# 5. Key Python Packages
echo "Installed Key Packages"
echo "-------------------------------------------"
check_package() {
    python -c "import $1; print('$1: ' + $1.__version__)" 2>/dev/null || echo "$1: Not installed"
}

check_package torch
check_package torchvision
check_package transformers
check_package numpy
check_package pandas
check_package matplotlib
check_package tqdm
echo ""

# 6. Network Check
echo "Network Environment Check"
echo "-------------------------------------------"
check_network() {
    if ping -c 1 -W 3 $1 >/dev/null 2>&1; then
        echo "$1: Connection OK"
    else
        echo "$1: Cannot connect"
    fi
}

check_network pypi.org
check_network huggingface.co
check_network github.com
echo ""

# 7. Recommendations
echo "Recommendations"
echo "-------------------------------------------"

# CUDA check
if ! command -v nvidia-smi &> /dev/null; then
    echo "- No NVIDIA GPU or driver detected, may need to run in CPU mode"
fi

# Python version recommendation
PYTHON_MAJOR=$(python -c 'import sys; print(sys.version_info.major)' 2>/dev/null)
PYTHON_MINOR=$(python -c 'import sys; print(sys.version_info.minor)' 2>/dev/null)
if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -gt 11 ]; then
    echo "- Python 3.$PYTHON_MINOR is relatively new, some older projects may be incompatible"
fi

# Virtual environment check
if [ -z "$VIRTUAL_ENV" ] && [ -z "$CONDA_DEFAULT_ENV" ]; then
    echo "- Recommend using virtual environment (conda or venv) for project isolation"
fi

echo ""
echo "=========================================="
echo "          Check Complete"
echo "=========================================="
