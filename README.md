# Proxy Toggle for Plasma 
An ultra-simple Plasma widget that allows you to toggle proxy with a simple click. You can easily configure the host and ports inside the widget settings window. 

<img height="150" alt="image" src="https://github.com/user-attachments/assets/90e28c98-fa4b-4ab9-b19a-a5f505eb65fa" />
<img height="150" alt="image" src="https://github.com/user-attachments/assets/685cb89f-29c3-4296-816c-692555feab48" />
<img height="500" alt="image" src="https://github.com/user-attachments/assets/a6baa05d-2aec-4b27-9cbd-22272cf64279" />

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

[Demo.webm](https://github.com/user-attachments/assets/c357ce95-0f7f-479f-ad52-f7e03873185c)

> ***Note**: This is a simple HTML file that detects ip address changes in ifconfig.me. It turns green for ipv4 (my proxy) and red for ipv6 (my home ip address). Thus it acts as a demo that dynamic proxy is working! Also this is the Flatpak version of Brave.* 

A cool feature that adds the seamlessness of GNOME's proxy handling to KDE! When toggled, any browser (both Chromium and Firefox-based ones) can inherit proxy settings without needing to quit and restart the entire browser session.

### Prequisites
- `gsettings` must be installed on your system
- Set the `XDG_CURRENT_DESKTOP=GNOME` environment variable for your browser

**For flatpak browsers**

> ***NOTE**: This setup is not needed for browsers like Brave and Chrome because it already ships with the necessary defaults. Therefore, check whether everything is working with your broswser first and only proceed if it does not.*

Replace `your.browser.folder` and `your.browser.name` appropriately:
- Download [libdconfsettings.so](https://github.com/n3thshan/proKc/blob/main/libdconfsettings.so) and copy it to `~/.var/app/your.browser.folder/data/gio/modules/` (make these folders if not present)
- Copy and run the following command:
```
flatpak override --user \
  --filesystem=xdg-run/dconf \
  --filesystem=~/.config/dconf:ro \
  --talk-name=ca.desrt.dconf \
  --env=GSETTINGS_BACKEND=dconf \
  --env=DCONF_USER_CONFIG_DIR=.config/dconf \
  --env=GIO_EXTRA_MODULES=$HOME/.var/app/your.browser.folder/data/gio/modules \
  your.browser.name
```

## Credits 
- Almost all of the credits go to [HimDek's Plasma Overview Widget](https://github.com/HimDek/Overview-Widget-for-Plasma) for serving as this project's template. 
