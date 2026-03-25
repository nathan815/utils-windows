# VPN Tray — MSFT-AzVPN-Manual

System tray app that monitors and manages the `MSFT-AzVPN-Manual` VPN connection.

## Features

- **Tray icon** — green when connected, red when disconnected
- **Auto-reconnect** — polls every 5 seconds and reconnects if the VPN drops (when enabled)
- **Left-click** — connect + enable auto-reconnect, or disconnect + disable auto-reconnect
- **Right-click menu** — Connect, Disconnect, Pause/Resume auto-reconnect, Exit

## Files

| File | Description |
|------|-------------|
| `VPN-Tray.ps1` | Main tray app (polling, auto-reconnect, UI) |
| `VPN-Tray-Launcher.vbs` | Windowless launcher for the tray app |
| `Toggle-VPN-Monitor.ps1` | Standalone CLI toggle for auto-reconnect flag |
| `Toggle-VPN-Monitor.vbs` | Windowless launcher for the toggle script |
| `Watch-VPN.ps1` | Original standalone monitor (retired — logic merged into tray) |
| `Watch-VPN-Launcher.vbs` | Launcher for the retired monitor |

## Setup

Run once after cloning:

```powershell
.\vpn\Install.ps1
```

This registers the `VPN-Tray-Icon` scheduled task for the current user and starts it immediately.



| Task | Trigger | Script |
|------|---------|--------|
| `VPN-Tray-Icon` | At logon | `VPN-Tray-Launcher.vbs` |

## Logs

Activity is written to `Watch-VPN.log` (gitignored) in this folder.

## Auto-reconnect Flag

Create `Watch-VPN.disabled` in this folder to pause auto-reconnect without stopping the tray.  
The tray's "Pause/Resume auto-reconnect" menu item manages this automatically.
