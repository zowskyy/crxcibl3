# stop-game.ps1 -- CRXCIBL3 cleanup
#
# Use this if the server window got closed by accident, or seems stuck,
# and running run-game.ps1 again says the port is already in use.
# Safe to run any time -- does nothing if no server is running.

$PORT = 8000

Write-Host "=== CRXCIBL3 -- Stopping server on port $PORT ===" -ForegroundColor Cyan

$connection = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue

if (-not $connection) {
    Write-Host "Nothing running on port $PORT -- nothing to stop." -ForegroundColor Green
    exit 0
}

$processId = $connection.OwningProcess | Select-Object -First 1
Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue

Write-Host "Stopped." -ForegroundColor Green
