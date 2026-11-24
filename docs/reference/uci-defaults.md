---
title: "CleanWRT first-boot defaults"
description: "Every first-boot script in the CleanWRT image: what it writes, the exact option and value, when it leaves your settings alone, and how to undo each one."
updated: 2026-11-06
---

# First-boot defaults

OpenWrt runs the scripts in `/etc/uci-defaults/` in name order on a clean boot. A script that exits
`0` is deleted, so it runs once; one that exits non-zero stays and is retried at the next boot.
This page is the complete list of what this image writes, and what it deliberately does not touch.

Everything here is in the repository under `files/etc/uci-defaults/`, so a router that has already
booted can be checked against the source.

!!! tip "These scripts run before you log in"
    The first boot is when the defaults below are written. A setting you change afterwards is not
    overwritten by a later `sysupgrade` that keeps settings — with the two exceptions noted in their
    rows.

## The image's own scripts

| script | what it writes | when it leaves things alone |
|---|---|---|
| `29-cw-keep-chosen-theme` | `luci.themes.Vantage=/luci-static/vantage`, written **before** Vantage's own `30_luci-theme-vantage`, which selects Vantage whenever its entry is new | only after an upgrade that kept the settings, when the base names an installed theme other than stock bootstrap (one you installed yourself, say): Vantage is added to the design list and the base stays. A fresh flash, the stock base or a base whose theme is gone is left to Vantage's script |
| `45-cw-strip-stock-leds` | removes the LuCI menu node `admin/system/leds` from `luci-mod-system.json` and deletes the stock `view/system/leds.js`, then clears the LuCI caches. The [LED Management](../leds.md) daemon owns those lamps | it writes the menu file back only if the System menu is still intact and the LEDs node really went; the `led` sections in `/etc/config/system` are **not** removed, nor the WAN port lamp |
| `46-cw-uhttpd-https` | `uhttpd.main.redirect_https='1'`, so plain HTTP becomes HTTPS; and, through `/usr/sbin/cw-https-cert`, a certificate that names the LAN address, the hostname and `<hostname>.lan`, so trusting it once ends the browser warning | exits quietly if `/etc/config/uhttpd` is missing; the certificate only when there is none yet, so an upgraded router keeps its own |
| `47-cw-awvoice-at-port` | deletes the `ubus-at-daemon` port section, which frees `/dev/ttyUSB2` for the [phone port](../awvoice.md). QModem keeps `ttyUSB3` | only if that config file exists. To undo: re-add the port section with its `at_port` set to `/dev/ttyUSB2` |
| `48-cw-strip-asu-ui` | removes every Attended Sysupgrade menu node — the package keys its pages as `admin/system/attendedsysupgrade/overview` and `…/configuration`, so the parent goes with them — and deletes their views, then clears the caches. `attendedsysupgrade-common` stays | it writes the menu back unless no key carries that path any more. The firmware-check preference those pages used to hold is written by `52-cw-upgrade-check`. See [releases](../releases.md#the-new-version-notice) for what the notice does |
| `49-cw-awvoice-provision-port` | adds a second uhttpd instance, `uhttpd.awvoice_provision`: `listen_http='0.0.0.0:8080'`, `home='/www/awvoice-provision'`, `redirect_https='0'`, `no_dirlists='1'`, `rfc1918_filter='1'`, and creates that directory. This is the plain-HTTP listener a [scanned provisioning code](../awvoice/network-phones.md#the-code-a-phone-scans) points a soft phone at | exits if `/etc/config/uhttpd` is missing. To undo: delete the section, remove the directory, restart uhttpd |
| `51-cw-awvoice-voipd-off` | stops the vendor VoIP engine `qmodem_voip` and takes it off the boot path, so the phone daemon can answer the front-end name itself and the [network phone](../awvoice/network-phones.md) carries audio | exits if the init script is not executable. It **fails** — and retries next boot — if any boot link for that engine survives other than the SIP service's own. This is the fix for a soft phone that registers and never sets up media |
| `52-cw-upgrade-check` | writes `attendedsysupgrade.client.login_check_for_upgrades='1'`, the answer to LuCI's firmware-check question, and **only where the option is absent**. LuCI asks that question on every load of *Status → Overview* until the option exists, and the page it names for a later change is the one `48-cw-strip-asu-ui` removes. See [releases](../releases.md#the-new-version-notice) | the number is part of the fix: the package's own `50-attendedsysupgrade` creates that config file, without the option, and uci-defaults run in name order — anything numbered below 50 is written into a file that does not exist yet and is then overwritten. A router whose owner answered the question keeps that answer, because the option is already there |
| `53-cw-qbittorrent-port` | sets `qbittorrent.config.http_port='8081'` where it is `8080`, so a qBittorrent configuration kept from an older router does not collide with the provisioning listener on 8080 | exits unless the option is exactly `8080`: any other port you chose stays |
| `54-cw-tailscale-off` | stops `tailscale` and takes it off the boot path, so it ships off; *Services → Tailscale → Enable and start* turns it on | a router already logged in (a non-empty `/etc/tailscale/tailscaled.state`) is left running |
| `55-cw-wireguard-restore` | leaves `/etc/cw-wireguard-restore` when a WireGuard interface is configured and WireGuard is not installed; `/etc/hotplug.d/iface/95-cw-wireguard-restore` then installs it from the official repositories the first time an interface comes up, brings the tunnels up and removes the marker | no WireGuard interface, or WireGuard installed: nothing |
| `95-cw-drop-removed-apps` | after a keep-settings upgrade from an image that carried them: deletes Footstrap's `/etc/config/footstrap` and `/etc/footstrap/` when the theme is gone; deletes `/etc/config/{passwall,passwall2,homeproxy,adblock}` and the `passwall*` firewall include sections. AdGuard Home's and p910nd's settings are **kept** (both are [optional installs](../install-apps.md)). While AdGuard Home is not installed, it also puts dnsmasq back on port 53 if its setup had moved it, so DNS keeps working after an upgrade | each app only when its init script is absent, so reinstalling one keeps its settings. Nothing to do on a router that never had them |
| `96-cw-apk-world-pin` | rewrites `/etc/apk/world` from the installed package database: every package that came from the LuCI feed, plus `base-files`, `kernel` and any `kmod-*`, is pinned to its exact version; everything else is written as a bare name and stays upgradable | it runs on **every** boot, so the pins always match the running image. The reason is recorded in the script: one `apk upgrade` once replaced patched LuCI packages with stock ones |
| `96-cw-default-theme` | `luci.themes.Vantage=/luci-static/vantage` and `luci.main.mediaurlbase=/luci-static/vantage`; removes every `luci.themes` entry whose directory the image does not carry; deletes a dead marker section an older image left | the base is set only if `/www/luci-static/vantage` exists **and** the current base is empty, still the stock bootstrap, or names a directory that no longer exists. A theme you chose that is still installed stays, and so does its entry in the design selector |
| `97-cw-net-tuning` | `network.globals.packet_steering='1'`, spreading receive and transmit work over the four cores | unconditional |
| `98-cw-modem-fix` | `/etc/init.d/cw-modem-fix enable`, which puts the modem registration fix on the boot path | unconditional. See [the 5G modem](../modem.md) |
| `99_zz-cw-nikki-defaults` | Nikki: `nikki.mixin.http_port` from `8080` (taken by the provisioning listener) to `7893`; `nikki.mixin.api_secret` and the proxy password from Nikki's six-digit number to 32 random hex characters | runs once (`nikki.config.cw_defaults`), after Nikki's own `99_init_nikki` — hence the `99_` name, since `-` sorts before `_`. A port or secret you changed is left alone |
| `99-aw1000-defaults` | `system.@system[0].timezone='UTC'`, `.log_size='64'`; `dropbear` password authentication and root password authentication `on` | hostname, Wi-Fi (SSID, key, encryption, radio state) and Ethernet port names are **deliberately left at the OpenWrt device defaults**, so a reset brings the router back to them. The regulatory domain is deliberately not hardcoded — it follows the network the modem registers on. The root password is left unset on purpose. |

## Scripts that arrive with packages

Two more first-boot scripts matter to this image even though they belong to other packages:

| script | where it comes from | what it does |
|---|---|---|
| `90-cw-led` | [`luci-app-cw-led`](https://github.com/Pr0Luci/luci-app-cw-led) | removes from `/etc/config/system` every `led` section whose sysfs node is one the LED daemon owns (`blue:5g`, `green:5g`, `red:5g`, `blue:signal`, `green:signal`, `red:signal`, `green:internet`), reseeds the daemon's own `global` section only if it is missing, enables the service and reloads rpcd. `green:power`, `green:wifi` and the WAN lamp keep their kernel triggers |
| `89-qmodem-sip-migrate`, `90-qmodem-sip-firewall`, `91-qmodem-sip-voip-off` | the QModem feed's SIP service, the last one added by this build's patch `patches/feeds/qmodem/0009-sip-voip-default-migration.patch` | migrate a configuration that still pointed at the vendor engine, add the service's firewall include, and set both directions' `voip_enabled` to `0` **only when** the media socket path is the phone daemon's — which is how an upgrade from an older image ends up with working audio |

## What the image ships as configuration

The scripts above change things; these files are simply there from the start. Full option lists are
in [UCI options](options.md).

| file | state on a new router |
|---|---|
| `fstab` | USB drives are auto-mounted under `/mnt`; no anonymous swap, no filesystem check at boot |
| `irqbalance` | enabled |
| `minidlna` | `enabled='0'`; when on, port 8200 on the LAN, media from `/mnt`, name `CleanWRT` |
| `qmodem_ttl` | **enabled**, TTL of forwarded packets rewritten to `64` |
| `samba4` | the daemon starts, with one share (`USB` → `/mnt`, writable) and `guest_ok='no'`, so nothing is reachable until you add users |
| `syncthing` | `enabled='0'`; when on, its own interface on `0.0.0.0:8384` and its config in `/etc/syncthing`. The app is not in the image: the file waits for an [install](../install-apps.md#syncthing), which keeps it |
| `qbittorrent` | `enabled='0'`, `download_dir='/mnt/download'`, `http_port='8081'` (8080 is the provisioning listener's). The app is not in the image: the file waits for an [install](../install-apps.md#qbittorrent), which keeps it |
| `watchcat` | **comment lines only, no sections.** The package default is an active "ping, reboot after 6 failures" rule; this file replaces it so the router never reboots itself unless you add a rule |
| `cw-led`, `awvoice`, `qmodem_sip` | shipped by their own packages, not here, so an upgrade keeps what you changed |

## Reading it on your router

Nothing here is hidden. On a flashed router:

```sh
ls /etc/uci-defaults/          # what is still waiting to run
logread -e cw-firstboot        # what the image's own scripts said
uci show awvoice               # the line, the network side, the quiet-hours windows
```

A script that already ran is gone from that directory, which is why the log and the config — not
the leftovers — are the evidence of what happened.
