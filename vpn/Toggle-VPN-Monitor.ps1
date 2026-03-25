<#
.SYNOPSIS
    Toggles the VPN auto-reconnect monitor on or off, showing a top-right notification.
#>
param([switch]$Enable, [switch]$Disable)

$DisableFlag = Join-Path $PSScriptRoot "Watch-VPN.disabled"
$currently   = Test-Path $DisableFlag

if ($Enable -and -not $Disable)     { $turnOff = $false }
elseif ($Disable -and -not $Enable) { $turnOff = $true  }
else                                 { $turnOff = -not $currently }

if ($turnOff) {
    New-Item -ItemType File -Path $DisableFlag -Force | Out-Null
    $message = "Auto-reconnect is PAUSED."
} else {
    Remove-Item $DisableFlag -Force -ErrorAction SilentlyContinue
    $message = "Auto-reconnect is ACTIVE."
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$icon    = [System.Drawing.SystemIcons]::Information
$notify  = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon    = $icon
$notify.Visible = $true
$notify.BalloonTipTitle = "MSFT-AzVPN-Manual"
$notify.BalloonTipText  = $message
$notify.BalloonTipIcon  = if ($turnOff) { [System.Windows.Forms.ToolTipIcon]::Warning } else { [System.Windows.Forms.ToolTipIcon]::Info }
$notify.ShowBalloonTip(2000)

Start-Sleep -Milliseconds 2500
$notify.Dispose()
