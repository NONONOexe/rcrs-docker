#!/bin/bash
set -e

cd /app/rcrs-agent

case "$RUN_TYPE" in
  precompute)
    ./launch.sh -h server -allp -pre 1
    echo "Precompute finished. Creating done file..."
    touch /app/shared/precompute.done
    ;;
  comprun)
    ./launch.sh -h server -all &
    AGENT_PID=$!
    echo "Agent started with PID $AGENT_PID"
    echo "Waiting for comprun to finish..."
    
    while [ ! -f /app/shared/comprun.done ]
    do
      sleep 5
    done

    echo "Done file found. Shutting down agent..."
    rm /app/shared/comprun.done

    kill $AGENT_PID
    wait $AGENT_PID

    echo "Agent shut down."
    exit 0
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
