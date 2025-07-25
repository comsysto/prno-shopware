#!/usr/bin/env bash
#
# Wrapper script to automatically save the output of a Codex/OpenAI CLI session
# into a timestamped log file for later review.
#
# Usage:
#   scripts/codex-log.sh <codex-cli-command> [args...]
#
# By default, logs are written under ~/.codex_cli_logs/

set -euo pipefail

# First argument is the CLI command (e.g. 'codex', 'openai chat', etc.)
if [ $# -lt 1 ]; then
  echo "Usage: $0 <codex-cli-command> [args...]"
  exit 1
fi

CMD="$1"
shift

# Prepare logging directory and file
LOG_DIR="${LOG_DIR:-$HOME/.codex_cli_logs}"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
LOG_FILE="$LOG_DIR/${CMD// /_}-session-$TIMESTAMP.log"

echo "[INFO] Logging session to $LOG_FILE"

# Run the command, teeing both stdout and stderr to the log file
{
  echo "[SESSION START] $(date)"
  echo "Running: $CMD $*"
  echo
  "$CMD" "$@"
  echo
  echo "[SESSION END] $(date)"
} 2>&1 | tee -a "$LOG_FILE"
