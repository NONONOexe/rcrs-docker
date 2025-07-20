#!/bin/bash
set -e

cd /app/rcrs-agent

case "$RUN_TYPE" in
  precompute)
    ./launch.sh -h server -allp -pre 1
    ;;
  comprun)
    ./launch.sh -h server -all
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
