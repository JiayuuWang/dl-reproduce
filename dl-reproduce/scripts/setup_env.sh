#!/bin/bash
# ============================================
# Environment Setup Template Script
# Usage: bash scripts/setup_env.sh [project_name]
# ============================================

# Default project name
PROJECT_NAME=${1:-my_project}

echo "=========================================="
echo "     Deep Learning Environment Setup Script"
echo "=========================================="
echo "Project Name: $PROJECT_NAME"
echo ""

# ============================================
# 1. Detect Current Environment
# ============================================
echo "Step 1: Detecting current environment..."
echo "-------------------------------------------"

# Python version
PYTHON_VERSION=$(python --version 2>&1 | grep -oP '\d+\.\d+')
echo "Python: $PYTHON_VERSION"

# CUDA version
if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/')
    echo "CUDA: $CUDA_VERSION"
else
    echo "CUDA: Not detected"
fi

# GPU
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader)
    echo "GPU: $GPU_NAME ($GPU_MEM)"
else
    echo "GPU: Not detected"
fi

echo ""

# ============================================
# 2. Detect Network Environment
# ============================================
echo "Step 2: Detecting network environment..."
echo "-------------------------------------------"

# Test pypi connection
if ping -c 1 -W 2 pypi.org >/dev/null 2>&1; then
    echo "International network: OK"
    USE_MIRROR=false
else
    echo "International network: Unstable, using domestic mirror"
    USE_MIRROR=true
fi

# Set mirror
if [ "$USE_MIRROR" = true ]; then
    PIP_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple"
    echo "pip mirror: Tsinghua mirror"
fi
echo ""

# ============================================
# 3. Create Virtual Environment
# ============================================
echo "Step 3: Creating virtual environment..."
echo "-------------------------------------------"

# Choose environment manager
if command -v conda &> /dev/null; then
    echo "Using conda to create environment..."
    conda create -n "$PROJECT_NAME" python=3.10 -y
    conda activate "$PROJECT_NAME"
    ENV_CREATED=true
elif command -v python &> /dev/null; then
    echo "Using venv to create environment..."
    python -m venv venv
    source venv/bin/activate
    ENV_CREATED=true
else
    echo "Error: conda or python not found"
    exit 1
fi

echo ""

# ============================================
# 4. Install Basic Dependencies
# ============================================
echo "Step 4: Installing basic dependencies..."
echo "-------------------------------------------"

# Set pip arguments
if [ "$USE_MIRROR" = true ]; then
    PIP_EXTRA="-i $PIP_MIRROR"
fi

# Upgrade pip
pip install --upgrade pip $PIP_EXTRA

# Install PyTorch
echo "Installing PyTorch..."
if command -v nvcc &> /dev/null; then
    # CUDA version
    CUDA_MAJOR=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/' | cut -d. -f1)
    if [ "$CUDA_MAJOR" = "11" ]; then
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 $PIP_EXTRA
    elif [ "$CUDA_MAJOR" = "12" ]; then
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 $PIP_EXTRA
    fi
else
    pip install torch torchvision torchaudio $PIP_EXTRA
fi

# Install basic libraries
echo "Installing basic libraries..."
pip install numpy pandas scikit-learn matplotlib seaborn tqdm $PIP_EXTRA

# Install deep learning related
echo "Installing deep learning libraries..."
pip install transformers datasets accelerate $PIP_EXTRA

echo ""

# ============================================
# 5. Install Project Dependencies
# ============================================
echo "Step 5: Installing project dependencies..."
echo "-------------------------------------------"

if [ -f "requirements.txt" ]; then
    echo "Found requirements.txt, installing project dependencies..."
    pip install -r requirements.txt $PIP_EXTRA
elif [ -f "setup.py" ]; then
    echo "Found setup.py, installing project..."
    pip install -e . $PIP_EXTRA
elif [ -f "pyproject.toml" ]; then
    echo "Found pyproject.toml, installing project..."
    pip install -e . $PIP_EXTRA
else
    echo "Warning: No project dependency file found"
fi

echo ""

# ============================================
# 6. Verify Environment
# ============================================
echo "Step 6: Verifying environment..."
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
# Complete
# ============================================
echo "=========================================="
echo "Environment setup complete!"
echo "=========================================="
echo ""
echo "Activate environment command:"
if command -v conda &> /dev/null; then
    echo "  conda activate $PROJECT_NAME"
else
    echo "  source venv/bin/activate"
fi
echo ""
echo "Install additional packages:"
echo "  pip install <package> $PIP_EXTRA"
echo ""
