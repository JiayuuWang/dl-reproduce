#!/bin/bash
# ============================================
# Environment Setup Script (DL Reproduction)
# Usage: bash scripts/setup_env.sh <project_name> [python_version]
#
# Key design: installs PyTorch FIRST with correct CUDA,
# THEN project dependencies. This prevents pip from
# pulling in CPU-only torch.
# ============================================

PROJECT_NAME=${1:-my_project}
PYTHON_VERSION=${2:-3.10}

echo "=========================================="
echo "  DL Environment Setup: $PROJECT_NAME"
echo "=========================================="

# ============================================
# 1. Detect Hardware & CUDA
# ============================================
echo ""
echo "[1/6] Detecting hardware..."
echo "-------------------------------------------"

# Detect OS
OS_TYPE="unknown"
case "$(uname -s)" in
    Linux*)   OS_TYPE="linux";;
    Darwin*)  OS_TYPE="macos";;
    MINGW*|MSYS*|CYGWIN*) OS_TYPE="windows";;
esac
echo "OS: $OS_TYPE"

# Detect CUDA version (prefer nvcc, fall back to nvidia-smi)
CUDA_VER=""
if command -v nvcc &> /dev/null; then
    CUDA_VER=$(nvcc --version | grep "release" | sed 's/.*release \([^,]*\),.*/\1/')
    echo "CUDA (nvcc): $CUDA_VER"
elif command -v nvidia-smi &> /dev/null; then
    CUDA_VER=$(nvidia-smi | grep "CUDA Version" | sed 's/.*CUDA Version: \([0-9.]*\).*/\1/')
    echo "CUDA (driver): $CUDA_VER (nvcc not found — install CUDA toolkit for custom kernels)"
else
    echo "CUDA: Not detected (will install CPU-only PyTorch)"
fi

# GPU info
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
    GPU_COUNT=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l)
    echo "GPU: $GPU_NAME ($GPU_MEM) x$GPU_COUNT"
fi

# ============================================
# 2. Detect Network
# ============================================
echo ""
echo "[2/6] Detecting network..."
echo "-------------------------------------------"

USE_MIRROR=false
if command -v curl &> /dev/null; then
    if ! curl -s --max-time 5 https://pypi.org > /dev/null 2>&1; then
        USE_MIRROR=true
        echo "PyPI: Slow/blocked — will use Tsinghua mirror"
    else
        echo "PyPI: OK"
    fi
elif command -v ping &> /dev/null; then
    if [ "$OS_TYPE" = "windows" ]; then
        ping -n 1 -w 2000 pypi.org > /dev/null 2>&1 || USE_MIRROR=true
    else
        ping -c 1 -W 2 pypi.org > /dev/null 2>&1 || USE_MIRROR=true
    fi
fi

PIP_MIRROR_ARG=""
if [ "$USE_MIRROR" = true ]; then
    PIP_MIRROR_ARG="-i https://pypi.tuna.tsinghua.edu.cn/simple"
    echo "Using mirror for pip installs"
fi

# ============================================
# 3. Create Virtual Environment
# ============================================
echo ""
echo "[3/6] Creating environment '$PROJECT_NAME' (Python $PYTHON_VERSION)..."
echo "-------------------------------------------"

if command -v conda &> /dev/null; then
    # Must initialize conda for script usage
    eval "$(conda shell.bash hook)"
    conda create -n "$PROJECT_NAME" python="$PYTHON_VERSION" -y
    conda activate "$PROJECT_NAME"
    echo "Created conda env: $PROJECT_NAME"
elif command -v python3 &> /dev/null || command -v python &> /dev/null; then
    PYTHON_CMD=$(command -v python3 || command -v python)
    $PYTHON_CMD -m venv venv
    if [ "$OS_TYPE" = "windows" ]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    echo "Created venv in ./venv"
else
    echo "ERROR: No conda or python found"
    exit 1
fi

# ============================================
# 4. Install PyTorch (FIRST — before other deps)
# ============================================
echo ""
echo "[4/6] Installing PyTorch (CUDA-matched)..."
echo "-------------------------------------------"

pip install --upgrade pip $PIP_MIRROR_ARG

# Determine PyTorch index URL based on CUDA version
TORCH_INDEX=""
if [ -n "$CUDA_VER" ]; then
    CUDA_MAJOR=$(echo "$CUDA_VER" | cut -d. -f1)
    CUDA_MINOR=$(echo "$CUDA_VER" | cut -d. -f2)

    if [ "$CUDA_MAJOR" -eq 11 ]; then
        TORCH_INDEX="https://download.pytorch.org/whl/cu118"
    elif [ "$CUDA_MAJOR" -eq 12 ]; then
        if [ "$CUDA_MINOR" -le 1 ]; then
            TORCH_INDEX="https://download.pytorch.org/whl/cu121"
        elif [ "$CUDA_MINOR" -le 4 ]; then
            TORCH_INDEX="https://download.pytorch.org/whl/cu124"
        else
            TORCH_INDEX="https://download.pytorch.org/whl/cu126"
        fi
    else
        echo "WARNING: Unrecognized CUDA $CUDA_VER — trying latest torch index"
        TORCH_INDEX="https://download.pytorch.org/whl/cu126"
    fi
    echo "Using PyTorch index: $TORCH_INDEX"
    pip install torch torchvision torchaudio --index-url "$TORCH_INDEX"
else
    echo "No CUDA detected — installing CPU-only PyTorch"
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# ============================================
# 5. Verify PyTorch + CUDA (BEFORE other deps)
# ============================================
echo ""
echo "[5/6] Verifying PyTorch installation..."
echo "-------------------------------------------"

VERIFY_RESULT=$(python -c "
import torch
cuda_ok = torch.cuda.is_available()
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {cuda_ok}')
if cuda_ok:
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'VRAM: {torch.cuda.get_device_properties(0).total_mem / 1e9:.1f} GB')
    print(f'Compute capability: sm_{torch.cuda.get_device_capability(0)[0]}{torch.cuda.get_device_capability(0)[1]}')
print('VERIFY_OK')
" 2>&1)

echo "$VERIFY_RESULT"

if echo "$VERIFY_RESULT" | grep -q "VERIFY_OK"; then
    # Check CUDA mismatch
    if [ -n "$CUDA_VER" ] && echo "$VERIFY_RESULT" | grep -q "CUDA available: False"; then
        echo ""
        echo "WARNING: CUDA detected but torch says CUDA unavailable!"
        echo "This usually means torch was installed with wrong CUDA version."
        echo "Try reinstalling with explicit --index-url matching your CUDA."
    fi
else
    echo ""
    echo "ERROR: PyTorch verification failed. Fix before installing project deps."
    exit 1
fi

# ============================================
# 6. Install Project Dependencies
# ============================================
echo ""
echo "[6/6] Installing project dependencies..."
echo "-------------------------------------------"

if [ -f "requirements.txt" ]; then
    echo "Found requirements.txt"
    # Install but skip torch (already installed with correct CUDA)
    grep -v "^torch" requirements.txt | pip install -r /dev/stdin $PIP_MIRROR_ARG || \
        pip install -r requirements.txt $PIP_MIRROR_ARG
elif [ -f "pyproject.toml" ]; then
    echo "Found pyproject.toml"
    pip install -e . $PIP_MIRROR_ARG
elif [ -f "setup.py" ]; then
    echo "Found setup.py"
    pip install -e . $PIP_MIRROR_ARG
else
    echo "No dependency file found — install manually as needed"
fi

# ============================================
# Done
# ============================================
echo ""
echo "=========================================="
echo "  Setup complete!"
echo "=========================================="
echo ""
echo "Activate environment:"
if command -v conda &> /dev/null; then
    echo "  conda activate $PROJECT_NAME"
else
    if [ "$OS_TYPE" = "windows" ]; then
        echo "  source venv/Scripts/activate"
    else
        echo "  source venv/bin/activate"
    fi
fi
echo ""
echo "Next: verify with a smoke test (1 step of training or 1 inference sample)"
