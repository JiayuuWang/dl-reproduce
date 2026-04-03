#!/bin/bash
# ============================================
# Environment Check Script — DL Reproduction
# Usage: bash reference/environment_check.sh
# Works on: Linux, macOS, Windows (Git Bash/MSYS2)
# ============================================

echo "=========================================="
echo "  DL Environment Diagnostic Report"
echo "=========================================="
echo ""

# ---- OS ----
echo "[System]"
case "$(uname -s)" in
    Linux*)
        if [ -f /etc/os-release ]; then . /etc/os-release; echo "OS: $NAME $VERSION"; fi
        ;;
    Darwin*) echo "OS: macOS $(sw_vers -productVersion)" ;;
    MINGW*|MSYS*|CYGWIN*) echo "OS: Windows ($(uname -s))" ;;
esac
echo "Arch: $(uname -m)"
echo ""

# ---- Python ----
echo "[Python]"
if command -v python &> /dev/null; then
    echo "python: $(python --version 2>&1) ($(which python))"
else
    echo "python: NOT FOUND"
fi
if command -v python3 &> /dev/null; then
    echo "python3: $(python3 --version 2>&1) ($(which python3))"
fi
echo ""

# ---- Package managers ----
echo "[Package Managers]"
command -v pip &> /dev/null && echo "pip: $(pip --version 2>&1)"
command -v conda &> /dev/null && echo "conda: $(conda --version 2>&1)"
command -v uv &> /dev/null && echo "uv: $(uv --version 2>&1)"
if [ -n "$VIRTUAL_ENV" ]; then
    echo "Active venv: $VIRTUAL_ENV"
elif [ -n "$CONDA_DEFAULT_ENV" ]; then
    echo "Active conda: $CONDA_DEFAULT_ENV"
else
    echo "WARNING: No virtual environment active"
fi
echo ""

# ---- CUDA ----
echo "[CUDA & GPU]"
if command -v nvcc &> /dev/null; then
    echo "nvcc: $(nvcc --version | grep 'release' | sed 's/.*release \([^,]*\),.*/\1/')"
else
    echo "nvcc: NOT FOUND (custom CUDA kernels won't compile)"
fi

if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version --format=csv,noheader 2>/dev/null | while read line; do
        echo "GPU: $line"
    done
    DRIVER_CUDA=$(nvidia-smi | grep "CUDA Version" | sed 's/.*CUDA Version: \([0-9.]*\).*/\1/' 2>/dev/null)
    [ -n "$DRIVER_CUDA" ] && echo "Driver CUDA cap: $DRIVER_CUDA"
else
    echo "nvidia-smi: NOT FOUND (no NVIDIA GPU or driver)"
fi
echo ""

# ---- Key packages ----
echo "[Key Packages]"
python -c "
packages = ['torch', 'torchvision', 'transformers', 'accelerate', 'datasets',
            'bitsandbytes', 'peft', 'trl', 'vllm', 'deepspeed']
for pkg in packages:
    try:
        mod = __import__(pkg)
        ver = getattr(mod, '__version__', '?')
        print(f'  {pkg}: {ver}')
    except ImportError:
        pass

# Torch CUDA details
try:
    import torch
    print(f'  torch.cuda: {torch.cuda.is_available()} (built with CUDA {torch.version.cuda})')
    if torch.cuda.is_available():
        cap = torch.cuda.get_device_capability()
        print(f'  GPU compute: sm_{cap[0]}{cap[1]}')
        mem = torch.cuda.get_device_properties(0).total_mem / 1e9
        print(f'  GPU VRAM: {mem:.1f} GB')
except:
    pass
" 2>/dev/null
echo ""

# ---- Network ----
echo "[Network]"
check_url() {
    if command -v curl &> /dev/null; then
        curl -s --max-time 5 "$1" > /dev/null 2>&1 && echo "  $2: OK" || echo "  $2: BLOCKED/SLOW"
    fi
}
check_url "https://pypi.org" "pypi.org"
check_url "https://huggingface.co" "huggingface.co"
check_url "https://github.com" "github.com"
echo ""

# ---- Disk ----
echo "[Disk Space]"
if command -v df &> /dev/null; then
    df -h . 2>/dev/null | tail -1 | awk '{print "  Current dir: " $4 " free of " $2}'
fi
echo ""

echo "=========================================="
echo "  Check complete"
echo "=========================================="
