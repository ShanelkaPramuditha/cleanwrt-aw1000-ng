---
title: "Flash CleanWRT with your own settings"
description: "Set the hostname, LAN address, Wi-Fi names and password when you flash CleanWRT on the Arcadyan AW1000, without rebuilding the image. A reset still brings back the stock defaults."
updated: 2026-11-24
---

# Your own settings at flash time

The image ships the stock OpenWrt defaults, hostname `OpenWrt` and LAN `192.168.1.1`, and Wi-Fi
**on**, named `OpenWrt`, with the password `password123`. Those are the values a reset brings
back, so anyone can reach a reset router the same way.

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
| `--key PASSWORD` | the Wi-Fi password (WPA2, 8 to 63 characters), in place of `password123` | `--key 'a strong one'` |
| `-o FILE` | where the archive goes (default `mysettings.tar.gz`) | `-o home.tar.gz` |

Every option is optional. Anything you leave out stays at the image default. A Wi-Fi name
without `--key` only renames the networks: they keep the password they have (`password123` on
a fresh flash). The tool never makes a network open.

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
else), your password in place of `password123`, and its radio on. Without it, only the names
change. The root password is still unset: LuCI asks for
one on the first login, as on any fresh flash (see [First boot](first-boot.md)).

## Build them into your own image

If you build the image yourself, `tools/cw-build.sh` asks for these values before the build
starts. Press Enter to keep the value in brackets. If you change nothing, you get the stock
image.

```
  The router's defaults (built into the image; a reset brings them back)
  Enter keeps the value in brackets.
  Hostname [OpenWrt]: MyRouter
  LAN address (e.g. 192.168.50.1 or 192.168.50.1/24) [192.168.1.1]: 192.168.50.1
  Wi-Fi name, 2.4 GHz [OpenWrt]: MyWiFi
  Wi-Fi name, 5 GHz [OpenWrt]: MyWiFi-5G
  Wi-Fi password [Enter keeps the stock password123]:
  Again, to confirm:
```

The password is not shown while you type it. Press Enter there to keep `password123`. The values are checked by the same rules as `cw-settings-pack.sh`, and a wrong
one is asked again.

These are not a one-time setting like the archive. They become the **image's own defaults**:
the router starts with them, and a reset brings them back instead of the stock values.

The next build offers your last answers again (*Use these again? [Y]es, [c]hange, stock
[d]efaults*). They are kept in `.cw-build-settings` next to the repository, readable only by
you, because they include the Wi-Fi password.

| to | run |
|---|---|
| build the stock image without questions | `tools/cw-build.sh --defaults` |
| reuse the last answers without questions | `tools/cw-build.sh --same` |
| give the values without questions, for example in a script | `CW_HOSTNAME=MyRouter CW_LAN_IP=192.168.50.1 CW_SSID=MyWiFi CW_WIFI_KEY='Str0ng-WiFi-pass' tools/cw-build.sh` (also `CW_SSID_2G`, `CW_SSID_5G`) |

Without a terminal, for example when the output goes to a pipe, nothing is asked and the stock
image is built (or the `CW_*` values, or `--same`).

With Docker, or when you run `tools/cw-release-build.sh` directly, make the script with
`sh tools/cw-settings-pack.sh ... --script mysettings.sh` and pass it as
`CW_LOCAL_SETTINGS=/path/to/mysettings.sh` (inside the container, for example
`-e CW_LOCAL_SETTINGS=/cleanwrt/mysettings.sh`).

!!! warning "An image built with your own Wi-Fi password holds it"
    Anyone with the image file can read it. Keep the image to yourself, and use the stock image
    or the settings archive for anything you share. The build's `provenance.txt` notes that own
    defaults are built in, without the values. Release builds refuse them.

## On GitHub Actions

The `build` workflow takes the same values, if you build on GitHub (see
[Build from source](building.md#on-github-actions)).

1. Only if you want a Wi-Fi password other than `password123`: add it as a repository secret named
   `CW_WIFI_KEY` (*Settings → Secrets and variables → Actions → New repository secret*). It is a
   secret and not a box in the form, because anyone who can see the repository's Actions runs
   can read what was typed into the form.
2. *Actions → build → Run workflow*, then fill in the boxes you want. Leave the others empty for
   the stock values.

    | box | sets |
    |---|---|
    | Own settings - hostname | the router's name |
    | Own settings - LAN address | the LAN address |
    | Own settings - Wi-Fi name | the Wi-Fi name on both bands |
    | Own settings - 5 GHz Wi-Fi name | the 5 GHz name, when it differs |
    | Own settings - Wi-Fi password from CW_WIFI_KEY | the `CW_WIFI_KEY` password in place of `password123` |

3. The values are checked before the build starts, so a mistake costs a minute, not two hours.
   The run's summary lists what was built in (without the password).
4. The images go to a private draft release named `own-v<version>`, which only the
   repository's collaborators can see. Download the `*-squashfs-sysupgrade.bin` from there. A
   later build with own settings replaces that draft's files.

Such an image is never published: it doesn't go into the release draft, and the `release`
workflow refuses any draft built with own settings. The hostname, LAN address and Wi-Fi names
are visible in the run to anyone who can see the repository's Actions; only the password stays
secret.

## Back to the defaults

If you flashed with the settings archive, a reset removes your settings with everything else: *System → Backup / Flash Firmware → Perform
reset*, `firstboot && reboot`, or `sysupgrade -n`. The router comes back with the stock defaults
at `192.168.1.1`, and Wi-Fi `OpenWrt` with the password `password123`. See [Recovery](recovery.md). An image you built with your
own values comes back with those values instead; flash the stock image to get the stock ones.
