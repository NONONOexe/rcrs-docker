#!/bin/bash
set -e

if [ -z "$EXPERIMENT_NAME" ]; then
  echo "[ERROR] EXPERIMENT_NAME is not set." >&2
  exit 1
fi

SOURCE_DIR="/app/results/${EXPERIMENT_NAME}/server"
TARGET_DIR="/app/ringo-viewer/public/logs/rescue.log"

echo ">>> Preparing logs for viewer: $EXPERIMENT_NAME"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "[ERROR] Source log directory does not exist: $SOURCE_DIR" >&2
  exit 1
fi

LOG_FILE="${SOURCE_DIR}/rescue.log.7z"

if [ ! -f "$LOG_FILE" ]; then
  echo "[ERROR] Log file does not exist: $LOG_FILE" >&2
  exit 1
fi

echo "    -> Cleaning up target directory: $TARGET_DIR"
rm -rf "$TARGET_DIR"

echo "    -> Extracting $LOG_FILE to $TARGET_DIR"
7z x -o"$TARGET_DIR" "$LOG_FILE"

echo ">>> Log preparation complete. Starting viewer..."
npm run dev
