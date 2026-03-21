# Common Commands Reference

> Commonly used commands for deep learning project reproduction

---

## Environment Management

### Conda

```bash
# Create environment
conda create -n <env_name> python=3.10
conda create -n <env_name> python=3.10 pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia

# Activate environment
conda activate <env_name>
source ~/anaconda3/etc/profile.d/conda.sh && conda activate <env_name>  # Some Linux

# Deactivate environment
conda deactivate

# List environments
conda env list

# Remove environment
conda env remove -n <env_name>

# Export environment
conda env export > environment.yml
conda env export --from-history > environment_simple.yml

# Create from yaml
conda env create -f environment.yml
```

### pip / venv

```bash
# Create virtual environment
python -m venv venv

# Activate (Linux/Mac)
source venv/bin/activate

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e .  # Editable mode

# Export dependencies
pip freeze > requirements.txt

# Upgrade package
pip install --upgrade <package>
pip install -U <package>
```

---

## Mirror Sources

### pip Mirror

```bash
# Temporary use
pip install <package> -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install <package> -i https://mirrors.aliyun.com/pypi/simple/

# Set as default
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# Restore default
pip config unset global.index-url
```

### conda Mirror

```bash
# Add mirror channels
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch

# Check configuration
conda config --show channels
```

### Git Proxy

```bash
# Replace git:// with https://
git config --global url."https://github.com/".insteadOf "git@github.com:"

# Set proxy
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890

# Remove proxy
git config --global --unset http.proxy
git config --global --unset https.proxy
```

---

## Git Operations

```bash
# Clone repository
git clone https://github.com/username/repo.git
git clone --depth 1 https://github.com/username/repo.git  # Shallow clone

# Create branch
git checkout -b experiment/xxx

# List branches
git branch -a

# Switch branch
git checkout main
git checkout -b new_branch

# Commit changes
git add .
git commit -m "description"

# Check remote
git remote -v
git fetch origin
```

---

## Model Download

### HuggingFace

```bash
# Install huggingface_hub
pip install huggingface_hub

# Download model
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='meta-llama/Llama-2-7b', local_dir='./Llama-2-7b')"

# Or use hf_hub_download
python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='meta-llama/Llama-2-7b-hf', filename='config.json', local_dir='./models')"

# Login
huggingface-cli login
# Or
python -c "from huggingface_hub import login; login('your_token')"
```

### Git LFS

```bash
# Install
pip install git-lfs

# Enable
git lfs install

# Clone large repo (auto download LFS files)
git clone https://huggingface.co/username/repo

# Manual pull
git lfs pull
```

---

## File Transfer

### rsync

```bash
# Sync to remote
rsync -avz --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' ./ user@server:/path/

# Sync to local
rsync -avz user@server:/path/outputs/ ./outputs/

# With delete (files remote has but local doesn't)
rsync -avz --delete ./ user@server:/path/
```

### scp

```bash
# Upload
scp file.txt user@server:/path/
scp -r folder/ user@server:/path/

# Download
scp user@server:/path/file.txt ./
scp -r user@server:/path/folder/ ./
```

---

## Remote Server Operations

```bash
# SSH connection
ssh user@server
ssh -i ~/.ssh/key.pem user@server

# Execute command
ssh user@server "cd /path && python train.py"

# Port forwarding
ssh -L 8888:localhost:8888 user@server
```

---

## Background Execution

### tmux

```bash
# Create session
tmux new -s experiment

# List sessions
tmux ls

# Detach session
# Ctrl+B, then press D

# Reattach
tmux attach -t experiment

# Kill session
tmux kill-session -t experiment

# Run command in session
tmux send-keys -t experiment "python train.py" Enter
```

### nohup / screen

```bash
# nohup background run
nohup python train.py > output.log 2>&1 &

# screen
screen -S experiment
python train.py
# Ctrl+A, then press D to exit

screen -ls
screen -r experiment
```

---

## Process Management

```bash
# View processes
ps aux | grep python
ps -ef | grep python

# Kill process
kill <PID>
kill -9 <PID>  # Force kill

# Kill by name
pkill -9 python
pkill -9 -f "train.py"

# Check GPU usage
nvidia-smi
watch -n 1 nvidia-smi  # Real-time monitoring

# Check port usage
lsof -i :8888
netstat -tulpn | grep 8888
```

---

## Log Viewing

```bash
# View log
tail -f log.txt
tail -n 100 log.txt
cat log.txt

# Search keywords
grep "error" log.txt
grep -n "loss" log.txt

# Real-time monitoring
watch -n 1 "tail -n 5 log.txt"
```

---

## Data Processing

```bash
# Decompress
tar -xvf file.tar
tar -xzvf file.tar.gz
tar -xjvf file.tar.bz2
unzip file.zip

# View file
head -n 10 file.txt
wc -l file.txt  # Line count

# Convert format
dos2unix file.txt  # Windows to Unix
unix2dos file.txt  # Unix to Windows
```

---

## Python Debugging

```bash
# Simple import test
python -c "import torch; print(torch.__version__)"

# Check install path
python -c "import torch; print(torch.__file__)"

# Performance profiling
python -m cProfile train.py

# Memory profiling
pip install memory_profiler
python -m memory_profiler train.py

# Interactive debug
python -i train.py
>>> import pdb; pdb.pm()
```

---

## Conda Aliases (add to ~/.bashrc)

```bash
# Quick activate common environments
alias ac='conda activate'
alias dac='conda deactivate'
alias cl='conda env list'

# Quick install
alias pipi='pip install -i https://pypi.tuna.tsinghua.edu.cn/simple'

# Git common commands
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
```

---

## Quick Check Commands

```bash
# System info
uname -a
cat /etc/os-release

# Python version
python --version
python3 --version

# pip version
pip --version
pip -V

# CUDA version
nvcc --version
nvidia-smi

# GPU info
nvidia-smi -L
nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv

# Package version
pip show <package>
pip list | grep <package>
```
