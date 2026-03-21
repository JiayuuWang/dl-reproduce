# Experiment Log Template

> Fill out this template before each experiment for reproducibility and comparison

---

## Experiment Information

| Field | Content |
|------|------|
| **Experiment Name** | |
| **Date** | |
| **Experimenter** | |
| **Project Repository** | |

---

## Experiment Objectives

### Purpose
> Briefly describe the goal of this experiment

- [ ] Reproduce paper baseline results
- [ ] Verify effectiveness of a method
- [ ] Hyperparameter search
- [ ] Other: _______

### Paper/Project Information
- Paper Title:
- arXiv ID:
- GitHub Repository:

---

## Environment Configuration

### Hardware

| Item | Configuration |
|------|------|
| GPU Model | |
| GPU Count | |
| VRAM Total | |
| Memory (RAM) | |
| System | |

### Software

| Software | Version |
|------|------|
| Python | |
| PyTorch | |
| CUDA | |
| cuDNN | |
| Key Dependencies | |

### Environment Creation Commands

```bash
# conda environment
conda create -n <env_name> python=3.x
conda activate <env_name>
pip install <packages>

# Or export environment
conda env export > environment.yml
```

---

## Dataset

### Dataset Information

| Item | Content |
|------|------|
| Dataset Name | |
| Data Source | |
| Data Size | |
| Training Set Size | |
| Validation Set Size | |
| Test Set Size | |

### Data Processing
> Describe data preprocessing steps

```
```

### Data Paths
```
/path/to/data/
├── train/
├── val/
└── test/
```

---

## Experiment Configuration

### Model Configuration

| Parameter | Value |
|------|---|
| Model Architecture | |
| Pretrained Model | |
| Model Size | |
| Number of Layers | |
| Hidden Dimension | |
| Attention Heads | |

### Training Configuration

| Parameter | Value |
|------|---|
| Batch Size | |
| Learning Rate | |
| Optimizer | |
| Scheduler | |
| Epochs | |
| Gradient Accumulation Steps | |
| Mixed Precision | |
| Random Seed | |

### Other Configuration
```
```

---

## Experiment Results

### Key Metrics

| Metric | Paper Reported | This Experiment | Gap |
|------|-----------|-----------|------|
| | | | |
| | | | |
| | | | |

### Training Curves

> Insert training curve plots

![Training Curves](figures/training_curve.png)

### Runtime

| Phase | Time |
|------|------|
| Data Preprocessing | |
| Single Epoch Training | |
| Total Training Time | |
| Inference Time | |

---

## Experiment Log

### Command

```bash
# Training command
python train.py \
    --config config.yaml \
    --exp_name exp_001 \
    --batch_size 32 \
    --learning_rate 5e-5
```

### Key Output

```
[2024-01-01 10:00:00] Starting training...
[2024-01-01 10:05:00] Epoch 1/10, Loss: 2.345
[2024-01-01 10:10:00] Eval, BLEU: 15.23
```

---

## Problems and Solutions

### Problems Encountered

| Problem | Description | Severity |
|------|------|----------|
| 1 | | High/Medium/Low |
| 2 | | High/Medium/Low |

### Solutions

**Problem 1**:
```
Resolution approach:
Attempted solutions:
Final fix:
```

---

## Code Modifications

### Modified Files

| File | Modification |
|------|----------|
| `train.py` | |
| `model.py` | |
| `data.py` | |

### Reason for Modifications
> Why these modifications were made

```
```

---

## Next Steps

- [ ] Try different learning rates
- [ ] Increase training data
- [ ] Improve model architecture
- [ ] Compare with other methods
- [ ] Other: _______

---

## Notes

> Other content that needs to be recorded

```
```

---

## Quick Links

- Training Logs: `logs/exp_001.log`
- Model Checkpoints: `checkpoints/exp_001/`
- Output Results: `outputs/exp_001/`
- Git Commit: `commit: xxxxxxx`

---

*Template usage: Copy this file to the experiment directory, rename to `exp_001.md`, and fill out based on actual situation.*
