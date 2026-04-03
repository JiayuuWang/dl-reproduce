---
name: dl-reproduce
description: Expert heuristics for reproducing deep learning / LLM papers — decision trees, failure recovery, VRAM estimation, and project archetype recognition
---

# DL Paper Reproduction — Expert Skill

## When This Skill Activates

User says anything like "help me reproduce XX", "run XX paper", "set up XX project". Immediately ask for:

1. **Project source** — GitHub URL, paper name, or description
2. **Goal** — inference, evaluation, or training?
3. **Hardware** — GPU model + VRAM, or remote server details

---

## Phase 1: Project Analysis — Read Signals, Not Just README

### Where to find version requirements (in priority order)

Most README files don't specify exact versions. Look at these signals:

| Signal | Where | What it tells you |
|--------|-------|-------------------|
| `Dockerfile` / `docker-compose.yml` | Root | Exact Python + CUDA + base image versions — **most reliable** |
| `.github/workflows/*.yml` | CI configs | Python matrix, torch version in test installs |
| `setup.cfg` / `setup.py` / `pyproject.toml` | Root | `python_requires`, install_requires with version bounds |
| `.python-version` | Root | Exact Python version (pyenv) |
| `environment.yml` | Root | Conda env with pinned versions — use directly |
| `requirements.txt` with pinned versions | Root | Version pins like `torch==2.1.0+cu118` reveal CUDA version |
| Import patterns in code | `*.py` | `from torch.nn.functional import scaled_dot_product_attention` → requires torch ≥ 2.0 |
| README "tested on" vs "requires" | README | "tested on" = soft suggestion; "requires" = hard constraint |

### Project archetype recognition

Identify the project type FIRST — it determines your entire approach:

**Type A: HuggingFace Trainer-based**
- Signals: imports `Trainer`, `TrainingArguments`, has `training_args` in code
- Setup: straightforward, `transformers` + `datasets` + `accelerate`
- Smoke test: `--max_steps 1 --eval_steps 1 --save_steps 0`
- Common issues: tokenizer version mismatches, model gating

**Type B: Custom training loop**
- Signals: explicit `for epoch in range(...)`, manual `optimizer.step()`
- Setup: read the training script line by line, trace imports
- Smoke test: add `break` after first batch or set `--epochs 1`
- Common issues: hard-coded paths, missing data preprocessing scripts

**Type C: Config-driven (Hydra / OmegaConf / mmconfig)**
- Signals: `@hydra.main`, `OmegaConf.load`, `cfg` objects everywhere, `configs/` directory
- Setup: install hydra-core, understand config hierarchy
- Smoke test: override config via CLI `python train.py model.batch_size=1 trainer.max_steps=1`
- Common issues: config path resolution, missing default configs

**Type D: Notebook-first**
- Signals: only `.ipynb` files, no training scripts
- Setup: `pip install jupyter`, convert to script with `jupyter nbconvert --to script`
- Smoke test: run first few cells
- Common issues: implicit state between cells, magic commands, display-dependent code

**Type E: Custom CUDA kernels / C++ extensions**
- Signals: `setup.py` with `CUDAExtension`, `csrc/` directory, `.cu` files
- Setup: MUST match exact CUDA version, needs `nvcc` in PATH
- Smoke test: `python setup.py build_ext --inplace` must succeed
- Common issues: CUDA arch mismatch, missing build tools (`ninja`, `gcc`)

**Type F: Docker-first**
- Signals: `Dockerfile` in root, README says "docker build"
- Setup: use Docker if available — it's almost always the fastest path
- Smoke test: `docker build -t project . && docker run --gpus all project python -c "import torch; print(torch.cuda.is_available())"`
- Common issues: large image size, NVIDIA container toolkit not installed

---

## Phase 2: Environment Setup — The Critical Decisions

### Decision: conda vs venv vs docker

```
Has Dockerfile AND user has docker+nvidia-container-toolkit?
  → YES: Use Docker. Done. Skip rest of Phase 2.
  → NO: Continue.

Needs specific Python version (e.g., 3.8 for old project)?
  → YES: Use conda (can install any Python version)
  → NO: Continue.

Has custom CUDA kernels (.cu files)?
  → YES: Use conda (better CUDA toolkit management)
  → NO: venv is fine, simpler.
```

### CRITICAL: PyTorch installation order

**ALWAYS install PyTorch FIRST, BEFORE other dependencies.** This is the #1 cause of broken environments.

Why: `pip install -r requirements.txt` lets pip resolve `torch` to a CPU-only or wrong-CUDA version. Other packages that depend on torch will then install against the wrong version.

**Correct order:**
1. Create env with correct Python version
2. Install PyTorch with explicit CUDA version URL
3. Verify: `python -c "import torch; print(torch.cuda.is_available())"` — MUST be True
4. THEN install project requirements (consider `--no-deps` if requirements.txt includes torch)

### PyTorch CUDA version mapping

Use the user's `nvcc --version` or `nvidia-smi` CUDA version to select:

| CUDA Version | PyTorch Install |
|--------------|----------------|
| 11.8 | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118` |
| 12.1 | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121` |
| 12.4 | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124` |
| 12.6+ | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126` |
| None / CPU | `pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu` |

**NOTE**: `nvidia-smi` shows driver CUDA version (upper bound), `nvcc --version` shows toolkit version (what matters). When they differ, use the lower one.

### Version pinning intelligence

When to **respect** the project's pinned versions:
- Custom CUDA kernels (.cu files, CUDAExtension)
- Specific operator usage (custom autograd functions)
- Project is actively maintained and recently tested
- Pin includes CUDA suffix (e.g., `torch==2.1.0+cu118`)

When to **try latest** instead:
- Project is >1 year old with no recent commits
- Uses only standard APIs (nn.Module, Trainer, etc.)
- Pinned version has known CVEs or bugs
- Pin is too old to support user's GPU architecture

### Network environment handling

If `pip install` is slow or times out:
```bash
# Test connectivity
curl -s --max-time 5 https://pypi.org > /dev/null && echo "PyPI OK" || echo "PyPI blocked/slow"

# For China mainland — use mirror for pip only (not for torch index-url)
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>

# HuggingFace mirror
export HF_ENDPOINT=https://hf-mirror.com

# GitHub clone mirror (if github.com is slow)
git clone https://mirror.ghproxy.com/https://github.com/user/repo
```

---

## Phase 3: VRAM Estimation — Know Before You OOM

### Quick estimation rules

**Inference (fp16):**
- VRAM ≈ 2 × model_params_in_billions GB
- 7B model → ~14GB, 13B → ~26GB, 70B → ~140GB

**Inference (int8 quantized):**
- VRAM ≈ 1 × model_params_in_billions GB
- 7B → ~7GB, 13B → ~13GB

**Inference (int4 / GPTQ / AWQ / GGUF):**
- VRAM ≈ 0.5 × model_params_in_billions GB
- 7B → ~4GB, 13B → ~7GB

**Training (full fine-tune, fp16 + AdamW):**
- VRAM ≈ 6-8 × model_params_in_billions GB (model + gradients + optimizer states)
- 7B → ~48-56GB (needs multi-GPU or DeepSpeed ZeRO-3)

**Training (LoRA/QLoRA):**
- VRAM ≈ inference VRAM + ~2-4GB overhead
- 7B LoRA fp16 → ~18GB, 7B QLoRA int4 → ~8GB

### Decision tree when VRAM is insufficient

```
User VRAM < required VRAM for target task?
│
├─ Goal is INFERENCE:
│  ├─ Try device_map="auto" (auto CPU offload)
│  ├─ Try load_in_8bit=True (bitsandbytes int8)
│  ├─ Try load_in_4bit=True (bitsandbytes int4)
│  ├─ Try GGUF format with llama.cpp / vLLM
│  └─ Last resort: use smaller model variant (7B → 3B)
│
├─ Goal is TRAINING:
│  ├─ Switch to LoRA/QLoRA (reduces VRAM 4-8x)
│  ├─ Enable gradient_checkpointing=True (trades compute for memory)
│  ├─ Reduce batch_size, increase gradient_accumulation_steps
│  ├─ Use DeepSpeed ZeRO Stage 2 or 3
│  └─ Use CPU offloading (slow but works)
│
└─ Tell user estimated VRAM needed vs available BEFORE attempting
```

---

## Phase 4: Data & Model Acquisition

### HuggingFace gated models

Many popular models (Llama, Gemma, Mistral) require access approval:
1. Check if model page says "gated" → user needs to accept license on HF website
2. User must `huggingface-cli login` with a token that has read access
3. Common error: `401 Unauthorized` or `403 Forbidden` → token issue or not approved

### Download with resume support

```python
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="<model_id>",
    local_dir="./models/<model_name>",
    resume_download=True,  # critical for large models
    max_workers=4,
)
```

### Dataset sources by priority

1. Project's own download script (check `scripts/`, `data/`, README)
2. HuggingFace Datasets (`datasets.load_dataset(...)`)
3. Direct URLs in README/paper
4. Kaggle (needs API key)
5. Papers with Code datasets page

---

## Phase 5: Running Experiments

### Smoke test strategy (ALWAYS do this first)

The goal: verify the full pipeline works end-to-end with minimal compute.

**For training:**
```bash
# HuggingFace Trainer
python train.py --max_steps 2 --eval_steps 1 --save_steps 0 --per_device_train_batch_size 1

# Custom loop — look for these args (common names)
python train.py --epochs 1 --debug  # or --dry-run, --test

# If no short-run option exists, set env var
MAX_STEPS=2 python train.py  # many scripts check this
```

**For inference:**
```bash
python inference.py --input "Hello, world"  # single input test
# or
python demo.py  # many projects have this
```

If smoke test fails, DO NOT proceed to full run. Fix the error first.

### Execution modes

**Interactive (debugging):** Run directly in terminal — see output in real time, can Ctrl+C.

**Background (long training):**
```bash
# tmux (preferred — can reattach)
tmux new -s train "python train.py --args 2>&1 | tee logs/train.log"

# nohup (simpler, no reattach)
nohup python train.py --args > logs/train.log 2>&1 &
echo $! > logs/train.pid
```

### Multi-GPU and distributed

| Method | When to use | Command |
|--------|-------------|---------|
| `torchrun` | PyTorch native distributed | `torchrun --nproc_per_node=N train.py` |
| `accelerate launch` | HuggingFace ecosystem | `accelerate launch train.py` (run `accelerate config` first) |
| `deepspeed` | Large model training, ZeRO | `deepspeed --num_gpus=N train.py --deepspeed ds_config.json` |
| Single GPU | Default | `CUDA_VISIBLE_DEVICES=0 python train.py` |

---

## Phase 6: Failure Recovery Decision Trees

These are the non-obvious fixes that save hours of debugging.

### flash-attn won't install

```
pip install flash-attn fails?
├─ Error mentions "No matching distribution"
│  → flash-attn doesn't have pre-built wheels for your torch+CUDA combo
│  → Try: pip install flash-attn --no-build-isolation
│  → Still fails? Check GPU compute capability (needs SM 80+, i.e., A100/A10/RTX 30xx+)
│  → GPU too old? Skip flash-attn:
│     model = AutoModelForCausalLM.from_pretrained(..., attn_implementation="eager")
│
├─ Error mentions "nvcc not found" or "CUDA_HOME not set"
│  → export CUDA_HOME=/usr/local/cuda  (or wherever CUDA toolkit is)
│  → Verify: nvcc --version
│
└─ Error mentions "ninja not found"
   → pip install ninja
   → Retry
```

### bitsandbytes issues

```
bitsandbytes import error?
├─ Windows:
│  → pip install bitsandbytes-windows  (or bitsandbytes>=0.43.0 which has native Windows support)
│
├─ Linux "libcudart.so not found":
│  → export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
│  → Or: export BNB_CUDA_VERSION=118  (match your CUDA)
│
└─ "CUDA Setup failed despite GPU being available":
   → pip install bitsandbytes --force-reinstall --no-cache-dir
   → Verify CUDA paths: python -c "import bitsandbytes; print(bitsandbytes.cuda_setup.main())"
```

### Model loading OOM

```
Model loads but OOM during forward pass?
├─ Try loading in lower precision:
│  model = AutoModelForCausalLM.from_pretrained(
│      model_id,
│      torch_dtype=torch.float16,        # or torch.bfloat16
│      device_map="auto",                # auto-split across GPUs + CPU
│      load_in_8bit=True,                # 8-bit quantization
│  )
│
├─ Still OOM? Try 4-bit:
│  model = AutoModelForCausalLM.from_pretrained(
│      model_id,
│      load_in_4bit=True,
│      bnb_4bit_compute_dtype=torch.float16,
│  )
│
├─ Single long sequence OOM but model loads fine?
│  → Reduce max_length / max_new_tokens
│  → Enable torch.cuda.empty_cache() between batches
│
└─ Training OOM?
   → Enable gradient_checkpointing: model.gradient_checkpointing_enable()
   → Reduce per_device_train_batch_size to 1
   → Increase gradient_accumulation_steps to compensate
   → Use DeepSpeed ZeRO-2 or ZeRO-3
```

### Training runs but loss doesn't decrease

```
Loss stuck or NaN?
├─ Loss is NaN from step 1:
│  → Learning rate too high → try 1e-5 or 2e-6
│  → Mixed precision issue → disable amp, use fp32
│  → Data has NaN/Inf → check data preprocessing
│
├─ Loss decreases then explodes:
│  → Gradient explosion → add max_grad_norm=1.0 (gradient clipping)
│  → Learning rate too high → reduce by 10x
│
├─ Loss doesn't decrease at all:
│  → Learning rate too low → try 1e-4 to 5e-5
│  → Model frozen → check that requires_grad=True for trainable params
│  → Wrong loss function → verify loss matches task (CE for classification, etc.)
│  → Data not shuffled → enable shuffling in dataloader
│
└─ Loss decreases but eval metrics don't improve:
   → Overfitting → add dropout, weight_decay, reduce epochs
   → Eval data issue → verify eval dataset is correct and preprocessed same way
```

---

## Key Principles

1. **Estimate before executing** — check VRAM, disk space, download size before starting
2. **Smoke test first** — 1 step/sample before full run, ALWAYS
3. **PyTorch first** — install torch with correct CUDA before anything else
4. **Read the project, not just the README** — Dockerfiles, CI configs, setup.py reveal more
5. **Don't modify original code unless necessary** — use config overrides, env vars, wrapper scripts
6. **Record everything** — use `templates/experiment_log.md` for reproducibility

## Reference Resources

- Error quick reference: `reference/errors.md`
- DL-specific commands: `reference/commands.md`
- Environment setup script: `scripts/setup_env.sh`
- Training run script: `scripts/run_train.sh`
- Model download script: `scripts/download_model.sh`
- Experiment log template: `templates/experiment_log.md`
