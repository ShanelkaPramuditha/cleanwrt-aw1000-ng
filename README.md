<p align="center">
  <img src="docs/assets/img/banner.svg" alt="CleanWRT for the Arcadyan AW1000" width="100%">
</p>

<p align="center">
  <a href="https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/"><img alt="Documentation" src="https://img.shields.io/badge/docs-online-14b8a6?style=for-the-badge"></a>
  <a href="https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng/releases"><img alt="Version" src="https://img.shields.io/badge/CleanWRT-25.12.5--R2.2--SP1-14b8a6?style=for-the-badge"></a>
  <a href="LICENSE"><img alt="Licence" src="https://img.shields.io/github/license/ShanelkaPramuditha/cleanwrt-aw1000-ng?style=for-the-badge&color=14b8a6"></a>
  <a href="https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng/actions/workflows/check.yml"><img alt="Checks" src="https://img.shields.io/github/actions/workflow/status/ShanelkaPramuditha/cleanwrt-aw1000-ng/check.yml?style=for-the-badge&label=checks"></a>
</p>

# CleanWRT: OpenWrt for the Arcadyan AW1000

> [!NOTE]
> **This is a fork.** CleanWRT was created and is maintained by
> [Pr0Luci](https://github.com/Pr0Luci) at
> [Pr0Luci/cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000). This fork,
> [ShanelkaPramuditha/cleanwrt-aw1000-ng](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng),
> follows upstream and adds a few changes of its own, listed under
> [Changes in this fork](#changes-in-this-fork). The fork is not affiliated with or endorsed by
> the upstream project.
>
> The documentation, release and issue links below are this fork's own and describe this fork's
> build. Report problems with an image built from this fork in
> [this fork's issues](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng/issues), not upstream.

CleanWRT is an independent build of **OpenWrt 25.12.5** for the **Arcadyan AW1000** 5G router
(Qualcomm IPQ8072, Quectel RG500Q-EA modem). It is made for people who want the router to simply
work: a phone on the RJ11 socket, a 5G modem that dials and recovers by itself, a modern interface,
and the usual power tools, all switched off until you ask for them.

The whole image is built in the open on GitHub from pinned sources, and every release comes with
checksums and a provenance bundle.

> CleanWRT is *Powered by OpenWrt* and is not affiliated with or endorsed by the OpenWrt project.
> OpenWrt® is a registered trademark of Software Freedom Conservancy (SFC) - https://openwrt.org

<p align="center">
  <a href="docs/assets/img/overview-dark.jpg"><img src="docs/assets/img/overview-dark.jpg" alt="The Status overview of CleanWRT in dark mode" width="92%"></a>
</p>

## Highlights

| | |
|---|---|
| **AWvoice, a phone on the router** | Plug an ordinary desk phone into the RJ11 socket and make and take calls over your SIM. Caller id, call waiting, hold, a three-way join, recall of a held call, a call log, call recordings, an answering machine, speed dial, call blocking and alarm calls. No extra box, no PBX, no SIP account. |
| **5G that just works** | QModem, auto-dial and auto-recovery, dual-stack IPv4/IPv6, SMS, TTL control, per-interface data usage, and a registration fix for data-only SIMs. |
| **A modern interface** | Vantage: a console-style theme with an icon rail, breadcrumbs, page tabs, a Ctrl+K command palette, light and dark modes, and a live Dashboard as the first page. Footstrap stays one click away. |
| **LEDs that mean something** | The 5G LED shows 4G, 4G+, NSA or SA in colours you choose, the signal LED shows quality, the internet LED runs a real connectivity check, and night mode switches them off at bedtime. |
| **Tools, but off by default** | Nikki (mihomo with your Clash profiles and a dashboard), WireGuard, Tailscale, DLNA and file sharing in the image; Cloudflare Tunnel, Syncthing and qBittorrent one `apk add` away. Nothing listens until you tick **Enable**. |
| **Careful defaults** | HTTPS for the admin UI, no hidden remote access, BBR congestion control, pinned LuCI so an `apk upgrade` cannot undo the build. |
| **Verifiable builds** | Built on GitHub Actions in a pinned Docker environment from commits you can read, with checksums and a provenance bundle for each release. |

## Screenshots

<table>
  <tr>
    <td align="center" width="50%"><a href="docs/assets/img/leds-dark-status.jpg"><img src="docs/assets/img/leds-dark-status.jpg" alt="LED Management with the live status card"></a><br><sub>LED Management: live state of the panel LEDs</sub></td>
    <td align="center" width="50%"><a href="docs/assets/img/overview-light.jpg"><img src="docs/assets/img/overview-light.jpg" alt="The Status overview in light mode"></a><br><sub>Light mode follows your system, or the toggle</sub></td>
  </tr>
  <tr>
    <td align="center"><a href="docs/assets/img/login-dark.jpg"><img src="docs/assets/img/login-dark.jpg" alt="The login page"></a><br><sub>The login page</sub></td>
    <td align="center"><a href="docs/assets/img/overview-mobile.jpg"><img src="docs/assets/img/overview-mobile.jpg" alt="The Status overview on a phone" width="34%"></a><br><sub>Made to be used from a phone</sub></td>
  </tr>
</table>

<sub>The screenshots come from a development preview of the interface with a simulated modem. Values such as the kernel, memory and storage differ on a real router.</sub>

## Before you flash

> [!CAUTION]
> **Supported hardware: the Arcadyan AW1000 only, with the expanded flash layout.** The image does
> not fit the stock layout, and flashing it there can leave the router unbootable. Check first:
>
> ```sh
> cat /proc/mtd
> ```
>
> The `rootfs` partition must be **at least `0x08000000`** (128 MiB). If it shows up as `rootfs_bak`
> instead, stop. Read the [MTD layout page](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/mtd-layout/).

> [!IMPORTANT]
> The very first install from the stock firmware needs a **serial console (UART)** and a TFTP
> server. Read [Installation](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/installation/) and
> [Recovery](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/recovery/) before you start.

## Quick install

If the router already runs OpenWrt, and `cat /proc/mtd` is fine:

1. Download the `*-squashfs-sysupgrade.bin` from the
   [Releases page](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng/releases) and check it:

   ```sh
   sha256sum -c sha256sums.cw --ignore-missing
   ```

2. Copy it to the router:

   ```sh
   scp cleanwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/
   ```

3. Flash it. Use `-n` (a clean install) when you come from another firmware, because the theme and
   some settings change names:

   ```sh
   ssh root@192.168.1.1 "sysupgrade -n -v /tmp/cleanwrt-*-sysupgrade.bin"
   ```

## First boot

| | |
|---|---|
| Address | `http://192.168.1.1` (over Ethernet) |
| Root password | none: LuCI asks you to set one |
| Wi-Fi | `CleanWRT-5G`, `CleanWRT-2.4G`, WPA2-PSK, default key `CleanWRT#40` |
| Hostname, time zone | `CleanWRT`, UTC |

> [!WARNING]
> Change the root password and the Wi-Fi key on the first login.

## Documentation

Everything is on the documentation site: **https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/**

| Page | What is in it |
|---|---|
| [Installation](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/installation/) | UART + TFTP for the first install, `sysupgrade` afterwards |
| [MTD layout](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/mtd-layout/) | what must fit, and how to check your router |
| [Recovery](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/recovery/) | failsafe, bootloader recovery, the way back |
| [AWvoice](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/awvoice/) | the phone port, flash codes, safety |
| [The 5G modem](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/modem/) | QModem, signal, SMS, TTL, modem firmware |
| [Front-panel LEDs](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/leds/) | what every LED shows, night mode, settings |
| [What is included](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/included/) | every app, where to find it, its default state |
| [Build from source](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/building/) | GitHub Actions, Docker, pins, signing |
| [FAQ](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/faq/) | known limits and common questions |

## How it is built

The repository holds only build configuration, patches and the rootfs overlay. The build runs on
GitHub Actions inside a pinned Docker image, applies the overlay and the patches to a clean OpenWrt
`v25.12.5` tree, and **fails** rather than ship something stale: every feed and every package is
pinned to a commit, a patch that no longer applies stops the build, and the image must fit the
flash layout.

```sh
git clone --depth 1 --branch v25.12.5 https://github.com/openwrt/openwrt.git openwrt
docker build -t cleanwrt-builder docker/
docker run --rm -v "$PWD/openwrt":/build -v "$PWD":/cleanwrt \
  cleanwrt-builder /cleanwrt/tools/cw-release-build.sh /build --clean
```

`CW_CHECK_ONLY=1` runs every check and stops before compiling. See the
[build page](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/building/) for signing and the optional
package feed.

## The parts

| Repository | What it is |
|---|---|
| [cleanwrt-aw1000](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng) | this repository (fork of [upstream](https://github.com/Pr0Luci/cleanwrt-aw1000)): configuration, patches, overlay, workflows, documentation |
| [AWvoice](https://github.com/Pr0Luci/openwrt-aw1000-voice-awvoice) | the phone port: kernel module, daemon and LuCI page |
| [luci-app-cw-led](https://github.com/Pr0Luci/luci-app-cw-led) | the front-panel LED daemon and its page |
| [luci-theme-vantage](https://github.com/anothaDev/luci-theme-vantage) | the web interface: the theme the image selects, and its Dashboard |
| [luci-theme-footstrap](https://github.com/VizzleTF/luci-theme-footstrap) | the previous default theme, still selectable |

## Help and contributions

- A bug or a question: open an [issue](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000-ng/issues) and fill in
  the form. Please never paste passwords, keys or full IMEI/IMSI numbers.
- A fix or an improvement: open a pull request. `main` is protected, the checks must pass, and
  changes are squash-merged. See [Contributing](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/contributing/).
- A mistake in the docs: every page has an *Edit this page* button.

## Changes in this fork

| Change | Files |
|---|---|
| A VS Code dev container and the `cw-dev` front end for local builds | `.devcontainer/`, `.vscode/tasks.json` |
| `--clean` / `--dirclean` are skipped on a fresh tree with no `.config`, where OpenWrt would otherwise open an interactive menuconfig and fail in CI | `tools/cw-release-build.sh` |
| Faster builds: the cross gdb (never in the image) is no longer built, and CI falls back to the last download and compiler cache of the same OpenWrt tag when the seed or feed pins change | `configs/arcadyan_aw1000.seed`, `.github/workflows/build.yml` |
| Passwall, Passwall 2, AdGuard Home and Adblock removed: their feeds, packages, vendored LuCI app, first-boot files, patch and docs | `feeds.conf.default`, `configs/`, `feeds-src/cwfeed/`, `files/`, `patches/feeds/`, `tools/`, `docs/` |
| Nikki (mihomo) added, with the Zashboard dashboard preinstalled: use Clash YAML profiles or subscriptions, manage proxies from the dashboard. First boot moves its HTTP port off 8080 and sets random secrets | `feeds.conf.default`, `configs/arcadyan_aw1000.seed`, `feeds-src/cwfeed/net/nikki-zashboard/`, `files/etc/uci-defaults/99_zz-cw-nikki-defaults`, `tools/cw-release-build.sh`, `docs/` |
| HomeProxy removed (its pin, sing-box and ucode-mod-digest): Nikki is the one proxy app | `configs/arcadyan_aw1000.seed`, `configs/local-packages.pin`, `tools/cw-release-build.sh`, `docs/` |
| Leftover iptables-era packages removed (`kmod-ipt-tproxy`, `ipset`, `ip6tables-nft`, `kmod-ip6tables`) and the duplicate `wget` line (the build already uses `uclient-fetch`) | `configs/arcadyan_aw1000.seed` |
| The fork's own links: os-release home and bug URLs, the newer-version notice and its version feed, the docs site, releases, issues, badges and the optional cw-opt feed point at this fork; site commits use the GitHub Actions bot identity | `configs/`, `tools/`, `files/`, `patches/feeds/luci/0007-upgrade-check-cdn-no-asu.patch`, `mkdocs.yml`, `.github/ISSUE_TEMPLATE/`, `docs/`, `feeds*` |
| The `-SP<n>` label moves to the next number by itself when a release is published, and a draft needs changelog entries | `tools/cw-bump-version.sh`, `tools/tests/cw-bump-version-test.sh`, `.github/workflows/release.yml`, `.github/workflows/build.yml`, `docs/fork-maintenance.md` |
| Version label `-SP<n>` (first: `25.12.5-R2.2-SP1`), and the upgrade notice compares the whole label | `tools/cw-release-build.sh`, `configs/arcadyan_aw1000.seed`, `patches/feeds/luci/0007-upgrade-check-cdn-no-asu.patch` |
| The fork's own apk feed signing key (the image trusts it instead of upstream's) | `files/etc/apk/keys/public-key.pem` |
| Leftover configs of the removed apps cleaned up on a keep-settings upgrade | `files/etc/uci-defaults/95-cw-drop-removed-apps` |
| CI caches the host tools, the cross toolchain and Go's build cache between runs | `.github/workflows/build.yml` |
| A page for maintaining the fork | `docs/fork-maintenance.md`, `mkdocs.yml` |
| Vantage is the default theme, with its Dashboard; Footstrap stays selectable, and a router upgraded with its settings kept stays on the theme it had | `configs/local-packages.pin`, `configs/arcadyan_aw1000.seed`, `tools/cw-release-build.sh`, `files/etc/uci-defaults/29-cw-keep-chosen-theme`, `files/etc/uci-defaults/96-cw-default-theme`, `tools/tests/`, `docs/` |
| Pages written for the stock themes follow Vantage's dark mode (3gInfo-lite, QModem, AWvoice), and the LED page's lamps follow the theme's switch | `patches/packages/luci-theme-vantage/0001-export-tier-for-stock-theme-pages.patch`, `patches/packages/luci-app-cw-led/0002-lamp-colours-follow-the-theme-switch.patch` |
| The 5G LED shows 4G (red) and 4G+ (yellow) as well as 5G NSA and SA, with the colours chosen on the LED page | `patches/packages/luci-app-cw-led/0003-fiveg-lamp-colours-for-4g-and-4g-plus.patch`, `docs/leds.md` |
| The 3gInfo-lite radio page takes its spacing from the theme, and QModem's buttons no longer touch | `patches/feeds/3ginfo/0006-radio-spacing-follows-the-theme.patch`, `patches/feeds/qmodem/0011-luci-button-spacing.patch` |
| OpenVPN removed, and with it the VPN menu (one `apk add` away) | `configs/arcadyan_aw1000.seed`, `docs/` |
| Tailscale in the image, shipped off; a router logged in already stays connected across an upgrade | `configs/arcadyan_aw1000.seed`, `tools/cw-release-build.sh`, `files/etc/uci-defaults/54-cw-tailscale-off`, `tools/tests/cw-tailscale-off-test.sh`, `docs/` |
| The login card is centred on the screen | `patches/packages/luci-theme-footstrap/0002-login-card-centred-in-the-viewport.patch` |
| OpenClash no longer built for the optional feed (Nikki runs the same Clash profiles) | `feeds.conf.default`, `tools/`, `files/etc/`, `.devcontainer/cw-dev.sh`, `docs/` |
| A missing or partly deleted OpenWrt tree stops the build in seconds instead of failing hours later | `tools/cw-release-build.sh` |
| Images are signed again: on OpenWrt 25.12 the build makes the signing certificate itself | `tools/cw-release-build.sh`, `tools/cw-sign-keys.sh` |
| Night mode can switch off the Phone LED (a memory-only hold in the phone service, asked for by the LED app) | `patches/packages/awvoice-phoned/`, `patches/packages/luci-app-cw-led/` |
| The p910nd printer share and the unused OHCI USB driver removed | `configs/arcadyan_aw1000.seed`, `files/`, `patches/feeds/luci/`, `docs/` |
| Every release carries the image signing public key | `.github/workflows/` |
| A smaller image: Tailscale, Cloudflare Tunnel, Syncthing and qBittorrent are one `apk add` away; the project's signed cw-opt feed (qBittorrent, the Syncthing switch) is published by a new `feed` workflow and listed on every router | `configs/`, `tools/`, `files/etc/`, `.github/workflows/`, `docs/` |
| A step-by-step guide to installing the optional apps (AdGuard Home included), qBittorrent's web UI on 8081 (8080 is the provisioning listener's), and AdGuard Home and printer settings kept across upgrades, with DNS returned to dnsmasq while AdGuard Home is not installed | `docs/install-apps.md`, `files/etc/config/qbittorrent`, `files/etc/uci-defaults/53-cw-qbittorrent-port`, `files/etc/uci-defaults/95-cw-drop-removed-apps` |
| Build once, publish the tested files: builds fill a private draft release (signature verified, notes from the changelog), and a separate `release` workflow publishes it without rebuilding | `.github/workflows/`, `docs/` |

Everything else is upstream's work, unchanged. These changes are kept in this fork only.

## Thanks

This fork is built on [CleanWRT](https://github.com/Pr0Luci/cleanwrt-aw1000) by
[Pr0Luci](https://github.com/Pr0Luci), who wrote the build, the overlay, the patches, the
documentation and the companion repositories listed above. Thanks for publishing it as free
software.

Thanks also to [XT-Martinez](https://github.com/XT-Martinez) for
[aw1000-feed](https://github.com/XT-Martinez/aw1000-feed), an AW1000 package feed for the
`ppe-nss` OpenWrt tree. This fork's dev container has it alongside as a reference for
comparison. None of its code is in this repository or in the image.

CleanWRT stands on the work of others: the [OpenWrt](https://openwrt.org) project and its
contributors, [QModem](https://github.com/FUjr/QModem),
[Nikki](https://github.com/nikkinikki-org/OpenWrt-nikki) and
[mihomo](https://github.com/MetaCubeX/mihomo), [Zashboard](https://github.com/Zephyruso/zashboard),
[3ginfo-lite](https://github.com/4IceG/luci-app-3ginfo-lite),
[luci-app-diskman](https://github.com/lisaac/luci-app-diskman), and the ImmortalWrt packages that
carry qBittorrent to LuCI. Each keeps its own licence, see
[NOTICE.md](NOTICE.md).

## Licence

GPL-2.0-only, see [LICENSE](LICENSE). It covers the build configuration, patches and rootfs overlay
scripts of this repository. Upstream's code stays © Pr0Luci and its contributors. This fork's
changes are released under the same licence. The OpenWrt base and each bundled package keep their own upstream
licences.

> [!NOTE]
> **QModem** carries an added non-commercial clause. CleanWRT is free of charge and is not sold,
> but if you deploy it in a business, for an ISP or in a paid service, read QModem's licence first.
> See [Licence and notices](https://shanelkapramuditha.github.io/cleanwrt-aw1000-ng/docs/licence/).
