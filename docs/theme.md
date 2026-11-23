---
title: "Themes: Vantage and Footstrap"
description: "The web interface of CleanWRT: Vantage, the default theme with its Dashboard, and Footstrap beside it, both with dark and light modes."
updated: 2026-11-23
---

# Themes

CleanWRT ships two third-party LuCI themes and LuCI's own Bootstrap as the fallback:

| Theme | Licence | In the image |
|---|---|---|
| [Vantage](#vantage) ([`luci-theme-vantage`](https://github.com/anothaDev/luci-theme-vantage) + `luci-app-vantage`) | GPL-3.0-or-later | the default on a fresh flash |
| [Footstrap](#footstrap) ([`luci-theme-footstrap`](https://github.com/VizzleTF/luci-theme-footstrap)) | Apache-2.0 | installed, one click away |
| Bootstrap (LuCI's own) | Apache-2.0 | the fallback |

Both third-party themes are pinned to one commit each in `configs/local-packages.pin`, like every
other out-of-feed package here.

## Vantage

Vantage is a console-style theme: an icon rail with flyout menus, a breadcrumb, page tabs, a
**Ctrl+K** command palette, and light, dark and auto modes from the button in the top bar. Its
companion package `luci-app-vantage` adds the **Dashboard**, the first page after login: live
traffic, the network path, clients and radios. The Appearance settings under the gear button are
saved on the router in `/etc/config/vantage_theme`, so every browser sees the same look.

CleanWRT changes one thing in it:
`patches/packages/luci-theme-vantage/0001-export-tier-for-stock-theme-pages.patch` makes Vantage
publish the colour tokens LuCI's Bootstrap theme publishes (`--background-color-high`,
`--text-color-highest` and the rest), mapped onto its own palette. Pages written for the stock themes
colour themselves from those tokens - *Modem → 3gInfo-lite*, QModem's signal bars, the AWvoice phone
page - and without them fell back to white tiles and dark text on Vantage's dark cards.
`patches/packages/luci-app-cw-led/0002-lamp-colours-follow-the-theme-switch.patch` does the same for
the lamps on the LED page, which read the browser's preference rather than the theme's switch.

Vantage's full documentation, including its own troubleshooting, is in
[its repository](https://github.com/anothaDev/luci-theme-vantage/blob/main/docs/INSTALL.md).

## Footstrap

Footstrap was the default before Vantage and stays in the image. **CleanWRT changes only its login
page**, with two small patches:
`patches/packages/luci-theme-footstrap/0001-login-page-carries-the-image-logo.patch` puts the
CleanWRT logo where the theme otherwise prints the router's hostname, and
`0002-login-card-centred-in-the-viewport.patch` centres the login card on the screen. Everything else
is the theme as its own author publishes it.

### What it looks like

- **Dark by default**, with light and auto modes, and a choice per browser as well as one saved on
  the router.
- A **top bar or a sidebar** for the menu, and a narrow-screen layout below 768 px.
- Five **palettes** - Footstrap, Bootstrap, 2020, Forum and Hi-Contrast - plus a free **accent
  colour** you can set by hue or by hex.
- **Frosted surfaces**: cards, controls and bars each take their own colour, material
  (flat, acrylic or frosted), opacity and a blur amount, with a corner rounding from 0 to 20 px.
- A **wallpaper** behind the pages: an SVG pattern of your own, or a photo, with the pattern's size,
  strength and ink and the photo's dimming all adjustable. The login page takes the same photo, and
  carries the CleanWRT logo above the username.
- **Density** (normal, compact, large) and a **content width** from 1280 to 3840 px.

### Screenshots

=== "Dark"

    [![Status overview, dark](assets/img/overview-dark.jpg)](assets/img/overview-dark.jpg)

=== "Light"

    [![Status overview, light](assets/img/overview-light.jpg)](assets/img/overview-light.jpg)

=== "Phone"

    [![Status overview on a phone](assets/img/overview-mobile.jpg)](assets/img/overview-mobile.jpg){ width="300" }

The login page, dark and light:

| Dark | Light |
|---|---|
| ![Login, dark](assets/img/login-dark.jpg) | ![Login, light](assets/img/login-light.jpg) |

The theme's own settings page:

[![Footstrap settings](assets/img/appearance-dark.jpg)](assets/img/appearance-dark.jpg)

!!! info "About the screenshots"
    These were taken from a real AW1000 running this firmware. The status page is LuCI's own: the
    theme draws its tables as boxes, and no part of it is patched by this repository.

### The settings page: System → Footstrap

The theme registers one page of its own, **System → Footstrap**, with four tabs: *Colour scheme*,
*Interface*, *Background* and *Colours*.

Changes there apply to the browser you are in immediately. Three buttons decide what happens next:

- **Save to router** writes the look into `/etc/config/footstrap`, so every other browser and
  device that opens the page gets it too. A browser that has chosen its own look keeps that choice.
- **Reset to router** drops this browser's own changes and follows the router again.
- **Reset to built-in** goes back to the defaults the theme itself ships with.

### The look a new router starts with

A fresh install does not start at the theme's own defaults:
`files/etc/uci-defaults/50-cw-footstrap-look`
writes the image's default look into `/etc/config/footstrap` on first boot - dark mode, the top
layout, the Footstrap palette, 12 px rounding, frosted surfaces - together with the two files that
make up its background:

- `files/etc/footstrap/login-bg`, the photo behind the pages and the login card;
- `files/etc/footstrap/pattern.svg`, the pattern the *pattern* wallpaper mode draws.

The two settings that name those files hold their checksums, so the script reads the checksums off
the files actually installed rather than trusting a number written down. It runs once: it marks the
look it applied, and a router whose look has already been saved to the router is left alone - your
choice always outranks the image's.

## Switching themes

A fresh flash opens in Vantage. To change it:

*System → System → Language and Style → Design*

Vantage is listed as `Vantage`, Footstrap as `Footstrap`. Over SSH:

```sh
uci set luci.main.mediaurlbase=/luci-static/footstrap   # or /luci-static/vantage
uci commit luci
```

**An upgrade that keeps the settings keeps the theme.** A router that was on Footstrap stays on
Footstrap, with Vantage added to the design list: Vantage's own first-boot script selects Vantage
whenever its entry is new, so `files/etc/uci-defaults/29-cw-keep-chosen-theme` registers the entry
just before it runs on such a router. Only a router still on the stock Bootstrap base moves to Vantage.

Bootstrap is the fallback: if the pinned theme did not install, `files/etc/uci-defaults/96-cw-default-theme`
leaves the stock base alone, so the web interface still opens, and Bootstrap is always a choice in the
selector.

An upgrade from an older image can leave two things naming a theme this image no longer carries: the
base the interface opens with, and the entry the design selector offers. Both are repaired at the
first boot after the upgrade - the base moves to Vantage and the entry is removed - so a router that
had another design selected does not open on a page with no styles.

## Notes for developers

Vantage installs its templates under `/usr/share/ucode/luci/template/themes/vantage/`, its resources
under `/www/luci-static/vantage/` and `/www/luci-static/resources/vantage-theme/`, and the conffile
`/etc/config/vantage_theme`. The Dashboard adds `admin/dashboard` as the first menu entry, the rpcd
ACL `luci-app-vantage` and `/etc/config/vantage` (the names you give devices). Under another theme,
*Dashboard* opens LuCI's Status → Overview instead.

Footstrap installs its ucode templates under
`/usr/share/ucode/luci/template/themes/footstrap/` (`header.ut`, `footer.ut`, `sysauth.ut` and two
partials), its resources under `/www/luci-static/footstrap/`, its settings view at
`/usr/share/luci/menu.d/luci-theme-footstrap.json` pointing at `footstrap/appearance`, and its own
`/etc/config/footstrap` conffile with a first-boot script of its own. Because that conffile belongs
to the package, this repository ships no copy of it: the image's look is applied by the
`uci-defaults` script above instead.

The two background files live in `/etc/footstrap/`, which the theme's own
`/lib/upgrade/keep.d/luci-theme-footstrap` lists, so a sysupgrade keeps whatever the admin uploaded
there. `/www/luci-static/footstrap/bg` and `.../fonts` are symlinks into that directory.

## Common questions

??? question "Does CleanWRT have a dark mode?"
    Yes, in both themes. In Vantage, the light / dark / auto button in the top bar. In Footstrap,
    *System → Footstrap → Colour scheme → Mode* offers Auto (follows your system), Light and Dark; a
    browser can also keep its own choice, which **Reset to router** gives up.

??? question "A page looks wrong in dark mode"
    Pages from LuCI apps colour themselves; most follow the theme, some carry light colours of their
    own. Reload with Ctrl+Shift+R first (LuCI caches scripts by its own version). If it persists,
    note the page and the theme and open an issue.

??? question "Does the theme work on a phone?"
    Yes. The layout collapses below 768 px, and the density and content width are adjustable on the
    settings page.

??? question "How do I switch back to the default OpenWrt theme?"
    Go to *System → System → Language and Style → Design* and pick Bootstrap. Bootstrap stays
    installed in the image precisely so that this is always possible.

??? question "Does CleanWRT patch the theme?"
    Only the login page: it shows the CleanWRT logo instead of the router's hostname, and its card
    is centred on the screen instead of sitting near the top. Everything else is the upstream
    package at its pinned commit. The logo is this repository's own
    file (`files/www/luci-static/cw-branding/login-logo.png`), outside the theme's directory, so a
    theme update can neither overwrite it nor collide with the patch. The look a new router starts
    with is added by a first-boot script and two background files, not by a patch.
