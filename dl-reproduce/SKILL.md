---
name: dl-reproduce
description: 深度学习/LLM 项目复现助手 - 自动化环境配置到实验管理的完整工作流
---

## 目标
当用户说"帮我复现 XX 论文/项目"时，agent 应能独立完成从环境配置到实验运行的全流程。

## 用户需提供
1. 项目信息：GitHub 仓库链接、论文名称、或项目描述
2. 复现目标：运行推理、做评估、还是训练？
3. 硬件情况：本地 GPU 型号/显存、是否需要远程服务器

---

## 工作流（按顺序执行）

### Phase 1: 项目发现与分析

**目标**：理解要复现的项目

1. **获取项目信息**
   - 如果用户提供了 GitHub 链接 → 直接使用
   - 如果只提供了论文/项目名称 → 搜索 GitHub 找到官方实现
   - 优先选择：stars 多、有 README、有训练脚本的项目

2. **克隆仓库**
   ```bash
   git clone <repo_url>
   cd <project_name>
   ```

3. **阅读项目文档**
   - 仔细阅读 README.md
   - 查找论文链接（arXiv）
   - 了解项目结构

4. **提取关键信息**
   - Python 版本要求
   - CUDA/PyTorch 版本要求
   - 依赖列表（requirements.txt, setup.py, pyproject.toml）
   - 训练/推理命令示例

---

### Phase 2: 环境配置 ⚡（核心重点）

**目标**：创建可运行的环境，**每步验证后才进入下一步**

#### Step 2.1: 检测当前环境

```bash
python --version
which python
pip --version

nvcc --version 2>/dev/null || echo "NVCC not found"

nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader
```

**输出模板**：
```
当前环境：
- Python: 3.10.x
- CUDA: 11.8
- GPU: RTX 4090, 24GB 显存
- 系统: Ubuntu 22.04
```

#### Step 2.2: 检测网络环境（自动切换镜像）

```bash
ping -c 1 -W 2 pypi.org >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "检测到网络问题，将使用国内镜像源"
fi
```

**决策**：
- 如果 ping 失败或延迟 > 500ms → 切换到国内镜像
- 临时设置（仅当前安装）：
  ```bash
  pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>
  ```

#### Step 2.3: 创建虚拟环境

```bash
# 使用 conda（推荐，适合深度学习）
conda create -n <project_name> python=3.x
conda activate <project_name>

# 或者使用 venv
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate   # Windows
```

#### Step 2.4: 安装依赖

**优先级**：
1. 项目自带的 requirements.txt
2. setup.py / pyproject.toml
3. README 中列出的依赖

**安装命令**：
```bash
pip install -r requirements.txt

# 如果没有 requirements.txt
pip install torch torchvision torchaudio
pip install transformers datasets accelerate
```

#### Step 2.5: 处理版本冲突（每步需确认）

**常见问题与解决方案**：

| 问题 | 症状 | 解决方案 |
|------|------|----------|
| PyTorch 版本不匹配 | CUDA not available | 安装对应 CUDA 版本的 PyTorch |
| Python 版本过高 | import error | 使用项目推荐的 Python 版本 |
| 依赖包版本冲突 | ImportError: cannot import... | 固定版本：`pip install package==x.x.x` |
| CUDA 版本过低 | RuntimeError: CUDA... | 升级 CUDA 或使用 CPU 模式 |

**处理流程**：
```
遇到错误 → 分析错误信息 → 提出解决方案 → 展示给用户 → 等待确认 → 执行修复
```

示例输出：
```
❌ 安装 transformers 失败：torch 2.0.0 与 transformers>=4.30.0 不兼容

建议方案：
[1] 升级 torch 到 2.1.0（推荐）
[2] 降级 transformers 到 4.28.0
[3] 查看项目是否有环境配置脚本

请选择 [1/2/3] 或输入自定义方案：
```

#### Step 2.6: 安装额外依赖

```bash
pip install numpy pandas scikit-learn matplotlib seaborn tqdm

pip install paramiko  # 远程服务器需要
```

#### Step 2.7: 验证环境（运行测试）

**验证方式**：
```bash
# 方式1：运行项目自带测试
pytest tests/ 2>/dev/null || python -m unittest discover tests/ 2>/dev/null || echo "No tests found"

# 方式2：运行示例代码
python example.py 2>/dev/null || python demo.py 2>/dev/null || echo "No example/demo found"

# 方式3：简单 import 测试
python -c "import torch; import transformers; print(f'PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
```

**成功标志**：
```
✅ 环境验证通过！
- PyTorch 版本: 2.1.0+cu118
- CUDA 可用: True
- GPU 数量: 1 (RTX 4090)
```

**如果验证失败**：
```
❌ 验证失败：ImportError: cannot import 'Self' from 'typing'

分析：可能是 transformers 版本问题
建议：运行 pip install transformers==4.36.0

是否执行？[Y/n]
```

---

### Phase 3: 数据与模型准备

**目标**：获取训练/推理所需的数据和模型

1. **查找模型来源**
   - README 中是否有下载链接
   - 是否需要从 HuggingFace 下载
   - 是否有脚本自动下载

2. **查找数据集**
   - 官方数据集下载链接
   - Kaggle / Papers with Code
   - 项目内是否有 download 脚本

3. **下载并验证**
   ```bash
   # HuggingFace 模型
   pip install huggingface_hub
   python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='meta-llama/Llama-2-7b-hf', local_dir='./models/llama2-7b')"

   # 或使用 hf_hub_download
   python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='...', filename='...', local_dir='./')"

   # 数据集
   python scripts/download_data.py

   # 手动下载
   wget <url>
   curl -L <url> -o <filename>
   ```

4. **放置到正确位置**
   - 按照项目 README 的说明放置
   - 记录实际路径

---

### Phase 4: 实验运行

**目标**：成功运行训练/推理

1. **理解运行方式**
   ```bash
   python train.py --help
   python inference.py --help

   ls scripts/
   ls -la
   ```

2. **理解配置方式**
   - argparse 参数
   - YAML 配置文件
   - Hydra 配置
   - 环境变量

3. **准备运行命令**
   - 根据用户目标调整参数
   - 考虑硬件限制（显存不足时减小 batch size）

4. **试运行**
   ```bash
   # 小规模测试（1 step）
   python train.py --max_steps 1 --eval_steps 1

   # 单次推理测试
   python inference.py --input "test prompt"
   ```

5. **正式运行**
   ```bash
   # 本地运行
   python train.py [args]

   # 使用 tmux/screen 后台运行
   tmux new -s experiment
   python train.py [args]
   # Ctrl+B 松开，再按 D 退出
   ```

---

### Phase 5: 远程服务器（可选模块）

**目标**：在远程服务器上运行实验

1. **检查 SSH 配置**
   ```bash
   ssh -o ConnectTimeout=5 user@server "echo OK" 2>/dev/null
   ls -la ~/.ssh/
   ```

2. **同步代码和数据**
   ```bash
   rsync -avz --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' ./ user@server:/path/project/
   ```

3. **远程环境配置**
   - 在服务器上重复 Phase 2

4. **运行实验**
   ```bash
   ssh user@server "cd /path/project && python train.py [args]"
   ```

5. **监控进度**
   ```bash
   ssh user@server "tail -f logs/train.log"
   ssh user@server "nvidia-smi"
   ```

6. **下载结果**
   ```bash
   rsync -avz user@server:/path/project/outputs/ ./outputs/
   ```

---

### Phase 6: 实验管理与记录

**目标**：整理实验结果，便于复现

1. **创建实验记录**（使用 templates/experiment_log.md 模板）

2. **整理输出文件**
   - checkpoints/
   - logs/
   - figures/
   - results.json

---

## 关键原则

### 1. 透明沟通
- 每步操作前说明要做什么
- 遇到问题解释原因
- 提供解决方案选项

### 2. 验证优先
- 不确定是否成功时，运行测试验证
- 不要假设"应该可以"

### 3. 逐步推进
- 按 Phase 顺序执行
- 每个 Phase 完成后汇报状态

### 4. 记录一切
- 记录尝试过的方案
- 记录错误和解决方案
- 记录最终配置

---

## 成功标准

当用户说"帮我复现 XX 项目"时，agent 应交付：
1. ✅ 可运行的环境（已验证）
2. ✅ 下载好的模型/数据
3. ✅ 可执行的训练/推理命令
4. ✅ 实验记录文档

---

## 注意事项

- 尊重作者版权，仅用于研究目的
- 不修改项目原始代码（除非必要）
- 重要操作前备份数据
- 考虑国内网络环境

## 参考资源

- 环境检测脚本：reference/environment_check.sh
- 错误速查：reference/errors.md
- 命令速查：reference/commands.md
- 环境配置模板：scripts/setup_env.sh
- 训练运行模板：scripts/run_train.sh
- 模型下载模板：scripts/download_model.sh
- 实验记录模板：templates/experiment_log.md
