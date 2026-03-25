<#
.SYNOPSIS
    Installs the VPN tray monitor scheduled task for the current user.
.DESCRIPTION
    Registers a logon-triggered scheduled task that starts VPN-Tray.ps1
    via the windowless VBS launcher. Run once after cloning the repo.
    Safe to re-run — removes any existing task before re-registering.
#>

$taskName   = "VPN-Tray-Icon"
$launcherVbs = Join-Path $PSScriptRoot "VPN-Tray-Launcher.vbs"

if (-not (Test-Path $launcherVbs)) {
    Write-Error "Launcher not found: $launcherVbs"
    exit 1
}

# Remove existing task if present
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action    = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "//Nologo `"$launcherVbs`""
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings  = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
    -Settings $settings -Principal $principal `
    -Description "MSFT-AzVPN-Manual tray monitor - auto-reconnect + tray icon" | Out-Null

Write-Host "Registered task '$taskName'." -ForegroundColor Green
Write-Host "Starting now..."
Start-ScheduledTask -TaskName $taskName
Write-Host "Done. Check your system tray." -ForegroundColor Green
