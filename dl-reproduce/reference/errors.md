# Common Errors Quick Reference

> Decision trees for the errors you'll actually hit reproducing DL papers (2024-2025)

---

## Build & Installation Failures

### flash-attn won't install

**Symptoms**: `ERROR: Could not build wheels for flash-attn`, `No matching distribution`, `nvcc fatal`

**Decision tree**:
```
1. Check GPU compute capability — flash-attn requires SM 80+ (A100, A10, RTX 30xx/40xx)
   → SM < 80 (V100=SM70, GTX 10xx/20xx): Cannot use flash-attn.
     Workaround: attn_implementation="eager" or "sdpa" in from_pretrained()

2. nvcc not found / CUDA_HOME not set:
   → export CUDA_HOME=/usr/local/cuda (or $(dirname $(dirname $(which nvcc))))
   → Verify: nvcc --version

3. ninja not found:
   → pip install ninja && pip install flash-attn --no-build-isolation

4. Torch/CUDA version mismatch:
   → flash-attn must match your torch+CUDA exactly
   → pip install flash-attn==2.5.9.post1 (pin to version that has your combo's wheel)
   → Check: https://github.com/Dao-AILab/flash-attention/releases for pre-built wheels

5. Still fails? Use SDPA (built into PyTorch ≥2.0, no install needed):
   → model = AutoModelForCausalLM.from_pretrained(..., attn_implementation="sdpa")
```

---

### bitsandbytes errors

**Symptoms**: `libbitsandbytes_*.so not found`, `CUDA Setup failed`, import errors

```
Windows:
  → bitsandbytes ≥ 0.43.0 has native Windows support
  → pip install bitsandbytes --upgrade
  → If still fails: pip install bitsandbytes-windows

Linux "libcudart.so not found":
  → export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
  → Or set: export BNB_CUDA_VERSION=118 (match your CUDA, e.g., 118, 121, 124)

"CUDA Setup failed despite GPU being available":
  → pip install bitsandbytes --force-reinstall --no-cache-dir
  → Verify: python -c "import bitsandbytes as bnb; print(bnb.__version__)"

macOS (Apple Silicon):
  → bitsandbytes does NOT support MPS quantization
  → Use MLX or coremltools instead for Apple Silicon quantization
```

---

### triton compilation errors

**Symptoms**: `ModuleNotFoundError: No module named 'triton'`, build failures on Windows

```
Windows:
  → Triton does NOT officially support Windows
  → Workaround: pip install triton-windows (community build) or disable torch.compile()
  → Set TORCH_COMPILE_DISABLE=1 env var to skip compilation

Linux build failure:
  → Usually gcc version issue: needs gcc ≥ 7
  → pip install triton --no-cache-dir

Import error after install:
  → Triton version must match torch version
  → pip install triton==2.1.0 (for torch 2.1), triton==2.2.0 (for torch 2.2), etc.
```

---

## CUDA / GPU Errors

### RuntimeError: CUDA out of memory

**DO NOT just retry** — calculate whether it can work first. See VRAM estimation in SKILL.md.

**Quick fixes by priority:**
```
1. Reduce batch_size (most effective, try halving each time)
2. Enable gradient_checkpointing: model.gradient_checkpointing_enable()
3. Use mixed precision: --fp16 or --bf16 (halves activation memory)
4. Increase gradient_accumulation_steps (same effective batch, less VRAM)
5. Quantize model: load_in_8bit=True or load_in_4bit=True
6. CPU offload: device_map="auto" with accelerate
7. DeepSpeed ZeRO Stage 2/3 for multi-GPU
```

**Debugging VRAM usage:**
```python
# See what's using VRAM
print(torch.cuda.memory_summary())

# Reset peak stats
torch.cuda.reset_peak_memory_stats()

# After forward pass
print(f"Peak VRAM: {torch.cuda.max_memory_allocated() / 1e9:.1f} GB")
```

---

### CUDA version / kernel mismatch

**Symptoms**: `no kernel image is available for execution`, `CUDA error: device-side assert`

```
1. Check actual CUDA version used by torch:
   python -c "import torch; print(torch.version.cuda)"

2. Compare with nvidia-smi CUDA version (driver capability):
   nvidia-smi | grep "CUDA Version"

3. Mismatch? Reinstall torch with correct CUDA:
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   (see SKILL.md for full URL table)

4. GPU architecture not supported by installed torch:
   → Very new GPU (e.g., RTX 50xx) + old torch → upgrade torch
   → Very old GPU (e.g., GTX 1080) + new project → may need older torch or CPU mode
```

---

### torch.compile() failures

**Symptoms**: `torch._dynamo` errors, `TorchDynamo internal error`, slow compilation

```
Quick fix — disable it:
  → Set env var: TORCH_COMPILE_DISABLE=1
  → Or: torch._dynamo.config.suppress_errors = True
  → Or in code: replace @torch.compile with pass-through

When to actually fix:
  → Only if the project explicitly requires torch.compile for performance
  → Usually safe to disable — it's an optimization, not a requirement
```

---

## HuggingFace Errors

### 401 / 403 on model download

**Symptoms**: `401 Unauthorized`, `403 Forbidden`, `Access to model is restricted`

```
Gated model (Llama, Gemma, Mistral, etc.):
  1. Go to model page on huggingface.co → click "Request access"
  2. Wait for approval (usually instant for most models)
  3. Create token: huggingface.co/settings/tokens (need "read" scope)
  4. Login: huggingface-cli login (paste token)
  5. Retry download

Token issues:
  → Token expired → generate new one
  → Wrong token scope → needs at least "read" permission
  → env var: export HF_TOKEN=hf_xxxxx (alternative to login)
```

---

### safetensors vs bin format

**Symptoms**: `FileNotFoundError: model.safetensors`, weight loading mismatches

```
Project expects .bin but model only has .safetensors (or vice versa):

Option 1: Let transformers handle it (usually works):
  → AutoModelForCausalLM.from_pretrained() auto-detects format

Option 2: Force format:
  → model = AutoModelForCausalLM.from_pretrained(..., use_safetensors=True)
  → model = AutoModelForCausalLM.from_pretrained(..., use_safetensors=False)

Option 3: Convert:
  → safetensors → bin:
     python -c "from safetensors.torch import load_file; import torch; torch.save(load_file('model.safetensors'), 'pytorch_model.bin')"
  → bin → safetensors:
     python -c "import torch; from safetensors.torch import save_file; save_file(torch.load('pytorch_model.bin'), 'model.safetensors')"
```

---

### Tokenizer version mismatch

**Symptoms**: `ValueError: expected sequence of length X but got Y`, wrong tokens, garbled output

```
1. Check if tokenizer matches model:
   → Use same repo_id for both model and tokenizer
   → tokenizer = AutoTokenizer.from_pretrained("same/model_id")

2. chat_template errors:
   → Old transformers doesn't support chat_template → pip install transformers>=4.34

3. Special tokens mismatch (especially with fine-tuned models):
   → Check tokenizer_config.json for special tokens
   → Ensure pad_token is set: tokenizer.pad_token = tokenizer.eos_token
```

---

## Training Errors

### Loss is NaN or explodes

```
NaN from step 1:
  → Learning rate too high (try 1e-5 or 2e-6)
  → Data has NaN/Inf values — check preprocessing
  → Mixed precision issue — try fp32 or bf16 instead of fp16

Loss decreases then suddenly NaN/Inf:
  → Gradient explosion → set max_grad_norm=1.0
  → Learning rate too high → reduce 10x
  → Specific batch has bad data → add data validation

Loss doesn't decrease at all:
  → Learning rate too low (try 1e-4 to 5e-5)
  → Model weights frozen — check requires_grad
  → Wrong loss function for task
  → Data not shuffled in dataloader
```

---

### Distributed training failures

**Symptoms**: `NCCL error`, `rank X failed`, `timeout`, `connection refused`

```
NCCL timeout:
  → export NCCL_TIMEOUT=1800 (increase from default 300s)
  → export NCCL_DEBUG=INFO (see what's happening)
  → Check: all GPUs visible? (nvidia-smi should show all)

Address already in use:
  → kill previous training: pkill -f torchrun
  → Or change port: torchrun --master_port=29501 train.py

Single GPU works, multi-GPU fails:
  → Test NCCL: python -c "import torch.distributed as dist; dist.init_process_group('nccl')"
  → Check firewall: GPUs must communicate via localhost
  → Try GLOO backend: --dist_backend gloo (slower but more compatible)
```

---

### DataLoader worker crashes

**Symptoms**: `DataLoader worker (pid X) exited unexpectedly`, `Broken pipe`

```
Quick fix: --num_workers 0 (disable multiprocessing, slower but stable)

Root causes:
  → Shared memory too small (Docker): --shm-size=8g or --ipc=host
  → Data file corrupted: verify dataset integrity
  → Memory leak in transform: simplify data augmentation
  → Too many workers: reduce to num_workers=2
```

---

## Network / Download Errors

### SSL: CERTIFICATE_VERIFY_FAILED

```
pip install:
  → pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org <package>
  → Or use mirror: pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>

HuggingFace:
  → export CURL_CA_BUNDLE=""  (temporary, not secure)
  → pip install --upgrade certifi

git clone:
  → git config --global http.sslVerify false (temporary, not secure)
  → Or use mirror/proxy
```

---

### git clone slow / fails

```
GitHub slow or blocked:
  → Shallow clone: git clone --depth 1 <url>
  → Mirror: git clone https://mirror.ghproxy.com/https://github.com/user/repo
  → Download zip: curl -L https://github.com/user/repo/archive/refs/heads/main.zip -o repo.zip

HuggingFace repo slow:
  → export HF_ENDPOINT=https://hf-mirror.com
  → Use snapshot_download with resume_download=True and max_workers=4
```

---

### Disk space errors

```
Check: df -h (Linux) or Get-Volume (Windows PowerShell)

Free space quickly:
  → pip cache purge
  → conda clean -a
  → rm -rf ~/.cache/huggingface/hub/ (large model cache)
  → docker system prune -a (if using Docker)

Prevention:
  → Check model size BEFORE downloading (huggingface.co model card shows size)
  → Use symlinks: HF_HUB_CACHE=/path/to/large/drive/hf_cache
```

---

## Quick Diagnostic Commands

```bash
# Full environment check
python -c "
import torch
print(f'torch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'VRAM: {torch.cuda.get_device_properties(0).total_mem / 1e9:.1f} GB')
    print(f'GPU arch: sm_{torch.cuda.get_device_capability(0)[0]}{torch.cuda.get_device_capability(0)[1]}')
"

# Check for common package conflicts
pip check 2>&1 | head -20

# GPU memory usage
nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv
```
