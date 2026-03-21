---
name: dl-reproduce
description: Deep Learning/LLM Project Reproduction Assistant - Complete workflow from environment setup to experiment management
---

## Objective
When user says "Help me reproduce XX paper/project", the agent should be able to complete the entire process from environment setup to experiment running.

## User Must Provide
1. Project info: GitHub repository link, paper name, or project description
2. Reproduction goal: Run inference, evaluate, or train?
3. Hardware: Local GPU model/VRAM, or remote server needed

---

## Workflow (Execute in Order)

### Phase 1: Project Discovery & Analysis

**Objective**: Understand the project to reproduce

1. **Get Project Information**
   - If user provides GitHub link → Use directly
   - If only paper/project name provided → Search GitHub for official implementation
   - Prefer: More stars, has README, has training scripts

2. **Clone Repository**
   ```bash
   git clone <repo_url>
   cd <project_name>
   ```

3. **Read Project Documentation**
   - Read README.md carefully
   - Find paper link (arXiv)
   - Understand project structure

4. **Extract Key Information**
   - Python version requirements
   - CUDA/PyTorch version requirements
   - Dependency list (requirements.txt, setup.py, pyproject.toml)
   - Training/inference command examples

---

### Phase 2: Environment Setup ⚡ (Core Focus)

**Objective**: Create runnable environment, **verify before proceeding to next step**

#### Step 2.1: Detect Current Environment

```bash
python --version
which python
pip --version

nvcc --version 2>/dev/null || echo "NVCC not found"

nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader
```

**Output Template**:
```
Current Environment:
- Python: 3.10.x
- CUDA: 11.8
- GPU: RTX 4090, 24GB VRAM
- System: Ubuntu 22.04
```

#### Step 2.2: Detect Network Environment (Auto-switch Mirror)

```bash
ping -c 1 -W 2 pypi.org >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Network issues detected, will use domestic mirror"
fi
```

**Decision**:
- If ping fails or latency > 500ms → Switch to domestic mirror
- Temporary setting (current install only):
  ```bash
  pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>
  ```

#### Step 2.3: Create Virtual Environment

```bash
# Using conda (recommended, suitable for deep learning)
conda create -n <project_name> python=3.x
conda activate <project_name>

# Or using venv
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate   # Windows
```

#### Step 2.4: Install Dependencies

**Priority**:
1. Project's requirements.txt
2. setup.py / pyproject.toml
3. Dependencies listed in README

**Install Command**:
```bash
pip install -r requirements.txt

# If no requirements.txt
pip install torch torchvision torchaudio
pip install transformers datasets accelerate
```

#### Step 2.5: Handle Version Conflicts (Confirm Each Step)

**Common Issues & Solutions**:

| Issue | Symptoms | Solution |
|------|------|----------|
| PyTorch version mismatch | CUDA not available | Install PyTorch with matching CUDA version |
| Python version too new | import error | Use Python version recommended by project |
| Package version conflict | ImportError: cannot import... | Pin version: `pip install package==x.x.x` |
| CUDA version too old | RuntimeError: CUDA... | Upgrade CUDA or use CPU mode |

**Process**:
```
Encounter error → Analyze error message → Propose solution → Show user → Wait confirmation → Execute fix
```

Example output:
```
❌ transformers installation failed: torch 2.0.0 incompatible with transformers>=4.30.0

Suggested Solutions:
[1] Upgrade torch to 2.1.0 (recommended)
[2] Downgrade transformers to 4.28.0
[3] Check if project has environment setup scripts

Please select [1/2/3] or enter custom solution:
```

#### Step 2.6: Install Additional Dependencies

```bash
pip install numpy pandas scikit-learn matplotlib seaborn tqdm

pip install paramiko  # For remote server
```

#### Step 2.7: Verify Environment (Run Test)

**Verification Methods**:
```bash
# Option 1: Run project's own tests
pytest tests/ 2>/dev/null || python -m unittest discover tests/ 2>/dev/null || echo "No tests found"

# Option 2: Run example code
python example.py 2>/dev/null || python demo.py 2>/dev/null || echo "No example/demo found"

# Option 3: Simple import test
python -c "import torch; import transformers; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
```

**Success Indicator**:
```
✅ Environment verification passed!
- PyTorch version: 2.1.0+cu118
- CUDA available: True
- GPU count: 1 (RTX 4090)
```

**If Verification Fails**:
```
❌ Verification failed: ImportError: cannot import 'Self' from 'typing'

Analysis: Likely transformers version issue
Suggestion: Run pip install transformers==4.36.0

Execute? [Y/n]
```

---

### Phase 3: Data & Model Preparation

**Objective**: Obtain data and models needed for training/inference

1. **Find Model Source**
   - Does README have download link
   - Need to download from HuggingFace
   - Whether there's auto-download script

2. **Find Dataset**
   - Official dataset download link
   - Kaggle / Papers with Code
   - Whether project has download script

3. **Download & Verify**
   ```bash
   # HuggingFace model
   pip install huggingface_hub
   python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='meta-llama/Llama-2-7b-hf', local_dir='./models/llama2-7b')"

   # Or use hf_hub_download
   python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='...', filename='...', local_dir='./')"

   # Dataset
   python scripts/download_data.py

   # Manual download
   wget <url>
   curl -L <url> -o <filename>
   ```

4. **Place in Correct Location**
   - Place according to project README instructions
   - Record actual path

---

### Phase 4: Experiment Running

**Objective**: Successfully run training/inference

1. **Understand Running Method**
   ```bash
   python train.py --help
   python inference.py --help

   ls scripts/
   ls -la
   ```

2. **Understand Configuration Method**
   - argparse parameters
   - YAML config files
   - Hydra configuration
   - Environment variables

3. **Prepare Run Command**
   - Adjust parameters based on user goal
   - Consider hardware limitations (reduce batch size if VRAM insufficient)

4. **Trial Run**
   ```bash
   # Small scale test (1 step)
   python train.py --max_steps 1 --eval_steps 1

   # Single inference test
   python inference.py --input "test prompt"
   ```

5. **Formal Run**
   ```bash
   # Local run
   python train.py [args]

   # Use tmux/screen for background run
   tmux new -s experiment
   python train.py [args]
   # Ctrl+B release, then D to exit
   ```

---

### Phase 5: Remote Server (Optional Module)

**Objective**: Run experiments on remote server

1. **Check SSH Configuration**
   ```bash
   ssh -o ConnectTimeout=5 user@server "echo OK" 2>/dev/null
   ls -la ~/.ssh/
   ```

2. **Sync Code and Data**
   ```bash
   rsync -avz --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' ./ user@server:/path/project/
   ```

3. **Remote Environment Setup**
   - Repeat Phase 2 on server

4. **Run Experiment**
   ```bash
   ssh user@server "cd /path/project && python train.py [args]"
   ```

5. **Monitor Progress**
   ```bash
   ssh user@server "tail -f logs/train.log"
   ssh user@server "nvidia-smi"
   ```

6. **Download Results**
   ```bash
   rsync -avz user@server:/path/project/outputs/ ./outputs/
   ```

---

### Phase 6: Experiment Management & Recording

**Objective**: Organize experiment results for reproducibility

1. **Create Experiment Record** (use templates/experiment_log.md template)

2. **Organize Output Files**
   - checkpoints/
   - logs/
   - figures/
   - results.json

---

## Key Principles

### 1. Transparent Communication
- Explain what to do before each operation
- Explain reasons when encountering issues
- Provide solution options

### 2. Verification First
- Run test to verify when unsure of success
- Don't assume "should work"

### 3. Step-by-Step Progress
- Execute in Phase order
- Report status after each Phase completion

### 4. Record Everything
- Record attempted approaches
- Record errors and solutions
- Record final configuration

---

## Success Criteria

When user says "Help me reproduce XX project", agent should deliver:
1. ✅ Runnable environment (verified)
2. ✅ Downloaded models/data
3. ✅ Executable training/inference commands
4. ✅ Experiment record document

---

## Notes

- Respect author copyright, for research purposes only
- Don't modify project's original code (unless necessary)
- Backup data before important operations
- Consider domestic network environment

## Reference Resources

- Environment check script: reference/environment_check.sh
- Error quick reference: reference/errors.md
- Command quick reference: reference/commands.md
- Environment setup template: scripts/setup_env.sh
- Training run template: scripts/run_train.sh
- Model download template: scripts/download_model.sh
- Experiment record template: templates/experiment_log.md
