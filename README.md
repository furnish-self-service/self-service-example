# self-service-example

An example app collection for [furnish](https://github.com/furnish-self-service/furnish). Copy it as a starting point for your organization's own catalog.

## Apps in this collection

| App | Category | Recommended for | Windows (winget) | macOS (Homebrew) | Linux |
|---|---|---|---|---|---|
| `firefox` | Internet | Everyone | `Mozilla.Firefox` | `firefox` | `firefox` |
| `google-chrome` | Internet | | `Google.Chrome` | `google-chrome` | – |
| `thunderbird` | Communication, Office | Office work | `Mozilla.Thunderbird` | `thunderbird` | `thunderbird` |
| `slack` | Communication | Everyone | `SlackTechnologies.Slack` | `slack` | – |
| `zoom` | Communication | Everyone | `Zoom.Zoom` | `zoom` | – |
| `microsoft-teams` | Communication | Office work | `Microsoft.Teams` | `microsoft-teams` | – |
| `libreoffice` | Office | Office work | `TheDocumentFoundation.LibreOffice` | `libreoffice` | `libreoffice` |
| `adobe-acrobat-reader` | Office | Office work | `Adobe.Acrobat.Reader.64-bit` | `adobe-acrobat-reader` | – |
| `keepassxc` | Security | Everyone | `KeePassXCTeam.KeePassXC` | `keepassxc` | `keepassxc` |
| `7zip` | Utilities | | `7zip.7zip` | `sevenzip` | `7zip` |
| `vlc` | Video | | `VideoLAN.VLC` | `vlc` | `vlc` |
| `git` | Development | Software development | `Git.Git` | `git` | `git` |
| `visual-studio-code` | Development | Software development | `Microsoft.VisualStudioCode` | `visual-studio-code` | – |
| `postman` | Development | Software development | `Postman.Postman` | `postman` | – |
| `gimp` | Graphics | Design and media | `GIMP.GIMP.3` | `gimp` | `gimp` |
| `inkscape` | Graphics | Design and media | `Inkscape.Inkscape` | `inkscape` | `inkscape` |
| `figma` | Graphics | Design and media | `Figma.Figma` | `figma` | – |
| `openvpn-client` | Network | | `OpenVPNTechnologies.OpenVPN` | `tunnelblick` | `NetworkManager-openvpn` |
| `acme-vpn` | Network | Everyone | configuration file | Tunnelblick configuration | NetworkManager connection |

All apps except `acme-vpn` use the `Furnish/Package` resource. It's bundled with furnish and installs packages with winget on Windows, Homebrew on macOS, and on Linux with the distribution's package manager or Nix. Apps marked – on Linux aren't in the distributions' own repositories; without a resource for Linux, furnish shows them as not available there.

## Configurations, not only packages

[`apps/acme-vpn.dsc.yaml`](apps/acme-vpn.dsc.yaml) sets up a VPN connection to a fictional company network. It installs no package itself. It depends on `openvpn-client`, which installs OpenVPN on Windows, Tunnelblick on macOS and NetworkManager's OpenVPN plugin on Linux. Uninstalling `acme-vpn` removes the connection and keeps the client.

All three systems use the same OpenVPN configuration. It is written once in the file, under the YAML anchor `&ovpn`, and used again as `*ovpn`:

- Windows: `Microsoft.Filesystem.File/Content` writes it to `C:\Program Files\OpenVPN\config\acme.ovpn`. People connect with OpenVPN GUI.
- macOS: `Microsoft.DSC.Transitional/RunCommandOnSet` writes a Tunnelblick configuration and installs it with Tunnelblick's installer.
- Linux: `File/Content` writes the file to `/etc/openvpn`, and `RunCommandOnSet` imports it into NetworkManager as "Acme VPN".

The configuration is an example: replace the server `vpn.acme.example` and the CA certificate with your own. It contains no private keys. People sign in with their name and password when they connect (`auth-user-pass`). The app writes to system folders, so it needs administrator rights: install it through the furnish service, from a collection your organization presets.

`File/Content` doesn't delete files, and `RunCommandOnSet` runs its command on every install. So furnish can't uninstall the app by itself. The app lists its own removal steps under `metadata.furnish.uninstall`, and furnish runs them to uninstall it:

```yaml
metadata:
  furnish:
    uninstall:
      - name: delete the NetworkManager connection
        type: Microsoft.DSC.Transitional/RunCommandOnSet
        condition: "[equals(context().os.family, 'Linux')]"
        properties:
          executable: /bin/sh
          arguments: [-c, "nmcli connection delete id 'Acme VPN' >/dev/null 2>&1; rm -f /etc/openvpn/acme-vpn.ovpn"]
```

Without removal steps, furnish wouldn't offer to uninstall the app. `File/Content` and `RunCommandOnSet` are DSC's own resources. furnish ships them, so computers don't need DSC installed.

## Package names that differ per OS

When a package has a different ID on some OS, give each variant its own resource with a DSC `condition`. furnish skips resources whose condition is false. [`apps/firefox.dsc.yaml`](apps/firefox.dsc.yaml) shows the pattern:

```yaml
resources:
  - name: firefox (winget)
    type: Furnish/Package
    condition: "[equals(context().os.family, 'Windows')]"
    properties:
      name: Mozilla.Firefox
  - name: firefox
    type: Furnish/Package
    condition: "[not(equals(context().os.family, 'Windows'))]"
    properties:
      name: firefox
```

`context().os.family` returns `Windows`, `macOS` or `Linux`.

Some package managers name a package differently. Properties such as `pacmanName` or `brewName` override `name` for one of them: [`apps/libreoffice.dsc.yaml`](apps/libreoffice.dsc.yaml) installs `libreoffice-fresh` on Arch, [`apps/7zip.dsc.yaml`](apps/7zip.dsc.yaml) `sevenzip` from Homebrew.

Apps such as [`apps/slack.dsc.yaml`](apps/slack.dsc.yaml) have a resource for Windows and one for macOS only.

## Recommendations by role

[`collection.yaml`](collection.yaml) declares the required option `role` ("What do you work on?"); furnish asks for it when the collection is added. Apps recommend themselves in `metadata.furnish.recommended`, either always (`true`, like KeePassXC) or for one role:

```yaml
metadata:
  furnish:
    recommended: "[equals(parameters('role'), 'design')]"
```

## Try it

```sh
furnish collection add git@github.com:furnish-self-service/self-service-example.git --option role=developer
furnish list
furnish install firefox
```

`furnish install` asks for your sudo password when the package manager needs root.

## Kits

Kits in [`kits/`](kits) group apps users install together. Kits reference apps of the same collection by name.

| Kit | Required | Optional, preselected | Optional, not preselected |
|---|---|---|---|
| [`office`](kits/office.yaml) | `libreoffice`, `thunderbird` | `keepassxc` | `7zip` |
| [`design-studio`](kits/design-studio.yaml) | `gimp`, `inkscape` | `figma` | |
| [`developer`](kits/developer.yaml) | `git`, `visual-studio-code` | `postman` | |

## Icons

The collection's avatar is set in [`collection.yaml`](collection.yaml), each app's in its `metadata.furnish.icon`, and each kit's in its `icon`. The icons are in [`icons/`](icons), as SVG so they stay sharp at every size.

The app icons are the vendors' and projects' own, unchanged apart from size optimization:

| Icon | Source | License |
|---|---|---|
| [`firefox.svg`](icons/firefox.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Firefox_logo,_2019.svg) | MPL-2.0 |
| [`thunderbird.svg`](icons/thunderbird.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Thunderbird_2023_icon.svg) | MPL-2.0 |
| [`libreoffice.svg`](icons/libreoffice.svg) | [LibreOffice/core](https://github.com/LibreOffice/core/blob/master/sysui/desktop/icons/hicolor/scalable/apps/main.svg) | MPL-2.0 |
| [`keepassxc.svg`](icons/keepassxc.svg) | [keepassxreboot/keepassxc](https://github.com/keepassxreboot/keepassxc/blob/develop/share/icons/application/scalable/apps/keepassxc.svg), by Lorenzo Stella | LGPL-2.0 |
| [`vlc.svg`](icons/vlc.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:VLC_Icon.svg) | GPL |
| [`git.svg`](icons/git.svg) | [git/git-scm.com](https://github.com/git/git-scm.com/blob/gh-pages/static/images/logos/downloads/Git-Icon-1788C.svg), Git Logo by Jason Long | CC-BY-3.0 |
| [`gimp.svg`](icons/gimp.svg) | [GNOME/gimp-data](https://gitlab.gnome.org/GNOME/gimp-data/-/blob/main/images/logo/gimp-logo.svg) | CC-BY-SA-4.0 |
| [`inkscape.svg`](icons/inkscape.svg) | [inkscape/inkscape](https://gitlab.com/inkscape/inkscape/-/blob/master/share/branding/inkscape.svg), by Andrew Michael Fitzsimon | CC-BY-SA-3.0 |
| [`7zip.svg`](icons/7zip.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:7-Zip_Icon.svg) | Public domain |
| [`google-chrome.svg`](icons/google-chrome.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Google_Chrome_icon_(February_2022).svg) | Public domain |
| [`slack.svg`](icons/slack.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Slack_icon_2019.svg) | Public domain |
| [`microsoft-teams.svg`](icons/microsoft-teams.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Microsoft_Office_Teams_(2025%E2%80%93present).svg) | Public domain |
| [`adobe-acrobat-reader.svg`](icons/adobe-acrobat-reader.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Adobe_Acrobat_Reader_icon_(2020).svg) | Public domain |
| [`visual-studio-code.svg`](icons/visual-studio-code.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Visual_Studio_Code_1.35_icon.svg) | Public domain |
| [`figma.svg`](icons/figma.svg) | [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Figma-logo.svg) | Public domain |
| [`postman.svg`](icons/postman.svg) | [Postman](https://voyager.postman.com/logo/postman-logo-icon-orange.svg) | Postman's own logo |

The names and logos remain trademarks of their owners; they identify the apps here.

Zoom publishes no SVG of its app icon, so `zoom.svg` was drawn after it. The collection's and the kits' icons (`collection.svg`, `office.svg`, `design-studio.svg`, `developer.svg`) and those of `acme-vpn` and `openvpn-client` were drawn for this collection (MIT).

## Add an app

1. Create `apps/<app-name>.dsc.yaml`. The file name, without `.dsc.yaml`, becomes the app's name.
2. Set `metadata.furnish.description` and `metadata.furnish.categories`. The catalog shows both. `metadata.furnish.icon` adds an icon: an SVG, PNG, JPEG or WebP file in this repository, for example in `icons/`.
3. Under `resources`, list what the app needs in the [DSC v3 configuration format](https://learn.microsoft.com/powershell/dsc/concepts/configuration-documents/overview).
4. Commit and push. Users get the app with `furnish collection update`.

For the DSC v3 rules and pitfalls, see the [authoring-dsc-v3 skill](https://github.com/furnish-self-service/furnish/blob/main/.claude/skills/authoring-dsc-v3/SKILL.md) in the furnish repository.

To check an app before you push, point furnish at your local clone:

```sh
furnish collection add /path/to/your/clone --name my-test
furnish list
```

## License

MIT, except the official app icons listed under [Icons](#icons), which keep their own licenses.
