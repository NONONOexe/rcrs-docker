#!/bin/bash
set -e

RESULT_DIR="/app/results/${EXPERIMENT_NAME}/${RUN_TYPE}/server"
RESULT_LOG_DIR="${RESULT_DIR}/logs"

LOG_DIR="/app/rcrs-server/logs/log"
KERNEL_LOG_FILE="$LOG_DIR/kernel.log"

cd /app/rcrs-server/scripts

# Function to archive logs
archive_logs() {
  if [ ! -n "$EXPERIMENT_NAME" ]; then
    echo ">>> EXPERIMENT_NAME not set. Skipping log archiving."
    return
  fi

  echo ">>> Archiving logs for experiment: $EXPERIMENT_NAME"

  if [ -d "$RESULT_LOG_DIR" ]; then
    echo "    -> Removing existing directory: $RESULT_LOG_DIR"
    rm -rf "$RESULT_LOG_DIR"
  fi

  echo "    -> Creating new directory: $RESULT_LOG_DIR"
  mkdir -p "$RESULT_LOG_DIR"

  echo "    -> Copying logs..."
  cp -a "$LOG_DIR/." "$RESULT_LOG_DIR/"

  echo "Logs archived to: $RESULT_LOG_DIR"
}

# Determine which map to use
if [ -z "$MAP_NAME" ]; then
  echo "[ERROR] MAP_NAME environment variable is not set." >&2
  exit 1
fi

CUSTOM_MAP_DIR="../custom-maps/${MAP_NAME}"
STANDARD_MAP_DIR="../maps/${MAP_NAME}"
MAP_DIR_TO_USE=""

# Use custom map if it exists
if [ -d "$CUSTOM_MAP_DIR" ]; then
  MAP_DIR_TO_USE="$CUSTOM_MAP_DIR"
  echo ">>> Using custom map: '$MAP_NAME'"

# Use standard map if custom map doesn't exist
elif [ -d "$STANDARD_MAP_DIR" ]; then
  MAP_DIR_TO_USE="$STANDARD_MAP_DIR"
  echo ">>> Using standard map: '$MAP_NAME'"

# Specified map not found
else
  echo "[ERROR] Map not found: '$MAP_NAME'" >&2
  exit 1
fi

MAP_ARGS="-m ${MAP_DIR_TO_USE}/map -c ${MAP_DIR_TO_USE}/config"

case "$RUN_TYPE" in
  precompute)
    # Start precomputation in the background
    ./start-precompute.sh $MAP_ARGS -g 2>&1 | tee console.log &

    # Get the PID of the main Java process in the server
    JAVA_PID=""
    for _ in $(seq 30); do
      JAVA_PID=$(pgrep -f "kernel.StartKernel" | head -n 1)
      if [ -n "$JAVA_PID" ]; then
        break
      fi
      sleep 1
    done
    if [ -z "$JAVA_PID" ]; then
      echo "[ERROR] Failed to find the server's main Java process." >&2
      exit 1
    fi
    PGID=$(ps -o pgid= "$JAVA_PID" | tr -d ' ')
    echo "Server process group started. Main PID: $JAVA_PID, PGID: $PGID"

    # Wait for precomputation to finish
    echo "Waiting for precomputation to finish..."
    while [ ! -f /app/shared/precompute.done ]; do
      sleep 5
    done

    # Terminate the server process group
    echo "Done file found. Shutting down server..."
    rm /app/shared/precompute.done
    kill -- "-$PGID"
    sleep 2

    # Archive logs
    mkdir -p "$LOG_DIR"
    mv console.log "$LOG_DIR"/console.log
    archive_logs

    echo "Server shut down."
    exit 0
    ;;
  comprun)
    echo ">>> Preapring log directory..."
    # Prepare log directory and log file
    echo "    -> Creating new directory: $LOG_DIR"
    mkdir -p "$LOG_DIR"
    echo "    -> Creating kernel.log: $LOG_DIR"
    touch "$KERNEL_LOG_FILE"

    # Start comprun in the background
    ./start-comprun.sh $MAP_ARGS -g 2>&1 | tee console.log &
    SERVER_LAUNCHER_PID=$!

    # Get the PID of the main Java process in the server
    echo "Waiting for the server to start..."
    JAVA_PID=""
    for _ in $(seq 30); do
      JAVA_PID=$(pgrep -f "kernel.StartKernel" | head -n 1)
      if [ -n "$JAVA_PID" ]; then
        break
      fi
      sleep 1
    done
    if [ -z "$JAVA_PID" ]; then
      echo "[ERROR] Failed to find the server's main Java process." >&2
      exit 1
    fi
    PGID=$(ps -o pgid= "$JAVA_PID" | tr -d ' ')
    echo "Server process group started. Main PID: $JAVA_PID, PGID: $PGID"

    # Start watchdog to monitor kernel log for shutdown message
    TIME_STEP_PATTERN="INFO kernel : Timestep [0-9]+ complete"
    SHUTDOWN_MESSAGE="INFO kernel : Kernel has shut down"
    (
      tail -F -n 0 "$KERNEL_LOG_FILE" | while read -r line; do
        if [[ "$line" =~ $TIME_STEP_PATTERN ]]; then
          echo "$line"
        fi
        if [[ "$line" == *"$SHUTDOWN_MESSAGE"* ]]; then
          echo ">>> [WATCHDOG] Kernel shutdown message detected. Forcing termination of remaining processes to prevent hanging..."
          kill -- "-$PGID" 2>/dev/null || true
          break
        fi
      done
    ) &
    WATCHDOG_PID=$!

    # Wait for the server launcher to finish
    wait "$SERVER_LAUNCHER_PID" || true
    mv console.log ../logs/log/console.log
    
    # Cleanup watchdog
    kill "$WATCHDOG_PID" 2>/dev/null || true
    archive_logs
    echo "Comprun finished. Creating done file..."
    touch /app/shared/comprun.done
    exit 0
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
