# Auto Build Script for EnterpriseG Builder
# This script automates the build process for Windows EnterpriseG Edition images
# Usage: .\auto-build.ps1 -BuildNumber 22621 -TargetSku EnterpriseG -InstallWimUrl "https://example.com/install.wim"

param(
    [Parameter(Mandatory=$true)]
    [string]$BuildNumber,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetSku,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallWimUrl,
    
    [string]$MsEdge = "With",
    [string]$Defender = "With",
    [string]$WinRe = "With",
    [string]$Store = "With",
    [string]$HeloSpeech = "With",
    [string]$WiFiRTL = "With"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EnterpriseG Auto Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
Set-Location $RootDir

Write-Host "Working Directory: $RootDir" -ForegroundColor Green
Write-Host ""

# Step 1: Download install.wim
Write-Host "[1/5] Downloading install.wim..." -ForegroundColor Yellow
$installWimPath = Join-Path $RootDir "install.wim"

if (Test-Path $installWimPath) {
    Write-Host "  install.wim already exists. Skipping download." -ForegroundColor Gray
} else {
    try {
        Write-Host "  Downloading from: $InstallWimUrl" -ForegroundColor Gray
        Invoke-WebRequest -Uri $InstallWimUrl -OutFile $installWimPath -UseBasicParsing
        $fileSize = (Get-Item $installWimPath).Length / 1GB
        Write-Host "  Download completed. File size: $([math]::Round($fileSize, 2)) GB" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download install.wim: $_"
        exit 1
    }
}

# Step 2: Configure Bedi.ini
Write-Host "[2/5] Configuring Bedi.ini..." -ForegroundColor Yellow
$bediIniPath = Join-Path $RootDir "Bedi.ini"

$config = @"
;#Bedi v7.44 Configurations
_sourSKU=Professional
_targSKU=$TargetSku
_store=$Store
_defender=$Defender
_msedge=$MsEdge
_helospeech=$HeloSpeech
_winre=$WinRe
_wifirtl=$WiFiRTL
"@

Set-Content -Path $bediIniPath -Value $config
Write-Host "  Configuration saved to Bedi.ini" -ForegroundColor Green
Write-Host "  Target SKU: $TargetSku" -ForegroundColor Gray
Write-Host "  Build Number: $BuildNumber" -ForegroundColor Gray

# Step 3: Verify required files
Write-Host "[3/5] Verifying required files..." -ForegroundColor Yellow
$requiredFiles = @(
    "install.wim",
    "Files\wimlib-imagex.exe",
    "Files\7z.exe",
    "Files\NSudo.exe",
    "Files\expand.exe",
    "Files\expand_new.exe",
    "Files\7z.dll",
    "Files\libwim-15.dll",
    "Files\ModLCU.cmd",
    "Files\msdelta.dll",
    "Files\PSFExtractor.exe",
    "Files\upmod.cmd"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $RootDir $file
    if (-not (Test-Path $filePath)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Missing required files:`n$($missingFiles -join "`n")"
    exit 1
}

Write-Host "  All required files verified" -ForegroundColor Green

# Step 4: Check build number folder
Write-Host "[4/5] Checking build number folder..." -ForegroundColor Yellow
$buildFolder = Join-Path $RootDir $BuildNumber
if (-not (Test-Path $buildFolder)) {
    Write-Warning "Build number folder not found: $buildFolder"
    Write-Host "  Please ensure the folder exists with required packages" -ForegroundColor Yellow
} else {
    Write-Host "  Build folder found: $buildFolder" -ForegroundColor Green
}

# Step 5: Run EnterpriseG Builder
Write-Host "[5/5] Running EnterpriseG build process..." -ForegroundColor Yellow
Write-Host ""

# Note: Bedi.cmd (EnterpriseG Builder) requires administrator privileges
# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script requires administrator privileges."
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "  Starting EnterpriseG build..." -ForegroundColor Gray
    # Run Bedi.cmd (EnterpriseG Builder)
    $process = Start-Process -FilePath "Bedi.cmd" -WorkingDirectory $RootDir -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -ne 0) {
        Write-Warning "EnterpriseG build exited with code: $($process.ExitCode)"
    } else {
        Write-Host "  Build completed successfully" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to run EnterpriseG Builder: $_"
    exit 1
}

# Step 6: Check output
Write-Host ""
Write-Host "Checking build output..." -ForegroundColor Yellow
$outputFiles = Get-ChildItem -Path $RootDir -Filter "*.wim" -ErrorAction SilentlyContinue
if ($outputFiles) {
    Write-Host "  Build output files:" -ForegroundColor Green
    foreach ($file in $outputFiles) {
        $sizeGB = [math]::Round($file.Length / 1GB, 2)
        Write-Host "    - $($file.Name) ($sizeGB GB)" -ForegroundColor Gray
    }
} else {
    Write-Warning "No output WIM files found"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Process Completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

