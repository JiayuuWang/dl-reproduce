# DL-Specific Commands Reference

> Only commands that encode non-obvious deep learning knowledge. Generic git/pip/conda commands are omitted — the agent already knows those.

---

## PyTorch Install URLs (Critical — Wrong URL = CPU-only torch)

```bash
# CUDA 11.8
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# CUDA 12.1
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# CUDA 12.4
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# CUDA 12.6+
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# CPU only
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Specific version + CUDA (pin both)
pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu124

# Check what you actually got
python -c "import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available())"
```

---

## HuggingFace Environment Variables

```bash
# Mirror endpoint (for China mainland)
export HF_ENDPOINT=https://hf-mirror.com

# Custom cache directory (when home disk is small)
export HF_HUB_CACHE=/path/to/large/disk/hf_cache
export TRANSFORMERS_CACHE=/path/to/large/disk/transformers_cache

# Auth token (alternative to huggingface-cli login)
export HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Offline mode (use cached models only, no network)
export HF_HUB_OFFLINE=1
export TRANSFORMERS_OFFLINE=1

# Disable telemetry
export HF_HUB_DISABLE_TELEMETRY=1

# Download specific files only (skip large unused files)
# In Python:
# snapshot_download(repo_id="...", allow_patterns=["*.json", "*.safetensors"], ignore_patterns=["*.bin", "optimizer*"])
```

---

## CUDA & GPU Debugging

```bash
# Which CUDA does torch actually use (not nvidia-smi driver version)
python -c "import torch; print(torch.version.cuda)"

# GPU compute capability (determines flash-attn compatibility)
python -c "import torch; print(torch.cuda.get_device_capability())"
# SM 70 = V100, SM 75 = T4, SM 80 = A100/A10, SM 86 = RTX 30xx, SM 89 = RTX 40xx

# Detailed VRAM breakdown during training
python -c "import torch; torch.cuda.memory_summary()"

# Reset VRAM tracking for measurement
python -c "
import torch
torch.cuda.reset_peak_memory_stats()
# ... run your code ...
print(f'Peak VRAM: {torch.cuda.max_memory_allocated() / 1e9:.2f} GB')
"

# Force specific GPU
export CUDA_VISIBLE_DEVICES=0      # single GPU
export CUDA_VISIBLE_DEVICES=0,1    # first two GPUs
export CUDA_VISIBLE_DEVICES=""     # force CPU mode

# Real-time GPU monitoring (refreshes every 1s)
watch -n 1 nvidia-smi
# Or more detailed
nvidia-smi dmon -s u -d 1
```

---

## NCCL & Distributed Training

```bash
# Debug distributed issues
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=ALL

# Increase timeout (default 300s, set higher for large model loading)
export NCCL_TIMEOUT=1800

# Disable InfiniBand (common fix for cloud instances)
export NCCL_IB_DISABLE=1

# Force socket-based communication
export NCCL_SOCKET_IFNAME=eth0

# torch.distributed debugging
export TORCH_DISTRIBUTED_DEBUG=DETAIL

# Kill stuck distributed processes
pkill -f torchrun
pkill -f torch.distributed.launch
```

---

## Memory Optimization Env Vars

```bash
# Disable torch.compile (avoids triton issues, speeds up startup)
export TORCH_COMPILE_DISABLE=1

# OpenMP thread control (prevent CPU oversubscription)
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

# Reduce PyTorch memory fragmentation
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# macOS: fix OpenMP duplicate library error
export KMP_DUPLICATE_LIB_OK=TRUE

# Control CUDA memory allocator
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
```

---

## Model Format Conversion

```bash
# safetensors → PyTorch bin
python -c "
from safetensors.torch import load_file
import torch
state_dict = load_file('model.safetensors')
torch.save(state_dict, 'pytorch_model.bin')
"

# PyTorch bin → safetensors
python -c "
import torch
from safetensors.torch import save_file
state_dict = torch.load('pytorch_model.bin', map_location='cpu')
save_file(state_dict, 'model.safetensors')
"

# HuggingFace model → GGUF (for llama.cpp)
# Requires: git clone https://github.com/ggerganov/llama.cpp && pip install -r requirements.txt
python llama.cpp/convert_hf_to_gguf.py ./model_dir --outtype f16 --outfile model.gguf

# Quantize GGUF
./llama.cpp/llama-quantize model.gguf model-q4_k_m.gguf Q4_K_M
```

---

## Training Launch Patterns

```bash
# Single GPU with specific device
CUDA_VISIBLE_DEVICES=0 python train.py

# Multi-GPU with torchrun
torchrun --nproc_per_node=4 --master_port=29500 train.py

# HuggingFace accelerate (run accelerate config first)
accelerate launch --multi_gpu --num_processes=4 train.py

# DeepSpeed ZeRO
deepspeed --num_gpus=4 train.py --deepspeed ds_config.json

# DeepSpeed with accelerate
accelerate launch --use_deepspeed --deepspeed_config_file ds_config.json train.py

# Background with log capture
tmux new -s train "python train.py 2>&1 | tee logs/$(date +%Y%m%d_%H%M%S).log"
```

---

## Pip Mirrors (China Mainland)

```bash
# Temporary (per-install)
pip install <pkg> -i https://pypi.tuna.tsinghua.edu.cn/simple

# Persistent
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# NOTE: PyTorch --index-url takes precedence over pip mirror config
# Use BOTH for full coverage:
pip install torch --index-url https://download.pytorch.org/whl/cu124
pip install transformers -i https://pypi.tuna.tsinghua.edu.cn/simple
```
