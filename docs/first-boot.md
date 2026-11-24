---
title: "CleanWRT first boot and setup on the AW1000"
description: "The first login, default Wi-Fi and password, HTTPS, time zone and a short tour of LuCI after you flash CleanWRT on the Arcadyan AW1000."
updated: 2026-11-06
---

# First boot

CleanWRT follows the stock OpenWrt first-login model.

## Defaults

| | |
|---|---|
| Address | `192.168.1.1` |
| Hostname | `OpenWrt` (stock, not changed by this image) |
| Root password | **none** (set it on first login) |
| Wi-Fi | **on**: SSID `OpenWrt` on both bands, WPA2, password `password123` (`56-cw-wifi-default-key`). Change the password on the first login |
| Ethernet ports | stock names: `lan1`–`lan4`, `wan` |
| Time zone | UTC (set yours in LuCI) |
| Admin UI | LuCI over HTTPS (self-signed certificate) |
| The phone line | **on**. `awvoice.main.enabled` ships as `1`, so a desk phone works the first time you plug one in |
| The network phone (SIP) side | **off**. No SIP port is open and no SIP process runs until the AWvoice page's switch starts it |
| The front-panel LED daemon | on |
| The TTL rewrite for tethering | on, at 64 |
| Opt-in apps | installed and off, with one exception: the Samba daemon starts, but its share allows no guest access, so nothing is reachable until you add users |

!!! warning "Set a password on the first login"
    With no root password anyone on the LAN can log in, and the LAN includes the Wi-Fi, whose
    password `password123` is printed in this documentation. Set a root password and change the
    Wi-Fi password (*Network → Wireless → Edit → Wireless Security*) on the first login, before
    the router is anywhere strangers are in range.

## Steps

1. Connect a computer to a LAN port with **Ethernet**. Do not use Wi-Fi for the first login.
2. Open `http://192.168.1.1`. The browser is moved to HTTPS and shows a certificate warning.
   That is expected, see [Security](features/security.md#why-the-browser-says-not-secure).
3. LuCI asks you to set a root password. Set a strong one. It applies to LuCI and SSH.
4. Set a Wi-Fi key, then enable Wi-Fi: *Network → Wireless*, edit each interface, *Wireless Security*.

    ```sh
    for i in 0 1; do
      uci set wireless.default_radio$i.encryption='psk2'
      uci set wireless.default_radio$i.key='your-strong-key'
      uci set wireless.default_radio$i.disabled='0'
      uci set wireless.radio$i.disabled='0'
    done
    uci commit wireless && wifi reload
    ```

5. Set your time zone: *System → System → General Settings*.
6. Open *Modem* and check that the 5G modem registered. See [The 5G modem](modem.md).

The root password is set under *System → Administration*:

[![Router Password page](assets/img/password-dark.jpg)](assets/img/password-dark.jpg)

Upgrades with *keep settings* never overwrite a key you have set yourself.

The login page, in dark and light mode:

| Dark | Light |
|---|---|
| ![Login, dark](assets/img/login-dark.jpg) | ![Login, light](assets/img/login-light.jpg) |

!!! tip "Set it all at flash time instead"
    To flash with your own hostname, LAN address, Wi-Fi names and password already set, see
    [Your own settings at flash time](custom-settings.md). A reset still brings back the
    defaults above.

## A short tour of LuCI

| Menu | What is there |
|---|---|
| Status | overview widgets (system, modem, memory, storage), logs, traffic |
| System | administration, mount points, **LED Management**, theme |
| Services | Nikki, Tailscale, miniDLNA, Disk Manager (and Cloudflare Tunnel, Syncthing or qBittorrent once you install them) |
| Network | interfaces, wireless, firewall, SQM, file sharing |
| Modem | QModem, 3gInfo-lite, SMS, TTL |
| Services → AWvoice(RJ11) | [AWvoice](awvoice.md): the phone port |
| Tools | file manager, bandwidth monitor, watchcat, terminal |

## Turning on an app

Every opt-in app has the same single switch: open its LuCI page, tick **Enable**, press
**Save & Apply**. Set any passwords the app needs *before* you enable it. See
[What is included](included.md).

## What the image did before you got here

Thirteen first-boot scripts wrote the defaults above — the time zone, the
HTTPS redirect, the theme's look, the LED ownership, the AT port handed to the phone service, the
vendor VoIP engine taken off the boot path, and the package pins that keep `apk upgrade` from
replacing patched LuCI packages. All of it, script by script and option by option, is in
[first-boot defaults](reference/uci-defaults.md).
