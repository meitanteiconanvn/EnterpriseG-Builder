# Test script to check Windows ADK installation - Fixed version
Write-Host "=== Testing Windows ADK Installation ===" -ForegroundColor Cyan

# Test 1: Check if oscdimg already exists
Write-Host ""
Write-Host "[1] Checking for existing oscdimg.exe..." -ForegroundColor Yellow
$oscdimgPaths = @(
    "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "${env:ProgramFiles}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe",
    "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
)

$found = $false
foreach ($path in $oscdimgPaths) {
    Write-Host "  Checking: $path"
    if (Test-Path $path) {
        Write-Host "  Found oscdimg at: $path" -ForegroundColor Green
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Host "  oscdimg not found in common locations" -ForegroundColor Red
    
    # Test 2: Test Windows ADK installer download with proper redirect handling
    Write-Host ""
    Write-Host "[2] Testing Windows ADK installer download..." -ForegroundColor Yellow
    $adkUrl = "https://go.microsoft.com/fwlink/?linkid=2249370"
    Write-Host "  URL: $adkUrl"
    
    try {
        Write-Host "  Attempting to download installer with redirect handling..."
        # Use a path without spaces
        $testFile = "adksetup-test.exe"
        
        # Follow redirects properly
        $ProgressPreference = 'SilentlyContinue'
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($adkUrl, $testFile)
        
        if (Test-Path $testFile) {
            $fileSize = (Get-Item $testFile).Length / 1MB
            Write-Host "  Download successful!" -ForegroundColor Green
            Write-Host "  File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
            
            if ($fileSize -lt 1) {
                Write-Host "  WARNING: File seems too small, might be a redirect page" -ForegroundColor Yellow
            } else {
                Write-Host "  File size looks good!" -ForegroundColor Green
            }
            
            # Check if file is actually an executable
            $fileInfo = Get-Item $testFile
            Write-Host "  File extension: $($fileInfo.Extension)" -ForegroundColor Gray
            
            # Clean up test file
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            Write-Host "  Test file cleaned up" -ForegroundColor Gray
        } else {
            Write-Host "  Download failed - file not found" -ForegroundColor Red
        }
        $client.Dispose()
    } catch {
        Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Error type: $($_.Exception.GetType().Name)" -ForegroundColor Red
    }
    
    # Test 3: Check if we can install mkisofs via WSL
    Write-Host ""
    Write-Host "[3] Checking for WSL and mkisofs..." -ForegroundColor Yellow
    $wslAvailable = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslAvailable) {
        Write-Host "  WSL is available" -ForegroundColor Green
        
        Write-Host "  Checking for mkisofs in WSL..."
        try {
            $mkisofsCheck = wsl which mkisofs 2>&1
            if ($mkisofsCheck -match "mkisofs") {
                Write-Host "  mkisofs found in WSL" -ForegroundColor Green
            } else {
                Write-Host "  mkisofs not found, attempting to install..." -ForegroundColor Yellow
                # Try to install genisoimage (which provides mkisofs)
                $installResult = wsl sudo apt-get update -qq 2>&1
                $installResult2 = wsl sudo apt-get install -y genisoimage 2>&1
                Write-Host "  Install attempt completed. Checking again..."
                $mkisofsCheck2 = wsl which mkisofs 2>&1
                if ($mkisofsCheck2 -match "mkisofs") {
                    Write-Host "  mkisofs installed successfully!" -ForegroundColor Green
                } else {
                    Write-Host "  mkisofs installation failed or not available" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "  Could not check/install mkisofs in WSL: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  WSL is not available" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
