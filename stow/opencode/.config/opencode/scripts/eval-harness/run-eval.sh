#!/bin/bash
# run-eval.sh — Run eval harness tasks
# Usage: run-eval.sh [task-name] [--all]

set -euo pipefail

TASKS_DIR="/home/reeinharrrd/projects/personal/dotfiles/stow/opencode/.config/opencode/scripts/eval-harness/tasks"

if [[ $# -eq 0 ]] || [[ "$1" == "--all" ]]; then
    # Run all tasks
    for task_dir in "$TASKS_DIR"/*/; do
        task=$(basename "$task_dir")
        echo "=== Running $task ==="
        if [[ -f "$task_dir/verify.sh" ]]; then
            if bash "$task_dir/verify.sh"; then
                echo "✅ $task PASSED"
            else
                echo "❌ $task FAILED"
            fi
        else
            echo "⚠️  $task: no verify.sh"
        fi
        echo ""
    done
else
    # Run specific task
    task="$1"
    task_dir="$TASKS_DIR/$task"
    if [[ -d "$task_dir" ]]; then
        echo "=== Running $task ==="
        if [[ -f "$task_dir/verify.sh" ]]; then
            if bash "$task_dir/verify.sh"; then
                echo "✅ $task PASSED"
            else
                echo "❌ $task FAILED"
            fi
        else
            echo "⚠️  $task: no verify.sh"
        fi
    else
        echo "Task not found: $task"
        exit 1
    fi
fi
