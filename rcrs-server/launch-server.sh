#!/bin/bash
set -e

cd /app/rcrs-server/scripts

case "$RUN_TYPE" in
  precompute)
    ./start-precompute.sh -m ../maps/${MAP_NAME}/map -c ../maps/${MAP_NAME}/config -g
    ;;
  comprun)
    ./start-comprun.sh -m ../maps/${MAP_NAME}/map -c ../maps/${MAP_NAME}/config -g
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
