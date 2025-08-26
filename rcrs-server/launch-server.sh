#!/bin/bash
set -e

cd /app/rcrs-server/scripts

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
    ./start-precompute.sh $MAP_ARGS -g &
    SERVER_PID=$!
    echo "Server started with PID $SERVER_PID"
    echo "Waiting for precomputation to finish..."
    
    while [ ! -f /app/shared/precompute.done ]
    do
      sleep 5
    done

    echo "Done file found. Shutting down server..."
    rm /app/shared/precompute.done

    kill $SERVER_PID
    wait $SERVER_PID

    echo "Server shut down."
    exit 0
    ;;
  comprun)
    ./start-comprun.sh $MAP_ARGS -g
    echo "Comprun finished. Creating done file..."
    touch /app/shared/comprun.done
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
