<#
.SYNOPSIS
    Monitors MSFT-AzVPN-Manual and reconnects if disconnected.
.DESCRIPTION
    Runs in a loop, checking every 30 seconds. If the VPN is not connected,
    it attempts to reconnect using rasdial. Logs activity to Watch-VPN.log
    in the same directory as this script.
#>

$VpnName     = "MSFT-AzVPN-Manual"
$LogFile     = Join-Path $PSScriptRoot "Watch-VPN.log"
$DisableFlag = Join-Path $PSScriptRoot "Watch-VPN.disabled"
$CheckSecs   = 30

function Write-Log {
    param([string]$Message)
    $entry = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $LogFile -Value $entry
    Write-Host $entry
}

Write-Log "Watch-VPN started. Monitoring '$VpnName' every ${CheckSecs}s."

while ($true) {
    $vpn = Get-VpnConnection -Name $VpnName -ErrorAction SilentlyContinue

    if (-not $vpn) {
        Write-Log "ERROR: VPN '$VpnName' not found. Check VPN profile name."
        Start-Sleep -Seconds $CheckSecs
        continue
    }

    if ((Test-Path $DisableFlag)) {
        # Silently skip reconnection while disabled
        Start-Sleep -Seconds $CheckSecs
        continue
    }

    if ($vpn.ConnectionStatus -ne "Connected") {
        Write-Log "VPN disconnected (status: $($vpn.ConnectionStatus)). Attempting reconnect..."
        $result = rasdial $VpnName 2>&1
        Start-Sleep -Seconds 5

        $vpn = Get-VpnConnection -Name $VpnName -ErrorAction SilentlyContinue
        if ($vpn.ConnectionStatus -eq "Connected") {
            Write-Log "Reconnected successfully."
        } else {
            Write-Log "Reconnect attempt result: $result"
        }
    }

    Start-Sleep -Seconds $CheckSecs
}
