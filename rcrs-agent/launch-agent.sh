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
    ./launch.sh -h server -all
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
