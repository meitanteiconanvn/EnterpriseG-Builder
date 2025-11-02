# Test script to verify Windows ADK installer download
Write-Host "=== Testing Windows ADK Installer Download ===" -ForegroundColor Cyan
Write-Host ""

$adkUrl = "https://go.microsoft.com/fwlink/?linkid=2249370"
Write-Host "URL: $adkUrl" -ForegroundColor Yellow
Write-Host ""

# Method 1: Invoke-WebRequest with MaximumRedirectionCount
Write-Host "[Method 1] Testing Invoke-WebRequest with MaximumRedirectionCount..." -ForegroundColor Yellow
try {
    $testFile1 = "adksetup-method1.exe"
    $ProgressPreference = 'SilentlyContinue'
    $response = Invoke-WebRequest -Uri $adkUrl -OutFile $testFile1 -UseBasicParsing -TimeoutSec 60 -MaximumRedirectionCount 10 -PassThru
    
    if (Test-Path $testFile1) {
        $fileSize1 = (Get-Item $testFile1).Length / 1MB
        Write-Host "  Download successful!" -ForegroundColor Green
        Write-Host "  Status code: $($response.StatusCode)" -ForegroundColor Gray
        Write-Host "  File size: $([math]::Round($fileSize1, 2)) MB" -ForegroundColor Gray
        
        if ($fileSize1 -gt 1) {
            Write-Host "  Result: File size looks good (likely actual installer)" -ForegroundColor Green
        } else {
            Write-Host "  Result: File too small (likely redirect page)" -ForegroundColor Red
        }
        
        Remove-Item $testFile1 -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  Download failed - file not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $testFile1) { Remove-Item $testFile1 -Force -ErrorAction SilentlyContinue }
}

Write-Host ""

# Method 2: WebClient (handles redirects automatically)
Write-Host "[Method 2] Testing WebClient..." -ForegroundColor Yellow
try {
    $testFile2 = "adksetup-method2.exe"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($adkUrl, $testFile2)
    $client.Dispose()
    
    if (Test-Path $testFile2) {
        $fileSize2 = (Get-Item $testFile2).Length / 1MB
        Write-Host "  Download successful!" -ForegroundColor Green
        Write-Host "  File size: $([math]::Round($fileSize2, 2)) MB" -ForegroundColor Gray
        
        if ($fileSize2 -gt 1) {
            Write-Host "  Result: File size looks good (likely actual installer)" -ForegroundColor Green
        } else {
            Write-Host "  Result: File too small (likely redirect page)" -ForegroundColor Red
        }
        
        Remove-Item $testFile2 -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  Download failed - file not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $testFile2) { Remove-Item $testFile2 -Force -ErrorAction SilentlyContinue }
}

Write-Host ""

# Method 3: Check redirect URL manually
Write-Host "[Method 3] Checking redirect chain..." -ForegroundColor Yellow
try {
    $ProgressPreference = 'SilentlyContinue'
    $webRequest = [System.Net.HttpWebRequest]::Create($adkUrl)
    $webRequest.Method = "HEAD"
    $webRequest.AllowAutoRedirect = $true
    $webRequest.MaximumAutomaticRedirections = 10
    
    $response = $webRequest.GetResponse()
    $finalUrl = $response.ResponseUri.AbsoluteUri
    $contentLength = $response.ContentLength
    
    Write-Host "  Final URL: $finalUrl" -ForegroundColor Gray
    if ($contentLength -gt 0) {
        Write-Host "  Content-Length: $([math]::Round($contentLength / 1MB, 2)) MB" -ForegroundColor Gray
        if ($contentLength / 1MB -gt 1) {
            Write-Host "  Result: File size looks good" -ForegroundColor Green
        } else {
            Write-Host "  Result: File too small" -ForegroundColor Red
        }
    } else {
        Write-Host "  Content-Length: Not available" -ForegroundColor Yellow
    }
    
    $response.Close()
} catch {
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan

