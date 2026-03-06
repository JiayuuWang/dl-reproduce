# 常见错误速查表

> 深度学习项目复现过程中常见的错误及解决方案

---

## 环境依赖错误

### ModuleNotFoundError: No module named 'xxx'

**原因**：缺少 Python 包

**解决方案**：
```bash
pip install <package_name>
# 或指定版本
pip install <package_name>==x.x.x
```

---

### ImportError: cannot import name 'xxx' from 'typing'

**原因**：Python 或包的版本不兼容

**解决方案**：
```bash
# 方案1：升级/降级相关包
pip install --upgrade <package>
pip install <package>==<version>

# 方案2：检查 Python 版本
python --version
# 如果 Python 版本过高，考虑使用 conda 创建较低版本的环境
conda create -n env_name python=3.10
```

---

### pkg_resources.DistributionNotFound

**原因**：包版本不匹配或损坏

**解决方案**：
```bash
pip install --upgrade setuptools wheel
pip install --upgrade <package>
```

---

## CUDA/GPU 错误

### RuntimeError: CUDA out of memory

**原因**：GPU 显存不足

**解决方案**：
```bash
# 1. 减小 batch size
python train.py --batch_size 4

# 2. 启用梯度累积
python train.py --gradient_accumulation_steps 4

# 3. 减少模型精度（如果支持）
python train.py --precision fp16

# 4. 启用混合精度
python train.py --use_amp

# 5. 使用 torch.cuda.empty_cache() 清理缓存
```

---

### RuntimeError: CUDA error: no kernel image is available for execution

**原因**：PyTorch CUDA 版本与 GPU 不匹配

**解决方案**：
```bash
# 检查 CUDA 版本
nvcc --version
nvidia-smi

# 重新安装匹配 CUDA 版本的 PyTorch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
# 或 cu117, cu116, cu115 等
```

---

### AssertionError: Torch not compiled with CUDA enabled

**原因**：PyTorch 未启用 CUDA 支持

**解决方案**：
```bash
# 确认 PyTorch 版本
python -c "import torch; print(torch.__version__)"
python -c "import torch; print(torch.cuda.is_available())"

# 重新安装 CUDA 版本
pip uninstall torch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

---

### ValueError: Tensor for 'y' has dtype Float but expected IntType

**原因**：标签数据类型不匹配

**解决方案**：
```bash
# 检查数据集标签类型
# 转换标签类型
labels = labels.long()  # for CrossEntropyLoss
# 或
labels = labels.float()  # for BCE Loss
```

---

## 网络/下载错误

### SSL: CERTIFICATE_VERIFY_FAILED

**原因**：SSL 证书验证失败（通常是网络环境问题）

**解决方案**：
```bash
# 方案1：临时跳过 SSL 验证（不推荐用于敏感操作）
pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org <package>

# 方案2：换用国内镜像
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <package>

# 方案3：更新证书
pip install --upgrade certifi
/Applications/Python\ 3.x/Install\ Certificates.command  # macOS
```

---

### HTTPError 404: Not Found

**原因**：下载链接失效或包名错误

**解决方案**：
```bash
# 检查包名
pip search <package>  # 已废弃
pip index versions <package>

# 使用正确的包名
pip install <correct_package_name>

# 如果是模型/数据链接失效，尝试：
# 1. HuggingFace 镜像
# 2. 手动下载
# 3. 查找替代来源
```

---

### git clone failed / Connection refused

**原因**：Git 网络问题或代理配置

**解决方案**：
```bash
# 方案1：换用 https 协议
git config --global url."https://github.com/".insteadOf "git@github.com:"

# 方案2：配置代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy https://127.0.0.1:7890

# 方案3：使用镜像
git clone https://mirror.ghproxy.com/https://github.com/username/repo

# 方案4：手动下载 zip
```

---

### OSError: [Errno 28] No space left on device

**原因**：磁盘空间不足

**解决方案**：
```bash
# 查看磁盘使用
df -h

# 清理缓存
pip cache purge
rm -rf ~/.cache/pip
rm -rf ~/.*cache

# 清理 Docker
docker system prune -a

# 清理临时文件
rm -rf /tmp/*
```

---

## 权限错误

### PermissionError: [Errno 13] Permission denied

**原因**：无写入权限

**解决方案**：
```bash
# 方案1：使用虚拟环境（推荐）
python -m venv venv
source venv/bin/activate

# 方案2：使用 --user 安装
pip install --user <package>

# 方案3：检查目录权限
ls -la <directory>
# sudo 仅在必要时使用
```

---

### condaEnvironmentChangeError

**原因**：Conda 环境变更冲突

**解决方案**：
```bash
# 方案1：更新 conda
conda update conda

# 方案2：创建新环境
conda create -n new_env python=3.x
conda activate new_env

# 方案3：清理缓存
conda clean -a
```

---

## 数据处理错误

### FileNotFoundError: [Errno 2] No such file or directory

**原因**：文件路径错误

**解决方案**：
```bash
# 检查文件是否存在
ls -la <path>

# 使用绝对路径
import os
os.path.abspath("relative/path")

# 检查当前目录
import os
print(os.getcwd())
```

---

### ValueError: too many values to unpack (expected 2)

**原因**：数据格式与代码预期不符

**解决方案**：
```bash
# 检查数据格式
head -n 5 <data_file>

# 查看代码预期的数据格式
# 通常是：label,text 或 text,label 或 JSON 格式
```

---

## 并行/多GPU 错误

### RuntimeError: rank 0 FAILED

**原因**：分布式训练失败

**解决方案**：
```bash
# 方案1：检查 NCCL
python -c "import torch; print(torch.cuda.nccl.version())"

# 方案2：设置环境变量
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=0

# 方案3：使用单 GPU 测试
python train.py --nproc_per_node 1
```

---

### os._exit(-1) in <module> + AttributeError: 'NoneType' object has no attribute 'close'

**原因**：Dataloader worker 崩溃

**解决方案**：
```bash
# 减少 num_workers
python train.py --num_workers 0

# 或检查数据加载代码中的错误
```

---

## 其他常见错误

### KeyboardInterrupt 残留在并行进程

**解决方案**：
```bash
# 杀死所有 Python 进程
pkill -9 python
pkill -9 torchrun
```

---

### OMP: Error #15: Initializing libiomp5.dylib, but found initial error

**原因**：OpenMP 库冲突

**解决方案**：
```bash
# macOS
export KMP_DUPLICATE_LIB_OK=TRUE

# Linux
export OMP_NUM_THREADS=1
```

---

## 快速诊断命令

```bash
# 检查 Python 环境
python -c "import sys; print(sys.version)"
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"

# 检查依赖
pip list | grep -E "torch|numpy|transformers"

# 检查 GPU
nvidia-smi

# 检查内存
free -h

# 检查磁盘
df -h
```

---

## 获取帮助

如果遇到未列出的错误：
1. 复制完整错误信息
2. 搜索错误关键词
3. 查阅项目 README / Issues
4. 在 GitHub Issues 中搜索类似问题
