Write-Output "[1/3] Stopping Print Spooler Service..."
Stop-Service -Name Spooler -Force -ErrorAction SilentlyContinue
Write-Output "[2/3] Clearing Print Queue Files..."
Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue
Write-Output "[3/3] Starting Print Spooler Service..."
Start-Service -Name Spooler
Write-Output "[OK] Print Spooler successfully reset."
