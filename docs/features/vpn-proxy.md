---
title: "Nikki, WireGuard and OpenVPN on OpenWrt"
description: "The VPN and proxy tools shipped in CleanWRT for the Arcadyan AW1000, what is off by default, and the proxy app in the image: Nikki (mihomo, Clash profiles)."
updated: 2026-11-23
---

# VPN and proxies

Nikki and Tailscale ship installed and **disabled**; WireGuard and OpenVPN are one install away.
All of them need your servers, keys or configuration. For reaching the router from outside, see
[remote access](remote-access.md): Tailscale is in the image for that.

## WireGuard { #wireguard }

WireGuard is not in the image; Tailscale is the VPN it ships. To run your own WireGuard tunnel,
install it from the official repositories (the kernel module matches the image's kernel):

```sh
apk update && apk add kmod-wireguard wireguard-tools luci-proto-wireguard
```

Then reload LuCI. **WireGuard VPN** appears as a protocol under *Network → Interfaces*, and its
tunnels are listed on *Status → WireGuard* once one exists.

**Upgrading a router that runs a WireGuard tunnel:** with *Keep settings*, the tunnel's settings
stay, and the first time the router is online after the upgrade it installs these three packages
again by itself and brings the tunnel up (`logread -e cw-wireguard` shows it). Until then, that
interface is down.

**Create a tunnel:** *Network → Interfaces → Add new interface*, name it (for example `wg0`),
protocol **WireGuard VPN**, *Create interface*. In the interface's *Configuration* tab set the
private key and the peers (a peer is an endpoint plus allowed IPs).

Command line alternative:

```sh
wg genkey | tee privatekey | wg pubkey > publickey
```

then configure with `wg set`.

## OpenVPN { #openvpn }

OpenVPN is not in the image either. If a provider or office gives you only
an `.ovpn` file, install it:

```sh
apk update && apk add openvpn-openssl luci-app-openvpn
```

Its page then appears under *VPN → OpenVPN*. A router upgraded from an image that still had
OpenVPN keeps `/etc/config/openvpn`, so installing it again brings your settings back.

## Proxies

| App | Where | Core | Configured with |
|---|---|---|---|
| Nikki | *Services → Nikki* | mihomo (Clash Meta) | a Clash YAML profile: a file or a subscription URL |

## Nikki: Clash profiles and a dashboard { #nikki }

Nikki runs the mihomo core with an ordinary Clash (Clash Meta) configuration, so a profile from
your provider or one you wrote yourself works as it is.

1. *Services → Nikki → Profile*. Either upload your `config.yaml` (**Upload Profile**), or add a
   **subscription** with the URL your provider gave you and press **Update**.
2. *Services → Nikki → App Config*: pick that profile, tick **Enable**, **Save & Apply**.
3. **Open Dashboard** on the same page opens Zashboard, already installed, with the secret filled
   in. There you switch proxies and groups, run latency tests, and watch connections, rules and
   logs live.

*Mixin Config* overrides parts of the profile without editing it: ports, DNS mode (fake-ip by
default), TUN or TProxy, and the dashboard address. *Proxy Config* chooses which LAN devices and
which traffic go through the proxy.

**Dashboard address:** `http://192.168.1.1:9090/ui/`. The API on port 9090 needs the secret, which
the first boot sets to 32 random characters (`nikki.mixin.api_secret`). LuCI passes it for you.

**Update Dashboard** downloads the newest Zashboard release over the installed one. A clean
install brings back the version the image ships.

## Common questions

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Neither is in the image; both are one install away (see [WireGuard](#wireguard) and [OpenVPN](#openvpn)). Tailscale is the VPN in the image.

??? question "Can I use my Clash config?"
    Yes, with Nikki. Upload the YAML file or add its subscription URL on *Services → Nikki → Profile*. mihomo reads Clash and Clash Meta profiles.

??? question "Where did Passwall go?"
    Passwall and Passwall 2 are not in this build. Nikki (mihomo) covers the same use, with Clash profiles.

## Out of the box

| | state |
|---|---|
| WireGuard | **not in the image**, one `apk add` away (see [above](#wireguard)) |
| OpenVPN | **not in the image**, one `apk add` away (see [above](#openvpn)) |
| Nikki | installed, **off**. Its core is `mihomo-meta` (stable); the Zashboard dashboard is preinstalled. First boot moves its HTTP proxy port from 8080 (taken) to **7893** and sets a random dashboard secret and proxy password |
| HomeProxy, Passwall, Passwall 2, OpenClash | **not in the image**. OpenClash is no longer built either: Nikki runs the same Clash profiles |
| Tailscale | installed, **off**: *Services → Tailscale → Enable and start*, then log in. See [remote access](remote-access.md#tailscale) |
| Cloudflare Tunnel | **not in the image**, one `apk add` away. See [remote access](remote-access.md) |

## What is listening

A proxy that is off listens on nothing. When Nikki is enabled it listens on the LAN: 7890 (mixed
HTTP/SOCKS), 7893 (HTTP), 1080 (SOCKS), 7891/7892 (redirect and TProxy), 1053 (its DNS) and 9090
(the dashboard API, secret required). When enabled, the transparent-proxy ports are local to
the router and the LAN, and none of them is forwarded from the cellular side by this image.

## When it does not work

| symptom | what it means |
|---|---|
| Nikki will not start | the profile failed its test. *Services → Nikki → Log* shows mihomo's reason; a common one is a port in the profile that another service already uses |
| The dashboard says it cannot connect | the API address or secret. Open it from LuCI's **Open Dashboard**, which fills both in |
| Nikki and a VPN fight over the traffic | run Nikki or a full-tunnel VPN, not both. Each installs its own routing rules |
| A proxy in your profile is refused | check that mihomo supports its protocol. mihomo is the only proxy core in the image |
| `apk upgrade` pulled a different mihomo | the feed pins decide what the image is built with; see [updating and pinning](../updating.md) |

## Questions people ask

??? question "Why is there no VPN menu?"
    OpenVPN's page was the only one under it, and OpenVPN is no longer in the image. Installing OpenVPN or Cloudflare Tunnel brings the VPN menu back.

??? question "Can I install Passwall myself?"
    It is not built for this image, and its cores (xray-core and others) are not in the image either.
    Nikki is the supported proxy app.

??? question "Which dashboard is it, and why that one?"
    Zashboard, the dashboard Nikki itself defaults to. The image carries its build without bundled
    fonts (it uses the system's), about 1.5 MiB on flash, so it opens without downloading anything.
