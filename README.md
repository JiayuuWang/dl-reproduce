# dl-reproduce

A Claude Code skill that helps AI agents reproduce deep learning and LLM papers quickly and correctly.

## What This Skill Does

When you say "help me reproduce XX paper/project", the agent gets expert-level heuristics for:

- **Project archetype recognition** — identifies project type (HuggingFace Trainer, custom loop, Hydra config, Docker-first, etc.) and adapts the setup strategy accordingly
- **Environment setup** — installs PyTorch with the correct CUDA version first (the #1 cause of broken DL environments), then project dependencies
- **VRAM estimation** — estimates memory needs before running, proactively suggests quantization (int8/int4/LoRA) when GPU memory is insufficient
- **Failure recovery** — decision trees for flash-attn build failures, bitsandbytes issues, CUDA mismatches, OOM, NaN loss, distributed training errors, and more
- **Smoke testing** — verifies the full pipeline with 1 step/sample before committing to a long run

## Installation

### As a Claude Code skill (recommended)

Add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "skills": [
    "github:JiayuuWang/dl-reproduce//dl-reproduce"
  ]
}
```

Or add per-project in `.claude/settings.json`:

```json
{
  "skills": [
    "github:JiayuuWang/dl-reproduce//dl-reproduce"
  ]
}
```

### Manual

Clone this repo and point Claude Code to the `dl-reproduce/` directory as a skill.

## Usage

Once installed, just ask the agent naturally:

```
Help me reproduce the LLaMA-Factory project
```

```
I want to run inference on Qwen2.5-7B on my RTX 4090
```

```
Set up the environment for this paper: https://github.com/some/repo
```

The agent will ask you for:
1. **Project source** — GitHub URL, paper name, or description
2. **Goal** — inference, evaluation, or training
3. **Hardware** — GPU model and VRAM

Then it follows a 6-phase workflow: Project Analysis → Environment Setup → VRAM Estimation → Data/Model Acquisition → Experiment Execution → Logging.

## Skill Structure

```
dl-reproduce/
├── SKILL.md                      # Core skill — workflow, heuristics, decision trees
├── reference/
│   ├── errors.md                 # Failure → fix decision trees
│   └── commands.md               # Non-obvious DL-specific commands and env vars
├── scripts/
│   ├── setup_env.sh              # PyTorch-first env setup with CUDA auto-detection
│   ├── run_train.sh              # Training launcher (python/torchrun/accelerate/deepspeed)
│   └── download_model.sh         # HuggingFace/GitHub/Kaggle downloader with resume
└── templates/
    └── experiment_log.md          # Minimal experiment record template
```

## License

MIT
