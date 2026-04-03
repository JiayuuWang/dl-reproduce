#!/bin/bash
# ============================================
# Training Run Script Template
# Usage: bash scripts/run_train.sh [mode] [args...]
#
# Modes: foreground (default), tmux, nohup
# Example:
#   RUN_MODE=tmux bash scripts/run_train.sh train.py --batch_size 4
#   bash scripts/run_train.sh train.py --max_steps 1  # smoke test
# ============================================

# Parse arguments
TRAIN_SCRIPT=${1:-train.py}
shift
EXTRA_ARGS="$@"

EXP_NAME=${EXP_NAME:-"exp_$(date +%Y%m%d_%H%M%S)"}
LOG_DIR=${LOG_DIR:-"logs"}
RUN_MODE=${RUN_MODE:-"foreground"}
NUM_GPUS=${NUM_GPUS:-1}
LAUNCHER=${LAUNCHER:-"python"}  # python, torchrun, accelerate, deepspeed

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "checkpoints/$EXP_NAME"

LOG_FILE="$LOG_DIR/${EXP_NAME}.log"

echo "=========================================="
echo "  Training: $EXP_NAME"
echo "=========================================="
echo "Script:   $TRAIN_SCRIPT"
echo "Launcher: $LAUNCHER"
echo "GPUs:     $NUM_GPUS"
echo "Mode:     $RUN_MODE"
echo "Log:      $LOG_FILE"
echo "=========================================="

# ============================================
# Build launch command based on launcher
# ============================================
case $LAUNCHER in
    "python")
        CMD="python $TRAIN_SCRIPT $EXTRA_ARGS"
        ;;
    "torchrun")
        CMD="torchrun --nproc_per_node=$NUM_GPUS --master_port=${MASTER_PORT:-29500} $TRAIN_SCRIPT $EXTRA_ARGS"
        ;;
    "accelerate")
        CMD="accelerate launch --num_processes=$NUM_GPUS $TRAIN_SCRIPT $EXTRA_ARGS"
        ;;
    "deepspeed")
        DS_CONFIG=${DS_CONFIG:-"ds_config.json"}
        CMD="deepspeed --num_gpus=$NUM_GPUS $TRAIN_SCRIPT --deepspeed $DS_CONFIG $EXTRA_ARGS"
        ;;
    *)
        echo "Unknown launcher: $LAUNCHER (use: python, torchrun, accelerate, deepspeed)"
        exit 1
        ;;
esac

echo ""
echo "Command: $CMD"
echo ""

# ============================================
# Execute based on run mode
# ============================================
case $RUN_MODE in
    "foreground")
        eval "$CMD" 2>&1 | tee "$LOG_FILE"
        EXIT_CODE=${PIPESTATUS[0]}
        ;;

    "tmux")
        if ! command -v tmux &> /dev/null; then
            echo "ERROR: tmux not installed"
            exit 1
        fi
        tmux new-session -d -s "$EXP_NAME" "eval $CMD 2>&1 | tee $LOG_FILE; echo 'Exit code: '\$?"
        echo "Started in tmux session: $EXP_NAME"
        echo ""
        echo "  View:    tmux attach -t $EXP_NAME"
        echo "  Peek:    tmux capture-pane -t $EXP_NAME -p | tail -20"
        echo "  Stop:    tmux kill-session -t $EXP_NAME"
        EXIT_CODE=0
        ;;

    "nohup")
        nohup bash -c "$CMD" > "$LOG_FILE" 2>&1 &
        PID=$!
        echo "$PID" > "$LOG_DIR/${EXP_NAME}.pid"
        echo "Started in background (PID: $PID)"
        echo ""
        echo "  View log:  tail -f $LOG_FILE"
        echo "  Stop:      kill $PID"
        EXIT_CODE=0
        ;;

    *)
        echo "Unknown mode: $RUN_MODE (use: foreground, tmux, nohup)"
        exit 1
        ;;
esac

# ============================================
# Post-run
# ============================================
if [ "$RUN_MODE" = "foreground" ]; then
    echo ""
    echo "=========================================="
    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "  Training complete (exit code 0)"
    else
        echo "  Training FAILED (exit code $EXIT_CODE)"
        echo "  Check log: $LOG_FILE"
    fi
    echo "=========================================="
fi

# Save experiment metadata
cat > "$LOG_DIR/${EXP_NAME}_meta.sh" << EOF
EXP_NAME=$EXP_NAME
TRAIN_SCRIPT=$TRAIN_SCRIPT
LAUNCHER=$LAUNCHER
NUM_GPUS=$NUM_GPUS
CMD="$CMD"
LOG_FILE=$LOG_FILE
START_TIME=$(date -Iseconds)
EOF
