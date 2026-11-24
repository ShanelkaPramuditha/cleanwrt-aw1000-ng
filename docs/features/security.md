---
title: "OpenWrt router security defaults on the AW1000"
description: "How CleanWRT secures the Arcadyan AW1000 by default: no open services, HTTPS for the admin UI, a first-login password, Wi-Fi key and service advice."
updated: 2026-11-06
---

# Security

## Defaults

CleanWRT starts the way stock OpenWrt does:

- **No root password** at first. The first login happens over **Ethernet**, and LuCI asks you
  to set one. Until you do, **SSH refuses root**: stock OpenWrt lets anyone who reaches port 22 in
  as root with no password, this image does not. SSH works as soon as a password is set, with no
  restart. Failsafe mode still opens a shell with no password, for recovery.
- Wi-Fi is the stock OpenWrt default: SSID `OpenWrt`, no key, and **off**. Set a key before you enable it.
- Every opt-in service is **disabled**. Nothing listens on your network until you enable it.
- LuCI is served over **HTTPS**; plain HTTP only redirects to it.

See [First boot](../first-boot.md) for the steps.

!!! warning "Before you expose the router remotely"
    Set your root password first. Otherwise a tunnel publishes an admin interface with no
    password to the internet.

## Why the browser says "Not secure" { #why-the-browser-says-not-secure }

The admin UI uses a **self-signed TLS certificate**, generated on your router at first boot.
Every router gets a different one and no public authority signed it, so browsers warn exactly
as they do on stock OpenWrt. The connection is still encrypted. Click *Advanced → Proceed*.

**To stop the warning for good, trust the router's certificate once.** This image makes it with
the names you type: the LAN address (`192.168.1.1`), the hostname (`openwrt`) and
`openwrt.lan`. Stock OpenWrt's certificate names only the hostname, so trusting it changes nothing
at `https://192.168.1.1`.

1. Copy the certificate to your computer: `scp root@192.168.1.1:/etc/uhttpd.crt cleanwrt.crt`
   (or open the site, click the padlock / *Not secure*, and export the certificate).
2. Trust it:
    - **Windows:** double-click `cleanwrt.crt` → *Install Certificate* → *Local Machine* →
      *Place all certificates in the following store* → *Trusted Root Certification Authorities*.
      Chrome and Edge use this store.
    - **macOS:** double-click it, then in *Keychain Access* open it and set *Trust* to
      *Always Trust*.
    - **Firefox** keeps its own list: *Settings → Privacy & Security → Certificates → View
      Certificates → Authorities → Import*.
3. Restart the browser and open `https://192.168.1.1` again.

A router upgraded from an older image keeps the certificate it had, which names only the
hostname. To make the new kind, and after you change the router's LAN address, run
`cw-https-cert` over SSH, then trust the new file the same way. The certificate is valid for
825 days.

If you own a domain, you can get a publicly trusted certificate instead:

```sh
apk add acme-common luci-app-acme
```

Then issue a Let's Encrypt certificate with a DNS challenge (it works behind CGNAT).

## Changing the password and the Wi-Fi key later

- Root password: *System → Administration*, or `passwd` over SSH.
- Wi-Fi key: *Network → Wireless*, edit the interface, *Wireless Security*.

No re-flash is needed.

## Keeping services private

| Service | Reach | Advice |
|---|---|---|
| File sharing (SMB) | LAN | guest access is off; create users first |
| qBittorrent web UI (`:8081`), once installed | LAN | the first start prints a temporary password to the log; set your own |
| Syncthing GUI (`:8384`), once installed | LAN | set a GUI user and password before pairing |
| miniDLNA (`:8200`) | LAN only | no login; do not expose it |

## Reporting a problem

For a security problem, please open a private report from the repository's *Security* tab
(*Report a vulnerability*) if it is enabled, or open an issue that does not include exploit
details and ask for a private channel.

## Common questions

??? question "Why does my browser say the OpenWrt router connection is not secure?"
    LuCI uses a self-signed certificate that your router creates at first boot. The connection is still encrypted, but no public authority signed the certificate. Click *Advanced → Proceed*, or install a trusted certificate with ACME if you own a domain.

??? question "What are the default passwords on CleanWRT?"
    There is no root password at first. The first login happens over Ethernet and LuCI asks you to set one. Wi-Fi is the stock OpenWrt default: off, SSID `OpenWrt`, no key. Set a key before you enable it.

??? question "How do I get a trusted HTTPS certificate on the router?"
    Install `acme-common` and `luci-app-acme`, then issue a Let's Encrypt certificate with a DNS challenge. That works behind CGNAT because it needs no inbound connection.

## Out of the box

| | state | who wrote it |
|---|---|---|
| LuCI over HTTPS, HTTP redirected | on | `46-cw-uhttpd-https` |
| Root password | **none**, until you set one | `99-aw1000-defaults` leaves it unset, as stock OpenWrt does. Unlike stock, SSH refuses root until one is set (`patches/tree/0002-dropbear-no-blank-root-password.patch`) |
| Wi-Fi | off, SSID `OpenWrt`, no key | OpenWrt's own default; this image does not change it |
| Firewall | stock zones and defaults, `firewall4` and `nftables` | OpenWrt |
| Opt-in apps | off, so nothing listens | each package's own default |
| The provisioning listener | **open on port 8080, LAN only**, private-network filtered, directory listings off, document root holding one directory | `49-cw-awvoice-provision-port` |
| The SIP listener | **closed** until the AWvoice page's switch starts it | the switch |
| The browser audio port | opens with the phone line, bound to the LAN interface's address; a session on it needs a single-use token and only one page may hold it | `awvoice.main.web_iface` |
| Package pins | rewritten on every boot so `apk upgrade` cannot replace patched LuCI packages | `96-cw-apk-world-pin` |
| Attended-sysupgrade UI | removed from the menu; the newer-version check stays | `48-cw-strip-asu-ui` |

## What is listening

The complete list, with the defaults, is in
[files, ports and paths](../reference/files-and-ports.md#network-ports). The short version on a new
router: 443 and 80 for the admin interface, 8080 for the provisioning listener, the LAN-side DNS and
DHCP, and SSH on the LAN. Nothing is forwarded from the cellular side, and there is no UPnP.

## When it does not work

| symptom | what it means |
|---|---|
| The browser warns about the certificate | it is self-signed and created on your router. Expected. See the section above |
| `apk upgrade` says a package is held back | that is the pin working. See [updating and pinning](../updating.md) |
| A port you did not open answers on the LAN | check which app you enabled, and remember the provisioning listener on 8080 is opened by the image itself |
| LuCI says *"This account may not do that"* after an upgrade | grants are snapshotted at login. Log out and back in. See [the API and who may call it](../reference/ubus-and-acl.md#who-may-call-what) |

## Questions people ask

??? question "Is the AW1000 safe with CleanWRT on a 5G connection?"
    It is a router behind carrier NAT with nothing forwarded in, and this image opens no inbound
    service beyond the LAN-side admin interface and the local provisioning listener. What makes it
    unsafe is the same thing that makes any router unsafe: no root password, and the default Wi-Fi
    key still in place.
