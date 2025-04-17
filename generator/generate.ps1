# PowerShell script to generate Steam Language and Protobuf files using local tools.

# Prerequisites:
# 1. .NET SDK installed (for GoSteamLanguageGenerator tool).
# 2. Go compiler and tools installed (for go run and gofmt).
# 3. Protobuf compiler (protoc) installed and in PATH.
# 4. The 'SteamKit' submodule directory must be present relative to the 'generator' directory.
# 5. The 'GoSteamLanguageGenerator' tool must be built and present at 'generator/GoSteamLanguageGenerator/bin/Debug/GoSteamLanguageGenerator.exe'.

param(
    # Specify which parts to generate: 'steamlang', 'proto', or 'all' (default)
    [ValidateSet('steamlang', 'proto', 'all')]
    [string]$Target = 'all'
)

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Get the parent directory (expected to be the root of go-steam)
$GoSteamDir = Split-Path -Parent $ScriptDir

Write-Host "Go-Steam Directory: $GoSteamDir"
Write-Host "Generator Script Directory: $ScriptDir"
Write-Host "Target: $Target"

# --- Define required paths ---
$GeneratorGoPath = Join-Path $ScriptDir "generator.go"
$GeneratorToolPath = Join-Path $ScriptDir "GoSteamLanguageGenerator\bin\Debug\GoSteamLanguageGenerator.exe"
$SteamKitPath = Join-Path $ScriptDir "SteamKit"

# --- Check prerequisites ---
Write-Host "Checking prerequisites..."

if (-not (Test-Path $GeneratorGoPath)) {
    Write-Error "Generator script 'generator.go' not found at $GeneratorGoPath"
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for Generator Tool only if targeting steamlang or all
if ($Target -eq 'steamlang' -or $Target -eq 'all') {
    if (-not (Test-Path $GeneratorToolPath)) {
        Write-Warning "GoSteamLanguageGenerator.exe not found at $GeneratorToolPath. Steam Language generation will likely fail. Ensure the tool is built."
        # Allow proceeding, but warn the user.
    }
}

if (-not (Test-Path $SteamKitPath -PathType Container)) {
    Write-Error "'SteamKit' subdirectory not found in $ScriptDir. Please ensure git submodules are initialized."
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for protoc command
if (-not (Get-Command protoc -ErrorAction SilentlyContinue)) {
    Write-Error "'protoc' command not found in PATH. Please install the Protobuf compiler."
    Read-Host "Press Enter to exit"
    exit 1
}

# Check for go command
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Error "'go' command not found in PATH. Please install the Go compiler and tools."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Prerequisites seem OK."

# --- Change to the go-steam directory --- 
# The generator.go script seems to expect paths relative to the go-steam root
Push-Location $GoSteamDir
Write-Host "Changed directory to: $($PWD.Path)"

# --- Execute the Go generator program --- 
Write-Host "Executing Go generator program..."

$success = $true
$goArgs = @("run", "generator/generator.go") # Base arguments

# Add target arguments based on the $Target parameter
switch ($Target) {
    'steamlang' { $goArgs += 'steamlang' }
    'proto'     { $goArgs += 'proto' }
    'all'       { $goArgs += 'steamlang', 'proto' }
}

Write-Host "Running command: go $($goArgs -join ' ')"

try {
    # Execute the Go program
    & go $goArgs
    Write-Host "Go generator program finished successfully."
} catch {
    Write-Error "Go generator program failed. Error: $_"
    $success = $false
}

# --- Return to original location --- 
Pop-Location

# --- Final Status --- 
if ($success) {
    Write-Host "Generation process completed successfully for target '$Target'."
} else {
    Write-Error "Generation process failed for target '$Target'. Please review the errors above."
    # Pause the script so the user can see the error in the console
    Read-Host "Press Enter to exit"
    exit 1
}

# Pause at the end if successful too, unless running non-interactively
if ($Host.UI.RawUI.KeyAvailable -and ($ExecutionContext.SessionState.IsScript)) {
    # Don't pause if running non-interactively
} else {
    Read-Host "Press Enter to exit"
}

exit 0 