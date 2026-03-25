<#
.SYNOPSIS
    System tray icon for MSFT-AzVPN-Manual.
    Polls VPN state every 5s — reconnects automatically if disconnected and auto-reconnect is enabled.
    Icon: green = connected, red = disconnected.
    Left-click: connect+enable or disconnect+disable.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$VpnName     = "MSFT-AzVPN-Manual"
$DisableFlag = "C:\Users\johnsonn\utils\vpn\Watch-VPN.disabled"
$LogFile     = "C:\Users\johnsonn\utils\vpn\Watch-VPN.log"

function Write-Log([string]$msg) {
    Add-Content -Path $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg)
}

function New-DotIcon([System.Drawing.Color]$color) {
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.FillEllipse((New-Object System.Drawing.SolidBrush($color)), 1, 1, 14, 14)
    $g.Dispose()
    $handle = $bmp.GetHicon()
    $bmp.Dispose()
    return [System.Drawing.Icon]::FromHandle($handle)
}

function Get-VpnConnected {
    $vpn = Get-VpnConnection -Name $VpnName -ErrorAction SilentlyContinue
    return ($vpn -and $vpn.ConnectionStatus -eq "Connected")
}

function Update-Tray {
    if (Get-VpnConnected) {
        $script:tray.Icon = New-DotIcon([System.Drawing.Color]::FromArgb(50, 200, 80))
        $script:tray.Text = "MSFT-AzVPN-Manual: Connected"
    } else {
        $script:tray.Icon = New-DotIcon([System.Drawing.Color]::FromArgb(210, 60, 60))
        $script:tray.Text = "MSFT-AzVPN-Manual: Disconnected"
    }
}

function Invoke-Connect {
    Remove-Item $DisableFlag -Force -ErrorAction SilentlyContinue
    $script:menuToggle.Text = "Pause auto-reconnect"
    Start-Process "rasdial.exe" -ArgumentList $VpnName -WindowStyle Hidden
    $script:tray.BalloonTipTitle = "MSFT-AzVPN-Manual"
    $script:tray.BalloonTipText  = "Connecting..."
    $script:tray.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
    $script:tray.ShowBalloonTip(2000)
    Write-Log "Manual connect requested."
}

function Invoke-Disconnect {
    New-Item -ItemType File -Path $DisableFlag -Force | Out-Null
    $script:menuToggle.Text = "Resume auto-reconnect"
    Start-Process "rasdial.exe" -ArgumentList "$VpnName /disconnect" -WindowStyle Hidden
    Write-Log "Manual disconnect requested. Auto-reconnect paused."
}

# Build tray icon
$tray         = New-Object System.Windows.Forms.NotifyIcon
$tray.Visible = $true

# Left-click: connect+enable or disconnect+disable
$tray.Add_Click({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        if (Get-VpnConnected) { Invoke-Disconnect } else { Invoke-Connect }
        Start-Sleep -Milliseconds 500
        Update-Tray
    }
})

# Context menu
$menuConnect = New-Object System.Windows.Forms.ToolStripMenuItem
$menuConnect.Text = "Connect"
$menuConnect.Add_Click({ Invoke-Connect; Start-Sleep -Milliseconds 500; Update-Tray })

$menuDisconnect = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDisconnect.Text = "Disconnect"
$menuDisconnect.Add_Click({ Invoke-Disconnect; Start-Sleep -Milliseconds 500; Update-Tray })

$menuToggle = New-Object System.Windows.Forms.ToolStripMenuItem
$menuToggle.Add_Click({
    if (Test-Path $DisableFlag) {
        Remove-Item $DisableFlag -Force -ErrorAction SilentlyContinue
        $script:menuToggle.Text = "Pause auto-reconnect"
        $script:tray.BalloonTipTitle = "MSFT-AzVPN-Manual"
        $script:tray.BalloonTipText  = "Auto-reconnect is ACTIVE."
        $script:tray.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
        $script:tray.ShowBalloonTip(2000)
        Write-Log "Auto-reconnect enabled via menu."
    } else {
        New-Item -ItemType File -Path $DisableFlag -Force | Out-Null
        $script:menuToggle.Text = "Resume auto-reconnect"
        $script:tray.BalloonTipTitle = "MSFT-AzVPN-Manual"
        $script:tray.BalloonTipText  = "Auto-reconnect is PAUSED."
        $script:tray.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Warning
        $script:tray.ShowBalloonTip(2000)
        Write-Log "Auto-reconnect disabled via menu."
    }
})

$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit.Text = "Exit"
$menuExit.Add_Click({
    $script:tray.Visible = $false
    $script:tray.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$menu.Items.Add($menuConnect)    | Out-Null
$menu.Items.Add($menuDisconnect) | Out-Null
$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
$menu.Items.Add($menuToggle)     | Out-Null
$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null
$menu.Items.Add($menuExit)       | Out-Null
$tray.ContextMenuStrip = $menu

# Set initial toggle label
if (Test-Path $DisableFlag) { $menuToggle.Text = "Resume auto-reconnect" } else { $menuToggle.Text = "Pause auto-reconnect" }

# Poll every 5s: update icon + auto-reconnect if needed
$pollTimer          = New-Object System.Windows.Forms.Timer
$pollTimer.Interval = 5000
$pollTimer.Add_Tick({
    Update-Tray
    if (-not (Test-Path $DisableFlag) -and -not (Get-VpnConnected)) {
        Write-Log "VPN disconnected. Auto-reconnecting..."
        Start-Process "rasdial.exe" -ArgumentList $VpnName -WindowStyle Hidden
    }
})
$pollTimer.Start()

Write-Log "VPN tray started."
Update-Tray
[System.Windows.Forms.Application]::Run()
