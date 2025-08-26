#!/bin/bash
set -e

cd /app/rcrs-server/scripts

case "$RUN_TYPE" in
  precompute)
    ./start-precompute.sh -m ../maps/${MAP_NAME}/map -c ../maps/${MAP_NAME}/config -g &
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
    ./start-comprun.sh -m ../maps/${MAP_NAME}/map -c ../maps/${MAP_NAME}/config -g
    echo "Comprun finished. Creating done file..."
    touch /app/shared/comprun.done
    ;;
  *)
    echo "Unknown RUN_TYPE: $RUN_TYPE"
    exit 1
    ;;
esac
