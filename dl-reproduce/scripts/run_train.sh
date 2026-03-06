#!/bin/bash
# ============================================
# 训练运行脚本模板
# 用法: bash scripts/run_train.sh [args...]
# ============================================

# 默认参数
CONFIG_FILE=${1:-"config.yaml"}
EXP_NAME=${2:-"experiment_$(date +%Y%m%d_%H%M%S)"}
LOG_DIR=${3:-"logs"}

# 创建输出目录
mkdir -p "$LOG_DIR"
mkdir -p "checkpoints/$EXP_NAME"

# 日志文件
LOG_FILE="$LOG_DIR/${EXP_NAME}.log"

echo "=========================================="
echo "     训练运行脚本"
echo "=========================================="
echo "实验名: $EXP_NAME"
echo "日志: $LOG_FILE"
echo "=========================================="

# ============================================
# 训练命令（根据项目修改）
# ============================================

# 方案1: 直接运行 Python
CMD="python train.py \
    --config $CONFIG_FILE \
    --exp_name $EXP_NAME \
    --output_dir checkpoints/$EXP_NAME \
    --logging_dir $LOG_DIR \
    ${@:3}  # 额外参数

# 方案2: 使用 torchrun (分布式)
# CMD="torchrun --nproc_per_node=1 train.py \
#     --config $CONFIG_FILE \
#     --exp_name $EXP_NAME \
#     ${@:3}

# 方案3: 使用 accelerate
# CMD="accelerate launch train.py \
#     --config $CONFIG_FILE \
#     --exp_name $EXP_NAME \
#     ${@:3}

# ============================================
# 运行方式选择
# ============================================

RUN_MODE=${RUN_MODE:-"前台"}

case $RUN_MODE in
    "前台")
        echo "运行模式: 前台"
        echo "命令: $CMD"
        echo ""
        eval $CMD 2>&1 | tee "$LOG_FILE"
        ;;

    "tmux")
        echo "运行模式: tmux 后台"
        echo "会话名: $EXP_NAME"
        
        # 创建 tmux 会话并运行
        tmux new-session -d -s "$EXP_NAME" "eval $CMD 2>&1 | tee $LOG_FILE"
        
        echo "查看日志: tmux attach -t $EXP_NAME"
        echo "查看日志(不进入): tmux capture-pane -t $EXP_NAME -p | tail -20"
        echo "结束会话: tmux kill-session -t $EXP_NAME"
        ;;

    "nohup")
        echo "运行模式: nohup 后台"
        
        nohup bash -c "$CMD" > "$LOG_FILE" 2>&1 &
        PID=$!
        
        echo "PID: $PID"
        echo "查看日志: tail -f $LOG_FILE"
        echo "结束进程: kill $PID"
        ;;

    *)
        echo "未知运行模式: $RUN_MODE"
        echo "支持的模式: 前台, tmux, nohup"
        exit 1
        ;;
esac

# ============================================
# 训练完成后的操作
# ============================================
echo ""
echo "=========================================="
echo "训练完成！"
echo "=========================================="

# 保存最终状态
echo "EXP_NAME=$EXP_NAME" > "$LOG_DIR/${EXP_NAME}_env.sh"
echo "LOG_FILE=$LOG_FILE" >> "$LOG_DIR/${EXP_NAME}_env.sh"

echo "日志位置: $LOG_FILE"
echo "模型位置: checkpoints/$EXP_NAME"
