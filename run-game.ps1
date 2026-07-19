# run-game.ps1 -- CRXCIBL3 one-click run
#
# Starts a local server and opens the game in your browser automatically.
# This is the ONE script you run to play/test the game from here on --
# no need to remember the python3 command, the port number, or the URL.
#
# Why a server is needed at all: the moment real art gets added (via
# this.load.image(...) in BoardwalkScene.js), browsers block loading local
# image files directly for security reasons. A local server sidesteps that
# completely, so this script is worth using even before that happens, to
# build the habit and avoid hitting a confusing error later.
#
# To stop the game: close the black server window this opens, or press
# Ctrl+C inside it.

$PORT = 8000

Write-Host "=== CRXCIBL3 -- Starting ===" -ForegroundColor Cyan

# Always run from this script's own folder, no matter where it's called from
Set-Location $PSScriptRoot

# Check python3 is actually available before trying to use it
$pythonCheck = Get-Command python3 -ErrorAction SilentlyContinue
if (-not $pythonCheck) {
    Write-Host ""
    Write-Host "python3 not found on this system." -ForegroundColor Red
    Write-Host "Install it with: winget install Python.Python.3.12" -ForegroundColor Yellow
    Write-Host "Then close and reopen PowerShell and try this script again."
    exit 1
}

# Check the port isn't already in use by a previous run
$portInUse = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host ""
    Write-Host "Port $PORT is already in use -- the game might already be running." -ForegroundColor Yellow
    Write-Host "Opening the browser to it now instead of starting a second server."
    Start-Process "http://localhost:$PORT"
    exit 0
}

Write-Host "Starting local server on port $PORT..." -ForegroundColor Green
Write-Host "(A new window will open for the server -- leave it running while you play)"
Write-Host ""

# Start the server in its own window so it's easy to see/stop, and so this
# script doesn't just hang forever waiting for it to finish
Start-Process python3 -ArgumentList "-m","http.server","$PORT" -WorkingDirectory $PSScriptRoot

# Give the server a moment to actually start before opening the browser
Start-Sleep -Seconds 2

Write-Host "Opening the game in your browser..." -ForegroundColor Green
Start-Process "http://localhost:$PORT"

Write-Host ""
Write-Host "=== Running ===" -ForegroundColor Cyan
Write-Host "To stop: close the server window that opened, or press Ctrl+C inside it."
