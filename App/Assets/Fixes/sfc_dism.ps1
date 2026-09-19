Write-Output "[1/2] Running System File Checker..."
sfc /scannow
Write-Output "[2/2] Running DISM Component Cleanup & Repair..."
dism.exe /Online /Cleanup-Image /RestoreHealth
Write-Output "[OK] System File Integrity verification finished."
