# Auto-run wrapper for Bedi.cmd
# This script runs Bedi.cmd without requiring user input
param(
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EnterpriseG Auto Build Wrapper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Bedi.ini exists
if (-not (Test-Path "Bedi.ini")) {
    Write-Error "Bedi.ini not found. Please create it first."
    exit 1
}

Write-Host "Bedi.ini found. Reading configuration..."
$config = Get-Content "Bedi.ini" -Raw
Write-Host "Configuration loaded."
Write-Host ""

# Check if install.wim exists
if (-not (Test-Path "install.wim")) {
    Write-Error "install.wim not found in current directory"
    exit 1
}

Write-Host "Starting Bedi.cmd in non-interactive mode..."
Write-Host ""

# Create a wrapper that pipes input to Bedi.cmd
# The Choice command expects single character input
# We'll use echo to pipe "X" (exit) to the Choice command

# Method 1: Try to run Bedi.cmd and pipe responses
# Create a response file for Choice command
$responseFile = "$PWD\bedi_responses.txt"
if ($SkipCleanup) {
    "X" | Out-File -FilePath $responseFile -Encoding ASCII -NoNewline
} else {
    "C`nX" | Out-File -FilePath $responseFile -Encoding ASCII -NoNewline
}

# Run Bedi.cmd - it will read Bedi.ini and skip menu if config matches
# For the Choice prompt at the end, we need to pipe input
Write-Host "Running Bedi.cmd..."
Write-Host "Note: Any Choice prompts will be auto-answered with 'X' (Exit)"
Write-Host ""

# Use Start-Process with redirected input
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c Bedi.cmd"
$psi.WorkingDirectory = $PWD
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi

# Start process
$process.Start() | Out-Null

# Send "X" to exit when Choice prompt appears
Start-Sleep -Seconds 2
$process.StandardInput.WriteLine("X")
$process.StandardInput.Close()

# Wait for completion
$process.WaitForExit()

# Get output
$output = $process.StandardOutput.ReadToEnd()
$errorOutput = $process.StandardError.ReadToEnd()

Write-Host "=== Bedi Output ==="
Write-Host $output

if ($errorOutput) {
    Write-Host "=== Bedi Errors ==="
    Write-Host $errorOutput
}

# Check exit code
if ($process.ExitCode -ne 0) {
    Write-Warning "Bedi.cmd exited with code: $($process.ExitCode)"
    exit $process.ExitCode
} else {
    Write-Host ""
    Write-Host "Bedi.cmd completed successfully!" -ForegroundColor Green
}

# Cleanup
if (Test-Path $responseFile) {
    Remove-Item $responseFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Process Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

