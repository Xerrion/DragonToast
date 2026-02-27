#!/usr/bin/env pwsh
# _run_tests.ps1 - Run the DragonToast busted test suite.
# Sets up Lua paths from luarocks and runs busted with any extra arguments.
# Usage: .\_run_tests.ps1 [busted args...]
# Examples: .\_run_tests.ps1 --verbose
#           .\_run_tests.ps1 --filter "gold"

param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$BustedArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Preflight checks -------------------------------------------------------

if (-not (Get-Command lua -ErrorAction SilentlyContinue)) {
    Write-Error "lua not found on PATH. Install Lua (e.g. scoop install lua)."
    exit 1
}

if (-not (Get-Command luarocks -ErrorAction SilentlyContinue)) {
    Write-Error "luarocks not found on PATH. Install luarocks (e.g. scoop install luarocks)."
    exit 1
}

if (-not (Get-Command busted -ErrorAction SilentlyContinue)) {
    Write-Error "busted not found on PATH. Install it with: luarocks install busted"
    exit 1
}

# --- Set up Lua paths from luarocks -----------------------------------------

# luarocks path outputs SET statements like: SET "LUA_PATH=..." and SET "LUA_CPATH=..."
# Parse and apply them as process-level environment variables so lua can find rocks.
foreach ($line in (& luarocks path 2>&1)) {
    if ("$line" -match '^SET "(\w+)=(.+)"$') {
        [System.Environment]::SetEnvironmentVariable($Matches[1], $Matches[2].TrimEnd('"'), 'Process')
    }
}

if (-not $env:LUA_PATH) {
    Write-Error "Failed to parse LUA_PATH from 'luarocks path' output."
    exit 1
}

# --- Run busted --------------------------------------------------------------

& busted @($BustedArgs ?? @())
exit $LASTEXITCODE
