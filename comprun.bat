@echo off

setlocal

rem argument checks
if "%1"=="" (
    echo Usage: %0 path\to\.env [agent-service-name]
    exit /b 1
)

set AGENT_SERVICE=agent-custom
if not "%2"=="" (
    set AGENT_SERVICE=%2
)

rem Precompute
set RUN_TYPE=precompute
docker compose --env-file %1 up server %AGENT_SERVICE% --exit-code-from server
if errorlevel 1 exit /b 1
docker compose down server %AGENT_SERVICE%

rem Comprun
set RUN_TYPE=comprun
docker compose --env-file %1 up server %AGENT_SERVICE% --exit-code-from %AGENT_SERVICE%
if errorlevel 1 exit /b 1
docker compose down server %AGENT_SERVICE%

endlocal
