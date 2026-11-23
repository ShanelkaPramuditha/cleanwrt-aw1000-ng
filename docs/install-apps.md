---
title: "Install optional apps"
description: "Step by step: install and set up Cloudflare Tunnel, Syncthing, qBittorrent and the USB printer server on CleanWRT for the Arcadyan AW1000, from LuCI or the command line."
updated: 2026-11-15
---

# Install optional apps

Some apps are left out of the image to keep it small enough for the router's flash. Each one
installs in a minute, from the web interface or with one command, and arrives **switched off**:
nothing listens on your network until you enable it.

| App | What it does | Install |
|---|---|---|
| [Cloudflare Tunnel](#cloudflare-tunnel) | publish a web service under your own domain, no public IP needed | `apk add cloudflared luci-app-cloudflared` |
| [Syncthing](#syncthing) | keep folders in step between your phone, your PC and a USB drive | `apk add syncthing luci-app-syncthing` |
| [qBittorrent](#qbittorrent) | download client that saves to a USB drive | `apk add qbittorrent luci-app-qbittorrent` |
| [AdGuard Home](#adguard-home) | blocks ads and trackers for every device on your network (DNS filter) | `apk add adguardhome luci-app-adguardhome` |
| [Printer server](#printer-server-p910nd) | share a USB printer on your network | `apk add kmod-usb-printer p910nd luci-app-p910nd` |

The examples assume the router is at `192.168.1.1`.

## Before you start

- **The router must be online**: the packages download from the internet.
- **Set a root password first** (*System → Administration*). An app that opens a port on a router
  with no password is an open door. See [Security](features/security.md).
- **Check the free space** for larger apps. In *System → Software* the free space is shown at the
  top; from the command line, `df -h /overlay`. qBittorrent and AdGuard Home need about 30 MB
  each, the others less.

## Two ways to install

=== "From the web interface (LuCI)"

    1. Open **System → Software**.
    2. Click **Update lists…** and wait until it finishes.
    3. Type the package name in **Filter**, for example `luci-app-syncthing`.
    4. On the *Available* tab, click **Install…** next to it, then **Install** in the dialog.
    5. Install every package in the app's row of the table above, one after the other.
    6. Reload the page in your browser: the app's page appears in the menu (usually under
       **Services**).

=== "From the command line (SSH)"

    Log in with `ssh root@192.168.1.1` (or open *Tools → Terminal*), then:

    ```sh
    apk update
    apk add syncthing luci-app-syncthing
    ```

    Use the install line from the table above for the app you want. Reload LuCI in your browser
    afterwards so its menu shows the new page.

Where the packages come from: Cloudflare Tunnel, `syncthing`, AdGuard Home, the printer
server and its driver come from the **official OpenWrt repositories**. qBittorrent and the Syncthing switch
(`luci-app-syncthing`) come from this project's own signed feed, **`cw-opt`**. Every router already
lists both, and `apk` checks each package's signature before it installs anything. See
[Extra packages](extra-packages.md).

!!! warning "After a firmware upgrade, install your apps again"
    A firmware upgrade replaces everything that is not in the image, so apps you installed
    yourself are gone afterwards. **Their settings are kept** (with *Keep settings* ticked, as
    usual), so run the same install line again and the app comes back exactly as you left it.

## Tailscale { #tailscale }

Tailscale is in the image now: see [Remote access](features/remote-access.md#tailscale) to switch
it on and log in.

## Cloudflare Tunnel

Publishes one service, for example a web page on your LAN, under your own domain through your
Cloudflare account. It only connects outwards, so no port is opened on the router.

1. Install:

    ```sh
    apk update && apk add cloudflared luci-app-cloudflared
    ```

2. In your Cloudflare dashboard (*Zero Trust → Networks → Tunnels*), create a tunnel and copy its
   **token**.
3. On the router: **Services → Cloudflare Zero Trust Tunnel → Configuration**. Paste the token,
   tick **Enable**, then **Save & Apply**.
4. Back in the Cloudflare dashboard, add a *Public hostname* for the tunnel that points at the
   service, for example `http://192.168.1.10:80`.

!!! info "A red error before step 3 is normal"
    Until a token is set, the page shows a red `cloudflared` error (`config.yml was empty` or no
    origin certificate). It disappears once the tunnel is configured.

**Remove it:** `apk del luci-app-cloudflared cloudflared`

## Syncthing

Keeps folders in step between your phone, your PC and a USB drive on the router.

1. Plug in a USB drive first: it mounts under `/mnt` by itself. See
   [USB storage](features/storage.md).
2. Install:

    ```sh
    apk update && apk add syncthing luci-app-syncthing
    ```

3. **Services → Syncthing**: tick **Enable**, then **Save & Apply**.
4. Open the dashboard: `http://192.168.1.1:8384`.
5. **Do this first:** *Actions → Settings → GUI*, set a user name and password. Until you do,
   anyone on your network can open the dashboard.
6. Add your other devices (*Add Remote Device*) and choose the folders to share, on the USB drive
   under `/mnt`.

To keep the dashboard reachable from the router only, set *Dashboard address* on the LuCI page to
`http://127.0.0.1:8384`. More: [Apps with their own web interface](features/web-apps.md#syncthing-folder-sync).

**Remove it:** `apk del luci-app-syncthing syncthing`

## qBittorrent

A download client that saves to a USB drive on the router, controlled from a web page.

1. Plug in a USB drive first: downloads go to `/mnt/download`.
2. Install (from this project's `cw-opt` feed):

    ```sh
    apk update && apk add qbittorrent luci-app-qbittorrent
    ```

3. **Services → qBittorrent → Settings**: tick **Enable**, then **Save & Apply**.
4. Open the web UI: `http://192.168.1.1:8081` (or **Open Web Interface** on the LuCI page).
5. The user name is `admin`. There is no shared default password: until you set your own,
   qBittorrent makes a temporary one at every start and prints it to the log. Read it in
   *Status → System Log*, or with `logread -e qbittorrent`.
6. Set your own password: *Tools → Options → Web UI → Authentication*.

!!! note "Why port 8081"
    qBittorrent's usual port, 8080, is taken by the router's provisioning listener for network
    phones. CleanWRT therefore sets 8081, both for a new install and for a router upgraded with a
    qBittorrent configuration that still says 8080. You can pick another free port on the LuCI
    page (*Listen port*).

**Remove it:** `apk del luci-app-qbittorrent qbittorrent`

## AdGuard Home

A DNS filter for the whole network: ads, trackers and malware domains are blocked for every device
that uses the router, phones and TVs included, with no app on the devices. It takes over the
router's DNS (port 53); the router keeps handing out addresses (DHCP) as before.

!!! tip "Use the router's own address"
    The commands below assume the router is at `192.168.1.1`. If you changed it, use your address.

1. **Install.** AdGuard Home starts by itself and waits for its first setup:

    ```sh
    apk update && apk add adguardhome luci-app-adguardhome
    ```

2. **Free port 53 for it.** dnsmasq answers DNS there today. Move it to port 54 (it keeps doing
   DHCP and still knows your devices' names), and tell the devices to use the router as their DNS
   server:

    ```sh
    uci set dhcp.@dnsmasq[0].port='54'
    uci add_list dhcp.lan.dhcp_option='6,192.168.1.1'
    uci commit dhcp
    /etc/init.d/dnsmasq restart
    ```

    Until step 3 is done, name lookups on your network do not work. That is expected; it takes a
    minute.

3. **Run the setup wizard:** open `http://192.168.1.1:3000` and click **Get Started**.
    - *Admin Web Interface*: **All interfaces**, port **3000**. Do not choose 80: that is the
      router's own web interface (LuCI).
    - *DNS server*: **All interfaces**, port **53**.
    - Create the admin user and a strong password, then finish the wizard.

    From now on the dashboard is at `http://192.168.1.1:3000`.

4. **Point it at a DNS provider and at your devices' names.** In the dashboard, open
   *Settings → DNS settings*:
    - *Upstream DNS servers*: for example `https://dns.cloudflare.com/dns-query` and
      `https://dns.quad9.net/dns-query` (encrypted DNS), then **Apply**.
    - *Private reverse DNS servers*: `127.0.0.1:54`, and tick **Use private reverse DNS
      resolvers**, then **Save**. The query log then shows device names instead of bare addresses.

5. **Blocklists:** *Filters → DNS blocklists*. The *AdGuard DNS filter* is on already; **Add
   blocklist → Choose from the list** offers more.
6. **Check it works.** On a computer on your network:

    ```sh
    nslookup doubleclick.net 192.168.1.1
    ```

    A blocked domain answers `0.0.0.0`. The *Dashboard* now counts queries and blocked requests.

**Good to know**

- **LuCI page:** *Services → AdGuard Home* shows whether the service runs and its service
  settings (user, folders, memory limit). Filtering itself is set up in the dashboard on port 3000.
- **Statistics and the query log start fresh after a reboot:** they are kept in RAM
  (`/var/lib/adguardhome`). To keep them, set *Working directory* on the LuCI page to a folder on a
  USB drive, for example `/mnt/adguardhome`.
- **With Nikki:** if Nikki runs with *DNS hijack* on, it catches your devices' DNS before AdGuard
  Home sees it, so nothing is filtered. Use one of the two for DNS: turn DNS hijack off in Nikki
  to let AdGuard Home filter.
- **After a firmware upgrade:** the app is gone but its settings are kept, and CleanWRT puts
  dnsmasq back on port 53 by itself so the internet keeps working. Reinstall (step 1) and move
  dnsmasq again (step 2); the wizard is not needed, your filters and settings are still there.

**Remove it** and give DNS back to dnsmasq:

```sh
apk del luci-app-adguardhome adguardhome
uci -q delete dhcp.@dnsmasq[0].port
uci del_list dhcp.lan.dhcp_option='6,192.168.1.1'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

## Printer server (p910nd)

Shares a USB printer so the computers on your network can print to it.

1. Plug the printer into the router's USB port.
2. Install the printer driver, the server and its page:

    ```sh
    apk update && apk add kmod-usb-printer p910nd luci-app-p910nd
    ```

3. Check that the printer was found: `ls /dev/usb/` should list `lp0`. If not, unplug the printer
   and plug it in again.
4. **Services → Printer server**: tick **Enabled**, set *Device* to `/dev/usb/lp0`, keep *Port*
   at **9100**, then **Save & Apply**.
5. On each computer, add a network printer of type *Raw / JetDirect / AppSocket* at
   `192.168.1.1`, port `9100`, and choose the printer's own driver.

**Remove it:** `apk del luci-app-p910nd p910nd kmod-usb-printer`

## If something goes wrong

| What you see | What to do |
|---|---|
| `apk add` says a package is not found | run `apk update` first (or **Update lists…** in *System → Software*) |
| `apk update` reports an error for one address and works for the rest | that repository is unreachable right now. Packages from the others still install; try again later |
| `UNTRUSTED signature` | the package or index is not signed by a key the router trusts. Do not force it: run `apk update` again later |
| `No space left on device` | remove apps you do not use (`apk del …`); check with `df -h /overlay` |
| The app's page does not appear in LuCI | reload the page in your browser (the menu is cached) |
| The app worked, and is gone after a firmware upgrade | expected: install it again with the same line, its settings are still there |
| qBittorrent's web UI does not open | use port **8081**, not 8080; check that the app is enabled and a USB drive is mounted |
| The printer is not found (`/dev/usb/lp0` missing) | make sure `kmod-usb-printer` is installed, then replug the printer |
| AdGuard Home: `http://192.168.1.1:3000` does not open after the install | start it: `/etc/init.d/adguardhome enable && /etc/init.d/adguardhome start` |
| AdGuard Home: the wizard says port 53 is in use | dnsmasq still holds it: do [step 2](#adguard-home) first |
| AdGuard Home: no website opens after setup | check that AdGuard Home is running (*Services → AdGuard Home*) and that it has upstream DNS servers. To get the internet back at once, run the commands under *Remove it* |
| AdGuard Home: nothing is blocked | the device may use its own DNS (some browsers and phones have "secure DNS" or "private DNS" on), or Nikki's DNS hijack is catching it |

## Questions people ask

??? question "Why are these apps not in the image?"
    They are large: Cloudflare Tunnel is about 10 MB, qBittorrent with the
    libraries it needs and AdGuard Home about 25–30 MB each. Leaving them out keeps the image small, and anyone who wants
    one installs it in a minute.

??? question "Are the packages safe to install?"
    `apk` installs only packages signed by a key the router trusts: the official OpenWrt key for
    the official repositories, and this project's key for the `cw-opt` feed. A package with any
    other signature is refused.

??? question "Do I have to reinstall apps after every firmware upgrade?"
    Yes. A firmware upgrade replaces what is not part of the image. With *Keep settings* ticked,
    each app's settings survive, so the same install line brings it back as it was.
