# Proxy Toggle for Plasma 
An ultra-simple Plasma widget that allows you to toggle proxy with a simple click. You can easily configure the host and ports inside the widget settings window. 

## How it works
1. Runs a bundled bash script that sets the standard proxy environment
   variables (`HTTP_PROXY`, `HTTPS_PROXY`, `FTP_PROXY`, `ALL_PROXY`,
   `SOCKS_PROXY`, `NO_PROXY` and their lowercase forms).
2. Propagates them to the **systemd user session** (`systemctl --user
   import-environment`) and the **D-Bus activation environment**
   (`dbus-update-activation-environment --systemd`), so newly launched
   processes pick the proxy up.
3. Optionally (settings checkbox) drives the **GNOME proxy stack via
   `gsettings`**, which lets browsers apply the proxy dynamically without a
   restart.

## Dynamic Browser Proxy
A cool feature that adds the seamlessness of GNOME's proxy handling to KDE! When toggled, any browser (both Chromium and Firefox-based ones) can inherit proxy settings without needing to quit and restart the entire browser session. 

### Prequisites
- `gsettings` must be installed on your system
- `XDG_CURRENT_DESKTOP=GNOME` environment variable must be set for the browser 

## Credits 
- Almost all of the credits go to [HimDek's Plasma Overview Widget](https://github.com/HimDek/Overview-Widget-for-Plasma) for serving as this project's template. 
