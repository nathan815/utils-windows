<#
.SYNOPSIS
    Uninstalls the VPN tray monitor — stops the process and removes the scheduled task.
#>

$taskName = "VPN-Tray-Icon"

# Stop any running tray instances
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task -and $task.State -eq "Running") {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
}

# Kill background powershell processes running the tray script
Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" | ForEach-Object {
    if ($_.CommandLine -like "*VPN-Tray.ps1*") {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped tray process (PID $($_.ProcessId))."
    }
}

# Remove scheduled task
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "Removed task '$taskName'." -ForegroundColor Yellow

# Clean up flag file if present
$flagFile = Join-Path $PSScriptRoot "Watch-VPN.disabled"
Remove-Item $flagFile -Force -ErrorAction SilentlyContinue

Write-Host "Uninstall complete." -ForegroundColor Green
