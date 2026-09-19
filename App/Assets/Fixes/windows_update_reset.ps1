Write-Output "[1/4] Stopping Windows Update Services..."
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptsvc -Force -ErrorAction SilentlyContinue

Write-Output "[2/4] Clearing SoftwareDistribution & Catroot2 Caches..."
if (Test-Path "$env:SystemRoot\SoftwareDistribution") {
    Rename-Item -Path "$env:SystemRoot\SoftwareDistribution" -NewName "SoftwareDistribution.old.$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force -ErrorAction SilentlyContinue
}
if (Test-Path "$env:SystemRoot\System32\catroot2") {
    Rename-Item -Path "$env:SystemRoot\System32\catroot2" -NewName "catroot2.old.$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force -ErrorAction SilentlyContinue
}

Write-Output "[3/4] Re-registering Update Services..."
Start-Service -Name cryptsvc -ErrorAction SilentlyContinue
Start-Service -Name bits -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

Write-Output "[4/4] Triggering Windows Update Detection..."
try {
    (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
} catch {
    Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -WindowStyle Hidden -ErrorAction SilentlyContinue
}
Write-Output "[OK] Windows Update components reset successfully."
