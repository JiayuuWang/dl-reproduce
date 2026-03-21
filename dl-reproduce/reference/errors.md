# Common Errors Quick Reference

> Common errors and solutions for deep learning project reproduction

---

## Environment Dependency Errors

### ModuleNotFoundError: No module named 'xxx'

**Cause**: Missing Python package

**Solution**:
```bash
pip install <package_name>
# Or specify version
pip install <package_name>==x.x.x
```

---

### ImportError: cannot import name 'xxx' from 'typing'

**Cause**: Python or package version incompatibility

**Solution**:
```bash
# Option 1: Upgrade/downgrade related packages
pip install --upgrade <package>
pip install <package>==<version>

# Option 2: Check Python version
python --version
# If Python version is too new, consider using conda to create an older environment
conda create -n env_name python=3.10
```

---

### pkg_resources.DistributionNotFound

**Cause**: Package version mismatch or corruption

**Solution**:
```bash
pip install --upgrade setuptools wheel
pip install --upgrade <package>
```

---

## CUDA/GPU Errors

### RuntimeError: CUDA out of memory

**Cause**: GPU VRAM insufficient

**Solution**:
```bash
# 1. Reduce batch size
python train.py --batch_size 4

# 2. Enable gradient accumulation
python train.py --gradient_accumulation_steps 4

# 3. Reduce model precision (if supported)
python train.py --precision fp16

# 4. Enable mixed precision
python train.py --use_amp

# 5. Clear cache with torch.cuda.empty_cache()
```

---

### RuntimeError: CUDA error: no kernel image is available for execution

**Cause**: PyTorch CUDA version incompatible with GPU

**Solution**:
```bash
# Check CUDA version
nvcc --version
nvidia-smi

# Reinstall PyTorch matching CUDA version
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
# Or cu117, cu116, cu115, etc.
```

---

### AssertionError: Torch not compiled with CUDA enabled

**Cause**: PyTorch compiled without CUDA support

**Solution**:
```bash
# Check PyTorch version
python -c "import torch; print(torch.__version__)"
python -c "import torch; print(torch.cuda.is_available())"

# Reinstall CUDA version
pip uninstall torch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

---

### ValueError: Tensor for 'y' has dtype Float but expected IntType

**Cause**: Label data type mismatch

**Solution**:
```bash
# Check dataset label type
# Convert label type
labels = labels.long()  # for CrossEntropyLoss
# Or
labels = labels.float()  # for BCE Loss
```

---

## Network/Download Errors

### SSL: CERTIFICATE_VERIFY_FAILED

**Cause**: SSL certificate verification failed (usually network environment issue)

**Solution**:
```bash
# Option 1: Temporarily skip SSL verification (not recommended for sensitive operations)
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org <package>

# Option 2: Use mirror
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>

# Option 3: Update certificates
pip install --upgrade certifi
/Applications/Python\ 3.x/Install\ Certificates.command  # macOS
```

---

### HTTPError 404: Not Found

**Cause**: Download link expired or package name error

**Solution**:
```bash
# Check package name
pip index versions <package>

# Use correct package name
pip install <correct_package_name>

# If model/data link expired, try:
# 1. HuggingFace mirror
# 2. Manual download
# 3. Find alternative source
```

---

### git clone failed / Connection refused

**Cause**: Git network issues or proxy configuration

**Solution**:
```bash
# Option 1: Switch to https protocol
git config --global url."https://github.com/".insteadOf "git@github.com:"

# Option 2: Configure proxy
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890

# Option 3: Use mirror
git clone https://mirror.ghproxy.com/https://github.com/username/repo

# Option 4: Manual download zip
```

---

### OSError: [Errno 28] No space left on device

**Cause**: Disk space full

**Solution**:
```bash
# Check disk usage
df -h

# Clear cache
pip cache purge
rm -rf ~/.cache/pip
rm -rf ~/.*cache

# Clean Docker
docker system prune -a

# Clean temp files
rm -rf /tmp/*
```

---

## Permission Errors

### PermissionError: [Errno 13] Permission denied

**Cause**: No write permission

**Solution**:
```bash
# Option 1: Use virtual environment (recommended)
python -m venv venv
source venv/bin/activate

# Option 2: Install with --user
pip install --user <package>

# Option 3: Check directory permissions
ls -la <directory>
# Use sudo only when necessary
```

---

### condaEnvironmentChangeError

**Cause**: Conda environment change conflict

**Solution**:
```bash
# Option 1: Update conda
conda update conda

# Option 2: Create new environment
conda create -n new_env python=3.x
conda activate new_env

# Option 3: Clear cache
conda clean -a
```

---

## Data Processing Errors

### FileNotFoundError: [Errno 2] No such file or directory

**Cause**: File path error

**Solution**:
```bash
# Check if file exists
ls -la <path>

# Use absolute path
import os
os.path.abspath("relative/path")

# Check current directory
import os
print(os.getcwd())
```

---

### ValueError: too many values to unpack (expected 2)

**Cause**: Data format doesn't match code expectation

**Solution**:
```bash
# Check data format
head -n 5 <data_file>

# Check code expected data format
# Usually: label,text or text,label or JSON format
```

---

## Parallel/Multi-GPU Errors

### RuntimeError: rank 0 FAILED

**Cause**: Distributed training failed

**Solution**:
```bash
# Option 1: Check NCCL
python -c "import torch; print(torch.cuda.nccl.version())"

# Option 2: Set environment variables
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0

# Option 3: Test with single GPU
python train.py --nproc_per_node 1
```

---

### os._exit(-1) in <module> + AttributeError: 'NoneType' object has no attribute 'close'

**Cause**: Dataloader worker crashed

**Solution**:
```bash
# Reduce num_workers
python train.py --num_workers 0

# Or check errors in data loading code
```

---

## Other Common Errors

### KeyboardInterrupt stuck in parallel processes

**Solution**:
```bash
# Kill all Python processes
pkill -9 python
pkill -9 torchrun
```

---

### OMP: Error #15: Initializing libiomp5.dylib, but found initial error

**Cause**: OpenMP library conflict

**Solution**:
```bash
# macOS
export KMP_DUPLICATE_LIB_OK=TRUE

# Linux
export OMP_NUM_THREADS=1
```

---

## Quick Diagnostic Commands

```bash
# Check Python environment
python -c "import sys; print(sys.version)"
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"

# Check dependencies
pip list | grep -E "torch|numpy|transformers"

# Check GPU
nvidia-smi

# Check memory
free -h

# Check disk
df -h
```

---

## Getting Help

If you encounter errors not listed:
1. Copy full error message
2. Search error keywords
3. Check project README / Issues
4. Search similar issues in GitHub Issues
