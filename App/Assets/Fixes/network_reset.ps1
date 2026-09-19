Write-Output "[1/4] Resetting Winsock Catalog..."
netsh winsock reset
Write-Output "[2/4] Resetting TCP/IP Stack..."
netsh int ip reset
Write-Output "[3/4] Flushing DNS Cache..."
ipconfig /flushdns
Write-Output "[4/4] Renewing IP Lease..."
ipconfig /renew
Write-Output "[OK] Network stack reset complete."
