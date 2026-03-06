# 常用命令速查

> 深度学习项目复现过程中常用的命令集合

---

## 环境管理

### Conda

```bash
# 创建环境
conda create -n <env_name> python=3.10
conda create -n <env_name> python=3.10 pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia

# 激活环境
conda activate <env_name>
source ~/anaconda3/etc/profile.d/conda.sh && conda activate <env_name>  # 某些 Linux

# 退出环境
conda deactivate

# 列出环境
conda env list

# 删除环境
conda env remove -n <env_name>

# 导出环境
conda env export > environment.yml
conda env export --from-history > environment_simple.yml

# 从 yaml 创建
conda env create -f environment.yml
```

### pip / venv

```bash
# 创建虚拟环境
python -m venv venv

# 激活 (Linux/Mac)
source venv/bin/activate

# 激活 (Windows)
venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt
pip install -e .  # 可编辑模式安装

# 导出依赖
pip freeze > requirements.txt

# 升级包
pip install --upgrade <package>
pip install -U <package>
```

---

## 镜像源

### pip 镜像

```bash
# 临时使用
pip install <package> -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install <package> -i https://mirrors.aliyun.com/pypi/simple/

# 设为默认
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 恢复默认
pip config unset global.index-url
```

### conda 镜像

```bash
# 添加镜像
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch

# 查看配置
conda config --show channels
```

### Git 代理

```bash
# 替换 git:// 为 https://
git config --global url."https://github.com/".insteadOf "git@github.com:"

# 设置代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890

# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

---

## Git 操作

```bash
# 克隆仓库
git clone https://github.com/username/repo.git
git clone --depth 1 https://github.com/username/repo.git  # 浅克隆

# 创建分支
git checkout -b experiment/xxx

# 查看分支
git branch -a

# 切换分支
git checkout main
git checkout -b new_branch

# 提交更改
git add .
git commit -m "description"

# 查看远程
git remote -v
git fetch origin
```

---

## 模型下载

### HuggingFace

```bash
# 安装 huggingface_hub
pip install huggingface_hub

# 下载模型
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='meta-llama/Llama-2-7b', local_dir='./Llama-2-7b')"

# 或使用 hf_hub_download
python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='meta-llama/Llama-2-7b-hf', filename='config.json', local_dir='./models')"

# 登录
huggingface-cli login
# 或
python -c "from huggingface_hub import login; login('your_token')"
```

### Git LFS

```bash
# 安装
pip install git-lfs

# 启用
git lfs install

# 克隆大仓库（自动下载 LFS 文件）
git clone https://huggingface.co/username/repo

# 手动拉取
git lfs pull
```

---

## 文件传输

### rsync

```bash
# 同步到远程
rsync -avz --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' ./ user@server:/path/

# 同步到本地
rsync -avz user@server:/path/outputs/ ./outputs/

# 带删除（远程有本地没有的文件）
rsync -avz --delete ./ user@server:/path/
```

### scp

```bash
# 上传
scp file.txt user@server:/path/
scp -r folder/ user@server:/path/

# 下载
scp user@server:/path/file.txt ./
scp -r user@server:/path/folder/ ./
```

---

## 远程服务器操作

```bash
# SSH 连接
ssh user@server
ssh -i ~/.ssh/key.pem user@server

# 执行命令
ssh user@server "cd /path && python train.py"

# 端口转发
ssh -L 8888:localhost:8888 user@server
```

---

## 后台运行

### tmux

```bash
# 创建会话
tmux new -s experiment

# 列出会话
tmux ls

# 分离会话
# Ctrl+B, 然后按 D

# 重新连接
tmux attach -t experiment

# 杀死会话
tmux kill-session -t experiment

# 在会话中运行命令
tmux send-keys -t experiment "python train.py" Enter
```

### nohup / screen

```bash
# nohup 后台运行
nohup python train.py > output.log 2>&1 &
nohup python train.py > output.log 2>&1 &

# screen
screen -S experiment
python train.py
# Ctrl+A, 然后按 D 退出

screen -ls
screen -r experiment
```

---

## 进程管理

```bash
# 查看进程
ps aux | grep python
ps -ef | grep python

# 杀死进程
kill <PID>
kill -9 <PID>  # 强制杀死

# 按名称杀死
pkill -9 python
pkill -9 -f "train.py"

# 查看 GPU 使用
nvidia-smi
watch -n 1 nvidia-smi  # 实时监控

# 查看端口占用
lsof -i :8888
netstat -tulpn | grep 8888
```

---

## 日志查看

```bash
# 查看日志
tail -f log.txt
tail -n 100 log.txt
cat log.txt

# 搜索关键词
grep "error" log.txt
grep -n "loss" log.txt

# 实时监控
watch -n 1 "tail -n 5 log.txt"
```

---

## 数据处理

```bash
# 解压
tar -xvf file.tar
tar -xzvf file.tar.gz
tar -xjvf file.tar.bz2
unzip file.zip

# 查看文件
head -n 10 file.txt
wc -l file.txt  # 行数

# 转换格式
dos2unix file.txt  # Windows 转 Unix
unix2dos file.txt  # Unix 转 Windows
```

---

## Python 调试

```bash
# 简单测试 import
python -c "import torch; print(torch.__version__)"

# 查看安装路径
python -c "import torch; print(torch.__file__)"

# 性能分析
python -m cProfile train.py

# 内存分析
pip install memory_profiler
python -m memory_profiler train.py

# 交互式调试
python -i train.py
>>> import pdb; pdb.pm()
```

---

## Conda 常用别名（添加到 ~/.bashrc）

```bash
# 快速激活常用环境
alias ac='conda activate'
alias dac='conda deactivate'
alias cl='conda env list'

# 快速安装
alias pipi='pip install -i https://pypi.tuna.tsinghua.edu.cn/simple'

# Git 常用
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
```

---

## 快捷查看命令

```bash
# 系统信息
uname -a
cat /etc/os-release

# Python 版本
python --version
python3 --version

# pip 版本
pip --version
pip -V

# CUDA 版本
nvcc --version
nvidia-smi

# GPU 信息
nvidia-smi -L
nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv

# 包版本
pip show <package>
pip list | grep <package>
```
