#!/bin/bash
set -e

archive_logs() {
  if [ -n "$EXPERIMENT_NAME" ]; then
    echo ">>> Archiving logs for experiment: $EXPERIMENT_NAME"

    SOURCE_LOG_DIR="/app/rcrs-agent/logs"
    DEST_DIR="/app/results/${EXPERIMENT_NAME}/agent"

    mkdir -p "$DEST_DIR"

    cp -a "$SOURCE_LOG_DIR/." "$DEST_DIR/"

    echo "Logs archived to: $DEST_DIR"
  else
    echo ">>> EXPERIMENT_NAME not set. Skipping log archiving."
  fi
}

cd /app/rcrs-agent

case "$RUN_TYPE" in
  precompute)
    # Start precomputation
    ./launch.sh -h server -allp -pre 1 2>&1 | tee console.log
    mv console.log logs/console.log

    # Archive logs
    archive_logs

    echo "Precompute finished. Creating done file..."
    touch /app/shared/precompute.done
    exit 0
    ;;
  comprun)
    # Start the agent in the background
    ./launch.sh -h server -all  2>&1 | tee console.log &

    # Get the PID of the agent process
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
