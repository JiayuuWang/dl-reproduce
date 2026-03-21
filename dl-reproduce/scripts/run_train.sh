#!/bin/bash
# ============================================
# Training Run Script Template
# Usage: bash scripts/run_train.sh [args...]
# ============================================

# Default parameters
CONFIG_FILE=${1:-"config.yaml"}
EXP_NAME=${2:-"experiment_$(date +%Y%m%d_%H%M%S)"}
LOG_DIR=${3:-"logs"}

# Create output directories
mkdir -p "$LOG_DIR"
mkdir -p "checkpoints/$EXP_NAME"

# Log file
LOG_FILE="$LOG_DIR/${EXP_NAME}.log"

echo "=========================================="
echo "     Training Run Script"
echo "=========================================="
echo "Experiment Name: $EXP_NAME"
echo "Log: $LOG_FILE"
echo "=========================================="

# ============================================
# Training Command (modify based on project)
# ============================================

# Option 1: Direct Python run
CMD="python train.py \
    --config $CONFIG_FILE \
    --exp_name $EXP_NAME \
    --output_dir checkpoints/$EXP_NAME \
    --logging_dir $LOG_DIR \
    ${@:3}  # Extra parameters

# Option 2: Using torchrun (distributed)
# CMD="torchrun --nproc_per_node=1 train.py \
#     --config $CONFIG_FILE \
#     --exp_name $EXP_NAME \
#     ${@:3}

# Option 3: Using accelerate
# CMD="accelerate launch train.py \
#     --config $CONFIG_FILE \
#     --exp_name $EXP_NAME \
#     ${@:3}

# ============================================
# Run Mode Selection
# ============================================

RUN_MODE=${RUN_MODE:-"foreground"}

case $RUN_MODE in
    "foreground")
        echo "Run Mode: Foreground"
        echo "Command: $CMD"
        echo ""
        eval $CMD 2>&1 | tee "$LOG_FILE"
        ;;

    "tmux")
        echo "Run Mode: tmux background"
        echo "Session Name: $EXP_NAME"

        # Create tmux session and run
        tmux new-session -d -s "$EXP_NAME" "eval $CMD 2>&1 | tee $LOG_FILE"

        echo "View log: tmux attach -t $EXP_NAME"
        echo "View log (without entering): tmux capture-pane -t $EXP_NAME -p | tail -20"
        echo "End session: tmux kill-session -t $EXP_NAME"
        ;;

    "nohup")
        echo "Run Mode: nohup background"

        nohup bash -c "$CMD" > "$LOG_FILE" 2>&1 &
        PID=$!

        echo "PID: $PID"
        echo "View log: tail -f $LOG_FILE"
        echo "End process: kill $PID"
        ;;

    *)
        echo "Unknown run mode: $RUN_MODE"
        echo "Supported modes: foreground, tmux, nohup"
        exit 1
        ;;
esac

# ============================================
# Post-Training Operations
# ============================================
echo ""
echo "=========================================="
echo "Training complete!"
echo "=========================================="

# Save final state
echo "EXP_NAME=$EXP_NAME" > "$LOG_DIR/${EXP_NAME}_env.sh"
echo "LOG_FILE=$LOG_FILE" >> "$LOG_DIR/${EXP_NAME}_env.sh"

echo "Log location: $LOG_FILE"
echo "Model location: checkpoints/$EXP_NAME"
