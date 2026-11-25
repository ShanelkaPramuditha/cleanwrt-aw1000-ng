---
batch: ENH-02
title: "Dashboard client names, QModem table layout"
status: doing           # todo | doing | review | done | blocked
started: 2026-11-25
updated: 2026-11-25 08:51 UTC
progress:
  code: 2/2
  off_device: 2/2
  on_router: 0/3
  suggestions_open: 0
---

# ENH-02: Dashboard client names, QModem table layout

User report of 2026-11-25: after the last firmware update the Vantage Dashboard shows
"Unknown device E5:AF" (wired, lan1, 192.168.1.247) and "Unknown device 4B:B1" (Wi-Fi,
192.168.1.193) where it used to show names. The diagnosis is in *Notes*. There is no bug in
Vantage or LuCI; the image gets one more name source (T1), and the router gets fixed names (T2).
Same day, from screenshots: three *Advance Modem Settings* tabs (Neighbor Cell, Lock Band, Dial
Mode) laid out wrong under Vantage (T3).

## Progress

| stage | done | bar |
|---|---|---|
| Code and docs written | 2 of 2 tasks | `████████████████████` 100% |
| Checked off-device | 2 of 2 tasks | `████████████████████` 100% |
| Tested on the router | 0 of 3 tasks | `░░░░░░░░░░░░░░░░░░░░` 0% |
| Committed | no | |

**Where it stands (2026-11-25 08:51 UTC):** T1 and T3 written and checked off-device (wait for a build and the router). T2 waits for the user to add the static leases.

## Router test checklist

- [ ] `ubus call umdns hosts` answers on a new image, and a device that announces itself over mDNS gets a name with the `mDNS` tag on the Dashboard (T1)
- [ ] after the static leases, 192.168.1.247 and 192.168.1.193 show their names on the Dashboard within a minute (T2)
- [ ] Neighbor Cell: the Connected row is the first visible row under the titles; Lock Band: every band line and the Select All / Submit row stay apart and inside the card; Dial Mode: current mode and radios sit under their titles, Submit inside the card (T3)

## Progress log

| time (UTC) | what happened |
|---|---|
| 06:33 | batch opened; diagnosis from the user's `/tmp/dhcp.leases`, `getHostHints` and `ipconfig` output |
| 06:40 | T1: `CONFIG_PACKAGE_umdns=y` in the seed; `docs/included.md`, `docs/changelog.md`, `NOTICE.md`, `README.md` rows added |
| 06:45 | T1: deps `libubox libubus libblobmsg-json libudebug` already `=y` in `../openwrt/.config`, so defconfig keeps it; T1 → review. T2: static-lease commands given to the user |
| 08:51 | T3 opened from the user's screenshots; causes found in `luci-theme-vantage` `vantage.css` (`.td` height 44px, `div.left` block, sticky `.th`); `patches/feeds/qmodem/0015-vantage-table-layout-fixes.patch` written from a/ b/ trees, applies `-F0` on a fresh 0988085b + 0002-0014, equals b/, reverses; listed in building/NOTICE/README/changelog; tool tests pass; T3 → review |

## Summary

| ID | task | status | patch / files |
|---|---|---|---|
| ENH-02-T1 | Add `umdns` to the image, so Vantage can use mDNS names | review | `configs/arcadyan_aw1000.seed`, `docs/included.md`, `docs/changelog.md`, `NOTICE.md`, `README.md` |
| ENH-02-T2 | Fixed names for the two unnamed devices on the user's router | doing | router only (`/etc/config/dhcp`) |
| ENH-02-T3 | Advance Modem Settings tables under Vantage (Neighbor Cell, Lock Band, Dial Mode) | review | `patches/feeds/qmodem/0015-vantage-table-layout-fixes.patch` |

## Tasks

### ENH-02-T1: Add `umdns` to the image

- **Status:** review
- **From:** user request 2026-11-25 ("do the suggestions")
- **Goal:** the Dashboard names a device that sends no DHCP hostname but announces one over mDNS.
- **Files:**
  - `configs/arcadyan_aw1000.seed`
  - `docs/included.md`
  - `docs/changelog.md`
  - `NOTICE.md`, `README.md` (change-table rows)
- **Changes:**
  - select `CONFIG_PACKAGE_umdns=y` (base package `package/network/services/umdns`; default config listens on `lan`, jailed). Vantage's ACL already grants `umdns hosts`; the `lan` zone accepts input, so UDP 5353 needs no firewall rule
- **Verification:**
  - [x] seed option present once and well-formed (off-device)
  - [x] every dependency already selected in `../openwrt/.config`, so `make defconfig` keeps it (off-device; `make defconfig` itself not run)
  - [ ] `ubus call umdns hosts` answers on the router, the Dashboard shows `mDNS` names (on the router)
- **Remaining:**
  - build an image; check on the router

### ENH-02-T2: Fixed names on the user's router

- **Status:** doing
- **From:** user request 2026-11-25
- **Goal:** the two devices keep a name whatever they send.
- **Files:** none in the repository; static leases in the router's `/etc/config/dhcp`
- **Changes:**
  - the user adds static leases (commands given in the session)
- **Verification:**
  - [ ] names show on the Dashboard (on the router)
- **Remaining:**
  - the user runs the commands

### ENH-02-T3: Advance Modem Settings tables under Vantage

- **Status:** review
- **From:** user screenshots 2026-11-25 ("some rows not visible", "this has issues", "button card padding issue")
- **Goal:** Neighbor Cell shows its first (Connected) row; Lock Band's bands and buttons do not overlap or leave the card; Dial Mode's cells line up and Submit stays in the card.
- **Files:**
  - `patches/feeds/qmodem/0015-vantage-table-layout-fixes.patch` (new, after 0014)
  - `docs/building.md`, `NOTICE.md`, `README.md`, `docs/changelog.md`, `docs/modem.md` (`updated:`)
- **Changes:** (causes in `luci-theme-vantage` `htdocs/luci-static/vantage/vantage.css` @ a7ff63b)
  - `.td { height: 44px }` is a fixed height on a `display: flex` cell: `td.qm-btn-row` (0011) and the band cell (now class `qm-band-cell`) get `height: auto`
  - `div.left { display: block }` (vantage.css:1921) pulled Dial Mode's `div.td.left` cells out of the table: `.cbi-section-table div.td.left { display: table-cell }`
  - sticky `.th` (vantage.css:1805) inside 0012's `.qm-nc-scroll` (`overflow-x: auto`) stuck to the scroller, `--stick-top` down over row 1: `.qm-nc-table .tr > .th.th { position: static }` (Vantage does the same for LuCI tables, vantage.css:3000)
- **Verification:**
  - [x] patch from clean a/ b/ trees; applies with `-F0` to a fresh `0988085b` with 0002-0014, result identical to b/, reverses cleanly (off-device)
  - [x] selector specificity beats each theme rule, and the page `<style>` comes after the theme stylesheet (off-device, by reading)
  - [ ] page script parsed with node (not done: no node in this container; the only JS change is one `classList.add` line)
  - [ ] layout seen in a browser (not done: no browser here; jsdom does no layout)
  - [ ] the three tabs on the router under Vantage (on the router)
- **Remaining:**
  - build an image; check on the router

## Notes

- Vantage (`luci-app-vantage` 1.2.0, pinned at `a7ff63b` in every commit of
  `configs/local-packages.pin`) names a station in this order: alias, reverse DNS, DHCP hostname
  (`luci-rpc getHostHints` `name`), mDNS (`umdns hosts`), WPS, vendor (small built-in OUI table),
  "Private device", "Unknown device".
- User's leases: `c8:f7:50:70:e5:af 192.168.1.247 *` (no hostname), and `a8:31:62:f8:4b:b1` absent
  (known only from ARP). `48:89:e7:df:c0:0a 192.168.1.217 DESKTOP-5NS3N07` holds the PC's name.
- `ipconfig` shows 192.168.1.247 is the same Windows PC on its Ethernet adapter, Wi-Fi
  disconnected. dnsmasq refuses a client-sent name that another live lease holds, **without a
  log line** (the `not giving name` warning is only for `/etc/hosts` clashes), so the wired lease
  got `*` while the old Wi-Fi lease (12 h) still holds `DESKTOP-5NS3N07`. Before the update the PC
  was on Wi-Fi, so it was named.
- 4B:B1: dnsmasq keeps leases in RAM (`/tmp/dhcp.leases`); the reflash dropped it and the device
  kept its address without asking again. Named again at its next DHCP request.
- `umdns` was never in the image (`# CONFIG_PACKAGE_umdns is not set` in `openwrt/.config`), so
  Vantage's mDNS source was always off. It helps Apple, Android, printers and IoT devices; Windows
  answers mDNS queries but announces little, so it may not name the PC.

## Suggestions

Written when the batch closes.
