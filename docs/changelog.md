---
title: "CleanWRT changelog"
description: "What is new in each CleanWRT release for the Arcadyan AW1000."
---

# Changelog

## 25.12.5-R2.2-SP2 (this fork, not yet released)

- **Vantage is the new default theme**, with its Dashboard as the first page after login: an
  icon rail, a Ctrl+K command palette, light and dark modes. Footstrap stays in the image under
  *System → System → Language and Style*, and a router upgraded with its settings kept stays on the
  theme it had. See [Themes](theme.md).
- **The 5G LED shows 4G and 4G+ too.** Red for 4G, yellow for 4G+ (carrier aggregation),
  green for 5G NSA and blue for 5G SA, by default. Each colour can be changed under
  *System → LED Management → 5G LED*. See [Front-panel LEDs](leds.md).
- **Dark mode on more pages.** *Modem → 3gInfo-lite*, QModem's signal bars, the AWvoice phone page
  and the LED page's lamps now follow the theme's dark mode instead of showing white tiles and
  dark text on dark cards.
- **Even spacing on *Modem → 3gInfo-lite*.** The Neighbour cells card no longer touches the card
  above it, "Auto refresh" and "Auto scan" stay on one line, and the page's buttons, cards and
  gaps match the rest of the theme.
- **QModem's pages are laid out properly under Vantage.** On *Advance Modem Settings* the
  function tabs look and work like tabs, the card titles sit inside their cards, the *Submit*,
  *Select All* and *Scan* buttons no longer lie on top of the band list, and radio and checkbox
  labels are spaced. On *Dial Overview* the Modem Log's buttons have space between them, and the
  status card no longer touches the Save bar.
- **OpenVPN is no longer in the image**, and with it the *VPN* menu, where it was the only page.
  OpenVPN is one install away:
  `apk add openvpn-openssl luci-app-openvpn`, and a router upgraded with its settings kept gets its
  OpenVPN settings back when it is installed again. See [VPN and proxies](features/vpn-proxy.md#openvpn).
- **WireGuard is no longer in the image** (its kernel module, `wireguard-tools` and LuCI's WireGuard
  protocol), and with it the empty *Status → WireGuard* page. Tailscale is the VPN the image ships.
  WireGuard is one install away: `apk add kmod-wireguard wireguard-tools luci-proto-wireguard`.
  A router that runs a WireGuard tunnel gets it installed again by itself once it is online after
  the upgrade (below); until then that interface is down. See
  [VPN and proxies](features/vpn-proxy.md#wireguard).
- **SSH refuses root until a root password is set.** Stock OpenWrt lets anyone who reaches
  port 22 log in as root with no password while none is set; this image does not. Set the password
  in LuCI (it asks on the first login) and SSH works at once. Failsafe mode still opens a shell with
  no password, for recovery. If you only ever used SSH without a password, set one in LuCI first.
- **"Not secure" can go away for good.** The router's HTTPS certificate now names its LAN address
  and `cleanwrt.lan`, so trusting it once in your browser or computer ends the warning. A router
  upgraded with its settings kept keeps its old certificate: run `cw-https-cert` to make the new
  kind. See [Security](features/security.md#why-the-browser-says-not-secure).
- **WireGuard comes back by itself** on a router that ran a WireGuard tunnel: the first time it is
  online after the upgrade, it installs WireGuard again from the official repositories and brings
  the tunnel up.
- **Footstrap is no longer in the image.** Vantage is the one theme, so every page is made to look
  right once. A router that was on Footstrap moves to Vantage when upgraded, and Footstrap's leftover
  settings are removed. LuCI's Bootstrap stays as the fallback. See [Theme](theme.md).
- **Tailscale is in the image** (about 10 MiB), with its page under *Services → Tailscale*. It
  ships off: *Services → Tailscale → Enable and start*, then log in from the same page. A router that was
  logged in to Tailscale before the upgrade stays connected. See
  [Remote access](features/remote-access.md#tailscale).
- **Local builds finish clean.** A build on your own machine no longer ends with a release-key
  error: the key file is locked down to mode 600 by the build, and a key that is not the release
  key is a note there. Release builds stay strict. See [Building](building.md).
- **One command for a local build:** `tools/cw-build.sh` clones the tree if needed, builds in the
  background (from your shell or a root shell), shows a progress display, and ends with the image's
  path and sha256. See [Building](building.md#one-command).
- **A progress bar for local builds.** `tools/cw-build-progress.sh` follows the build log and shows
  the phase, the steps done, the package compiling now and the time left. The GitHub Actions
  build prints the same progress as lines in its log. See [Building](building.md#a-progress-bar).

## 25.12.5-R2.2-SP1

- **Upgrading from upstream with keep-settings.** The first boot deletes the leftover
  configuration of Passwall, Passwall 2, HomeProxy, AdGuard Home and Adblock, and Passwall's
  firewall includes, when those apps are not installed.
- **The fork's own signing key.** The image trusts this fork's package-signing key instead of
  upstream's.
- **Version label.** Fork builds are labelled `-SP<n>` after the upstream release they are based
  on, and the newer-version notice now compares the whole label. The stock comparison read only
  the OpenWrt base and `rc`, so `R2.1` and `R2.2` counted as the same version.
- **Nikki, with a dashboard.** Nikki runs the mihomo (Clash Meta) core from your own Clash YAML
  profile or subscription, under *Services → Nikki*. The Zashboard dashboard is preinstalled
  (about 1.5 MiB), so **Open Dashboard** works offline: switch proxies, test latency, watch
  connections, rules and logs. It ships off. First boot moves its HTTP proxy port from 8080, which
  the image already uses, to 7893, and replaces Nikki's six-digit dashboard secret and proxy
  password with random 32-character ones.
- **Passwall, Passwall 2, HomeProxy, AdGuard Home and Adblock are gone.** Their feeds, packages,
  cores (xray-core, sing-box, hysteria, naiveproxy, ipt2socks, microsocks, dns2socks and others)
  and first-boot files are no longer in the image; Nikki is the proxy app.
- **A smaller image: four apps are one install away.** Tailscale, Cloudflare Tunnel, Syncthing
  and qBittorrent (with its Qt6 stack) are no longer built in. Tailscale, Cloudflare and Syncthing
  install from the official OpenWrt repositories; qBittorrent and the Syncthing switch come from
  this project's own signed feed, `cw-opt`, which every router now lists. One line each, see
  [what is included](included.md#one-install-away). A keep-settings upgrade removes the apps from
  a router that had them, and keeps their settings for a reinstall.
- **A guide for the optional apps.** [Install optional apps](install-apps.md) walks through
  installing and setting up Tailscale, Cloudflare Tunnel, Syncthing, qBittorrent, AdGuard Home and
  the USB printer server, from *System → Software* or the command line.
- **AdGuard Home's and the printer server's settings survive a firmware upgrade.** They used to be
  deleted on the first boot of a new image; now a reinstall brings them back. While AdGuard Home
  is not installed, the first boot also puts DNS back on dnsmasq (port 53), so an upgrade never
  leaves the network without name lookups.
- **qBittorrent's web UI moves to port 8081.** Port 8080 belongs to the provisioning listener for
  network phones, so qBittorrent's page never opened there. A router upgraded with an older
  qBittorrent configuration is moved to 8081 too.
- **Night mode can switch off the Phone LED.** *System → LED Management → Night mode* lists
  **Phone** under *Keep on during night*; untick it and the phone lamp stays dark inside the night
  window while the phone keeps working. It is ticked by default, so nothing changes until you
  untick it.
- **The p910nd printer share is gone.** Install it with `apk add p910nd luci-app-p910nd` if you
  need it; a keep-settings upgrade removes its leftover config. The unused OHCI USB driver is gone
  too: this board has no OHCI controller.
- **The login page is centred.** The sign-in card sits in the middle of the screen instead of near
  the top.
- **Signed release images.** Every release image carries the project's signature, and the image
  holds the matching public key in `/etc/opkg/keys/`; every release also carries it as
  `key-build.pub`. OpenWrt 25.12 had silently stopped signing
  images built with the key in place; the build now makes the certificate it needs.
- **OpenClash is no longer built.** It was never in the image, only compiled for the optional
  `cw-opt` feed, which was never published. Nikki runs the same Clash profiles, so the OpenClash
  feed and its build step are gone, and with them the Ruby stack it pulled in.
- **This fork's own links.** The router's newer-version notice now reads this fork's version list,
  so it never offers an upstream image (which would bring back the removed apps and drop Nikki).
  The os-release home and bug links, releases and issues point at this fork too.
- **Smaller package set.** The iptables-era leftovers of the old proxies (`kmod-ipt-tproxy`,
  `ipset`, `ip6tables-nft`) are gone; the firewall is nftables throughout.
- **Faster builds.** The cross gdb, a debugger for the build host that never reached the image, is
  no longer built.

## 25.12.5-R2.2

The radio page, *Modem → 3gInfo-lite*, is rebuilt, and one collector now answers every card on it.

- **One page, no tabs.** Signal health, serving cells, network, neighbour cells, diagnostics and
  identity are cards down a single page. The summary at the top names the registration state, the
  operator, the mode — LTE, 5G NSA with its LTE anchor, or 5G SA — and whether carrier aggregation
  is active, with the age of the reading beside it.
- **Serving cells per carrier.** Each component carrier has its own card with band, EARFCN or NR
  ARFCN, PCI, RSRP, RSRQ and SINR, and the 5G leg of an EN-DC connection is shown beside its LTE
  anchor rather than replacing it. The neighbour table keeps its signal filter, search and sort,
  and says how old the scan is.
- **Five seconds by default.** The snapshot refresh and the neighbour scan both offer 5, 15 and 30
  seconds, 1 and 5 minutes, and start at five seconds. Neighbours scan themselves while the page is
  open; the manual *Scan now* button stays. The collector enforces the same floor, so a page left
  open cannot turn into a stream of AT commands.
- **A duration, and a last error.** The diagnostics card reports how long a collection took and what
  the last one failed with, so a page that stops updating says why instead of going quiet.
- **The theme draws the boxes.** The cards are the theme's own section container, so the wallpaper
  and glass modes, the dark scheme and any installed theme apply to them as they do everywhere else
  in LuCI.

Behind the page is `radiodata.sh`, one script behind a lock with a short cache. It reads QModem over
`ubus` when the daemon answers, falls back to the package's own `3ginfo.sh` when it does not, and
keeps the per-carrier `AT+QCAINFO` output as a table. The page presents what it returns and reads no
modem itself.

## 25.12.5-R2.1

The second stable release of the OpenWrt 25.12.5 base. The line is quieter, and the new-firmware
notice works from the first boot:

- **AWvoice 1.1.5** (R1 shipped 1.1.3). A refused call no longer leaves the line busy: the audio
  path stands by again instead of running for silence, which showed on the Health card and in the
  load average. The step before it made an idle line cost nothing, set a factory modem in PCM
  master mode to slave by itself, let a call go out on either voice domain, kept the page's send
  level under its ceiling, and put the serving cell and one signal line on the Health card.
- **the new-firmware notice is on out of the box.** Its answer is written by
  `files/etc/uci-defaults/52-cw-upgrade-check`; *Stop showing upgrade alerts* stays the way off.
- **that answer is written after the package's own defaults**, so a fresh flash keeps it and an
  answer you gave is not asked again.
- **the Attended Sysupgrade pages are out of the menu**, with the two pages under them.

## 25.12.5-R1

The first stable release of the OpenWrt 25.12.5 base. It carries everything `25.12.5-rc2.1`
shipped — AWvoice 1.1.3 with the LAN SIP side, the web phone, the code a phone scans and quiet
hours, Footstrap as the default look, Alpha and Argon alongside it, the phone bridge's working
defaults and the vendor VoIP engine kept off the boot path — and adds two changes:

- **the provenance bundle is verifiable**. `sha256sums.cw` names the bundle's files under
  `cw-release-provenance/`, while the release step packed them as `provenance/`, so the checksums
  could not be run against the bundle. The bundle now keeps the name the checksums use, and the
  build unpacks it again and verifies those lines before anything is uploaded.
- The LED Management picture in the documentation is the page as the released package draws it:
  the live status strip takes its surface from the active theme and the form is LuCI's own.

## 25.12.5-rc2.1

- **AWvoice 1.1.3** (rc2 shipped 1.1.2). The phone port gains its **SIP side**. A switch on the new
  SIP tab starts and stops the LAN SIP service this image now carries, so a soft phone on your own
  network rings and dials through the SIM's line beside the handset on the RJ11 port; the tab shows
  the accounts and passwords it uses and what it reports while a call is up. The page also carries a
  **web phone** - the handset's audio in the browser - and a **code a phone can scan**, which writes
  the account a soft phone fetches into a directory of its own. Wideband voice follows what the modem
  answers, the caller-id message and the ring supervision were corrected, and the front end now
  behaves the same in every mode. The same version also carries **quiet hours**: windows of the day
  that hold the handset, the answering machine and the network phones off a ringing call, contacts
  marked to ring through one, and the `*78`, `*79` and `#` codes on the handset and the page. The
  vendor's VoIP engine is kept off the boot path (`files/etc/uci-defaults/51-cw-awvoice-voipd-off`)
  so the phone daemon itself serves the SIP side.
- **Six patches to that SIP service.** Three complete the transaction the cellular side opens: the
  2xx ACK a UAC owes, the BYE from either side of a dialog with the in-dialog authentication an
  in-dialog BYE needs, and the CANCEL of an unanswered LAN INVITE with its 487 recognised. One makes
  the UCI section the record of the inbound credential, one sets the defaults the phone bridge needs,
  and one migrates a configuration that kept the VoIP engine's socket ([AWvoice](awvoice.md)).
- **The web interface is Footstrap**, an upstream Apache-2.0 LuCI theme pinned to one commit and
  changed by one line of it - the login page now carries the CleanWRT logo where the theme prints the
  router's hostname. The LuCI feed now carries a copy of this theme too, at an older commit and under
  the same package name; the image ships the pinned one, and the build says on every run which
  package it took out of the feed to do that. The theme that shipped before it is out of the image, with the five feed
  patches written for it - four that drew card-style status widgets and one that read a CPU counter.
  The stock Bootstrap theme stays as the fallback and Argon and Alpha ship beside it for comparison, with
  the one line of Argon's first-boot script that claimed the default removed - an installed theme is
  offered, not selected. Alpha keeps the Lua template layout it was written for, so its pages are the one
  thing in this image that may not render as intended on 25.12; choosing it changes nothing else.
  A new router starts at the look
  `files/etc/uci-defaults/50-cw-footstrap-look` writes, with the photo and the pattern that go with
  it ([theme](theme.md)).
- `files/etc/uci-defaults/49-cw-awvoice-provision-port` opens the plain HTTP listener that serves the
  scanned account file, on the LAN only, from a directory that holds nothing else.
- The QModem feed pin moves to the commit that first carries that SIP service.
- Terminal moves from the Tools menu to System, and Tools sits where its own order says.

## 25.12.5-rc2

- **AWvoice 1.1.2** (rc1 shipped 1.0.0). The phone port gains **call recordings**: a call you
  answer is kept as a stereo WAV, the caller and the handset on separate channels, played, saved
  or deleted from the call's card. Off by default, with a size budget that removes the oldest.
- **The answering machine**: after a delay you set, an unanswered call hears your greeting and
  leaves a message, played, saved or deleted from the call's card. Off until a greeting is on the
  router; picking up the handset takes the call over and keeps the part of the message already
  recorded.
- **Caller id**: the message goes out framed, from on-hook transmission between the ring bursts,
  and the handset shows the national number with the name from your phone book.
- An upgrade keeps the line: the module loads from the installed package and the daemon checks
  its interface before it drives the line, instead of running against whatever module the boot
  had loaded.
- The three AWvoice packages share one version, 1.1.2.

## 25.12.5-rc1

First release candidate.

- OpenWrt 25.12.5 base for the Arcadyan AW1000 (`qualcommax/ipq807x`, kernel 6.12.94).
- AWvoice: an ordinary desk phone on the RJ11 port makes and takes calls over the SIM, with caller
  id, call waiting, hold, three-way join (flash + 3), recall of a held call, call log, speed dial,
  call blocking, hotline and alarm calls.
- 5G stack: QModem, vendor QMI dialer, 3ginfo-lite with a registration fix for data-only SIMs,
  SMS, TTL, vnStat.
- A dark interface theme with dark and light mode, a sidebar and card-style status widgets.
- Front-panel LED daemon (power, Wi-Fi, 5G type, signal, internet) with a night mode.
- Proxy and VPN tools installed and disabled: Passwall, Passwall 2, HomeProxy, WireGuard,
  OpenVPN, Tailscale, Cloudflare Tunnel.
- Opt-in apps installed and disabled: file sharing, DLNA, printer server, Syncthing, AdGuard Home,
  qBittorrent, Adblock, Disk Manager.
- Built on GitHub Actions in a pinned Docker environment from pinned sources, with checksums
  and a provenance bundle.
