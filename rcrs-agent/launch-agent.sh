#!/bin/bash
set -e

RESULT_DIR="/app/results/${EXPERIMENT_NAME}/${RUN_TYPE}/agent"
RESULT_PRECOMP_DIR="/app/results/${EXPERIMENT_NAME}/precompute/precomp_data"
RESULT_LOG_DIR="${RESULT_DIR}/logs"

LOG_DIR="/app/rcrs-agent/logs"
PRECOMP_DIR="/app/rcrs-agent/precomp_data"

save_precompute_data() {
  if [ ! -n "$EXPERIMENT_NAME" ]; then
    echo ">>> EXPERIMENT_NAME not set. Skipping save precompute data."
    return
  fi

  echo ">>> Save precompute data for experiment: $EXPERIMENT_NAME"

  if [ -d "$RESULT_PRECOMP_DIR" ]; then
    echo "    -> Removing precompute data directory: $RESULT_PRECOMP_DIR"
    rm -rf "$RESULT_PRECOMP_DIR"
  fi
  
  mkdir -p "$RESULT_PRECOMP_DIR"
  cp -a "$PRECOMP_DIR/." "$RESULT_PRECOMP_DIR/"
  
  echo "Precompute data are saved to: $RESULT_PRECOMP_DIR"
}

load_precompute_data() {
  if [ ! -n "$EXPERIMENT_NAME" ]; then
    echo ">>> EXPERIMENT_NAME not set. Skipping save precompute data."
    return
  fi
  if [ ! -d "$RESULT_PRECOMP_DIR" ]; then
    echo ">>> Precompute data is not found. Skipping load precompute data."
    return
  fi

  echo ">>> Load precompute data for experiment: $EXPERIMENT_NAME"

  mkdir -p "$PRECOMP_DIR"
  cp -a "$RESULT_PRECOMP_DIR/." "$PRECOMP_DIR/"

  echo "Precompute data are loaded from: $RESULT_PRECOMP_DIR"
}

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

cd /app/rcrs-agent

case "$RUN_TYPE" in
  precompute)
    # Start precomputation
    ./launch.sh -h server -allp -pre 1 2>&1 | tee console.log
    mv console.log logs/console.log

    # Archive logs
    save_precompute_data
    archive_logs

    echo "Precompute finished. Creating done file..."
    touch /app/shared/precompute.done
    exit 0
    ;;
  comprun)
    # Load precomputation data
    load_precompute_data

    # Start the agent in the background
    ./launch.sh -h server -all  2>&1 | tee console.log &

    # Get the PID of the agent process
    sleep 60
    AGENT_JAVA_PID=$(pgrep -f "adf.core.Main" | head -n 1)
    if [ -z "$AGENT_JAVA_PID" ]; then
      echo "[ERROR] Failed to find the agent's main Java process." >&2
      exit 1
    fi
    AGENT_PGID=$(ps -o pgid= -p "$AGENT_JAVA_PID" | tr -d ' ')
    echo "Agent process group started. Main PID: $AGENT_JAVA_PID, PGID: $AGENT_PGID"

    # Wait for comprun to finish
    echo "Waiting for comprun to finish..."
    while [ ! -f /app/shared/comprun.done ]; do
      if ! ps -p "$AGENT_JAVA_PID" > /dev/null; then
        echo "[ERROR] Agent process disappeared unexpectedly." >&2
        exit 1
      fi
      sleep 5
    done

    # Terminate the agent process group
    echo "Done file found. Shutting down agent..."
    rm /app/shared/comprun.done
    kill -- "-$AGENT_PGID"
    sleep 2
    mv console.log logs/console.log

    # Archive logs
    archive_logs

    echo "Agent shut down."
    exit 0
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
