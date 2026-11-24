---
title: "Flash CleanWRT with your own settings"
description: "Set the hostname, LAN address, Wi-Fi names and password when you flash CleanWRT on the Arcadyan AW1000, without rebuilding the image. A reset still brings back the stock defaults."
updated: 2026-11-24
---

# Your own settings at flash time

The image ships the stock OpenWrt defaults: hostname `OpenWrt`, LAN `192.168.1.1`, and Wi-Fi
named `OpenWrt` with no password and the radios **off**. Those are the values a reset always
brings back, so anyone can reach a reset router the same way.

For your own router you can set your values in the same step as the flash. You don't rebuild
anything, and the signed image stays as it is. `tools/cw-settings-pack.sh` writes a small
settings archive, and the router applies it once on its next boot.

## What you can set

| option | sets | example |
|---|---|---|
| `--hostname NAME` | the router's name | `--hostname MyRouter` |
| `--lan-ip ADDR[/PREFIX]` | the LAN address (default prefix `/24`) | `--lan-ip 192.168.50.1` |
| `--ssid NAME` | the Wi-Fi name on every band | `--ssid MyWiFi` |
| `--ssid-2g`, `--ssid-5g`, `--ssid-6g` | the Wi-Fi name on one band, instead of `--ssid` there | `--ssid-2g MyWiFi-2.4G` |
| `--key PASSWORD` | the Wi-Fi password (WPA2, 8 to 63 characters); **turns Wi-Fi on** | `--key 'a strong one'` |
| `-o FILE` | where the archive goes (default `mysettings.tar.gz`) | `-o home.tar.gz` |

Every option is optional. Anything you leave out stays at the image default. A Wi-Fi name
without `--key` is refused: the tool never turns on an open network, because the root password
is not set yet on a freshly flashed router.

## 1. Make the archive

On a Linux or macOS computer, or WSL / Git Bash on Windows:

```sh
curl -fsSLO https://raw.githubusercontent.com/ShanelkaPramuditha/cleanwrt-aw1000-ng/main/tools/cw-settings-pack.sh
sh cw-settings-pack.sh --hostname MyRouter --lan-ip 192.168.50.1 \
    --ssid MyWiFi --key 'Str0ng-WiFi-pass' -o mysettings.tar.gz
```

From a clone of this repository it is `sh tools/cw-settings-pack.sh ...`. Put the password in
single quotes if it holds characters your shell would read, such as `$`, `!` or spaces.

!!! warning "The archive holds the Wi-Fi password in plain text"
    Keep it like a password, and delete it once the router is set up.

## 2. Flash with it

=== "From OpenWrt or CleanWRT (sysupgrade)"

    ```sh
    scp -O cleanwrt-*-sysupgrade.bin mysettings.tar.gz root@192.168.1.1:/tmp/
    ssh root@192.168.1.1 "sysupgrade -v -f /tmp/mysettings.tar.gz /tmp/cleanwrt-*-sysupgrade.bin"
    ```

    `-f` restores the archive as the router's settings during the flash. Don't add `-n`: it
    throws the settings away, and the archive with them. `-f` also takes the place of the settings
    the router would otherwise keep, so you get the image defaults plus your values, not your old
    configuration.

=== "After a first install (LuCI)"

    A first install from the stock firmware (see [Installation](installation.md)) can't take a
    settings file. Flash as usual, log in at `http://192.168.1.1` over Ethernet, then open
    *System → Backup / Flash Firmware → Restore backup*, upload `mysettings.tar.gz` and confirm.
    The router reboots and applies it.

After the reboot the router answers at the new LAN address, `192.168.50.1` in the example
above. Reconnect your computer (or renew its DHCP lease) to reach it.

## What happens on the router

The archive holds one script, `/etc/uci-defaults/zz-cw-my-settings`. On the next boot it runs
after the Wi-Fi configuration exists and after the image's own
[first-boot scripts](reference/uci-defaults.md) (`zz-` sorts last). Then the system deletes it,
as it does every first-boot script. To see what it will do, list or print it before you flash:

```sh
tar -xzOf mysettings.tar.gz etc/uci-defaults/zz-cw-my-settings
```

With `--key`, every Wi-Fi interface gets WPA2-PSK (WPA3 on a 6 GHz radio, which allows nothing
else), the password, and its radio turned on. The root password is still unset: LuCI asks for
one on the first login, as on any fresh flash (see [First boot](first-boot.md)).

## Back to the defaults

A reset removes your settings with everything else: *System → Backup / Flash Firmware → Perform
reset*, `firstboot && reboot`, or `sysupgrade -n`. The router comes back with the stock defaults
at `192.168.1.1`, and Wi-Fi is off. See [Recovery](recovery.md).
