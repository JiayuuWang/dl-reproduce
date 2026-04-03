# Experiment Log: [EXP_NAME]

## Info

| | |
|---|---|
| **Date** | YYYY-MM-DD |
| **Project** | [repo_url](url) |
| **Paper** | [paper_title](arxiv_url) |
| **Goal** | inference / eval / train |

## Environment

```bash
# How to recreate this environment
conda create -n ENV_NAME python=3.x
conda activate ENV_NAME
pip install torch==X.X.X --index-url https://download.pytorch.org/whl/cuXXX
pip install -r requirements.txt
```

| | |
|---|---|
| GPU | |
| VRAM | |
| PyTorch | `python -c "import torch; print(torch.__version__, torch.version.cuda)"` |
| Key deps | `pip freeze \| grep -E "torch\|transformers\|accelerate"` |

## Command

```bash
# Exact command used
python train.py --args
```

## Results

| Metric | Paper | Ours | Gap |
|--------|-------|------|-----|
| | | | |

## Problems & Fixes

| Problem | Fix |
|---------|-----|
| | |

## Notes

<!-- Anything non-obvious that future you needs to know -->
