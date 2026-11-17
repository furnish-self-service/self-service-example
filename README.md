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
| `acme-git-ssh` | Development | Software development | SSH configuration | SSH configuration | SSH configuration |
| `acme-vscode-proxy` | Development, Network | Software development | VS Code setting | VS Code setting | VS Code setting |

The apps that install software use the `Furnish/Package` resource. It's bundled with furnish and installs packages with winget on Windows, Homebrew on macOS, and on Linux with the distribution's package manager or Nix. Apps marked – on Linux aren't in the distributions' own repositories; without a resource for Linux, furnish shows them as not available there. The three `acme-` apps install no software. They set up configuration for a fictional company with furnish's configuration resources.

## Configurations, not only packages

furnish's configuration resources write folders, files, single lines and single values, and run commands for settings that a tool applies itself. Each of them can also remove what it set up, so uninstalling an app made of them needs no extra steps. Paths that start with `~/` lead to the home folder on every system.

### A VPN connection

[`apps/acme-vpn.dsc.yaml`](apps/acme-vpn.dsc.yaml) sets up a VPN connection to a fictional company network. It installs no package itself. It depends on `openvpn-client`, which installs OpenVPN on Windows, Tunnelblick on macOS and NetworkManager's OpenVPN plugin on Linux. Uninstalling `acme-vpn` removes the connection and keeps the client.

All three systems use the same OpenVPN configuration, [`files/acme.ovpn`](files/acme.ovpn). `Furnish/File` copies it from the collection with `source`:

- Windows: `Furnish/File` writes it to `C:\Program Files\OpenVPN\config\acme.ovpn`. People connect with OpenVPN GUI.
- macOS: `Furnish/Directory` and `Furnish/File` write it to `/Library/Application Support/Acme VPN`. `Furnish/Command` builds a Tunnelblick configuration from it and installs it with Tunnelblick's installer, tells from the files' dates whether Tunnelblick has the current version, and deletes it on uninstall.
- Linux: `Furnish/File` writes the file to `/etc/openvpn`. `Furnish/Command` imports it into NetworkManager as "Acme VPN" and deletes it on uninstall. Users can't read NetworkManager's connection files, so after each import the command writes a stamp file with the profile's date. Its test checks with `nmcli` that the connection exists and that the profile isn't newer than the stamp, so a changed profile is imported again.

```yaml
- name: NetworkManager connection
  type: Furnish/Command
  condition: "[equals(context().os.family, 'Linux')]"
  properties:
    test:
      command: [/bin/sh, -c, "test \"$(nmcli -g connection.id connection show id 'Acme VPN')\" = 'Acme VPN' && ..."]
    set: [/bin/sh, -c, "nmcli connection import type openvpn file /etc/openvpn/acme-vpn.ovpn && ..."]
    remove: [/bin/sh, -c, "nmcli connection delete id 'Acme VPN' && ..."]
```

The configuration is an example: replace the server `vpn.acme.example` and the CA certificate with your own. It contains no private keys. People sign in with their name and password when they connect (`auth-user-pass`). The app writes to system folders, so it needs administrator rights. People install it through the furnish service, from a collection your organization presets. On macOS the service installs Tunnelblick with Homebrew, as the administrator account that owns Homebrew; see [macOS: the service and Homebrew](https://github.com/furnish-self-service/furnish/blob/main/docs/site/admins.md#macos-the-service-and-homebrew).

### SSH access to a Git server

[`apps/acme-git-ssh.dsc.yaml`](apps/acme-git-ssh.dsc.yaml) sets up SSH for the fictional Git server `git.acme.example` in the user's home folder. `Furnish/File` writes the server's settings to `~/.ssh/config.d/acme.conf` and its host key to `~/.ssh/acme_known_hosts`. `Furnish/Line` adds `Include config.d/acme.conf` to `~/.ssh/config`, before the first `Host` or `Match` line, because ssh ignores an `Include` after them. Lines that people wrote themselves stay as they are. Before a file changes, `validate` runs `ssh -G` on the new version, and a file that ssh rejects stays as it was:

```yaml
- name: Include in the SSH configuration
  type: Furnish/Line
  properties:
    path: ~/.ssh/config
    line: Include config.d/acme.conf
    before: '^\s*(Host|Match)\s'
    validate: [ssh, -G, -F, '%s', git.acme.example]
```

### One setting in an editor

[`apps/acme-vscode-proxy.dsc.yaml`](apps/acme-vscode-proxy.dsc.yaml) sets the proxy in Visual Studio Code's `settings.json`. `Furnish/Value` changes the one value and keeps the person's other settings and their comments. If someone changes the proxy by hand, furnish shows an update, and installing it again sets the proxy back. Uninstalling removes only this setting.

```yaml
- name: VS Code proxy (Linux)
  type: Furnish/Value
  condition: "[equals(context().os.family, 'Linux')]"
  properties:
    path: ~/.config/Code/User/settings.json
    format: jsonc
    location: "$['http.proxy']"
    value: http://proxy.acme.example:8080
```

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

## Translations

[`locales/de.yaml`](locales/de.yaml) translates the collection into German: app descriptions, categories, kits, and the role question with its answers. furnish shows these texts to people who use furnish in German. Everyone else sees the English texts from the app and kit files.

To add a language, create `locales/<lang>.yaml` with a language tag such as `fr` or `pt-BR`, and translate as much as you like. Texts you leave out show in the person's fallback language if the collection has it, otherwise in English. `furnish check` warns about names in the file that the collection doesn't have, and counts what is translated.

Apps and kits also have display names: `metadata.furnish.name` in an app file, `name` in a kit file. furnish shows "Google Chrome" for `google-chrome`. Commands, kits and dependencies keep using the file name.

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

Zoom publishes no SVG of its app icon, so `zoom.svg` was drawn after it. The collection's and the kits' icons (`collection.svg`, `office.svg`, `design-studio.svg`, `developer.svg`) and those of `acme-vpn`, `acme-git-ssh`, `acme-vscode-proxy` and `openvpn-client` were drawn for this collection (MIT).

## Add an app

1. Create `apps/<app-name>.dsc.yaml`. The file name, without `.dsc.yaml`, becomes the app's ID, which commands use.
2. Set `metadata.furnish.name`, `metadata.furnish.description` and `metadata.furnish.categories`. The catalog shows them. Add the German description to [`locales/de.yaml`](locales/de.yaml). `metadata.furnish.icon` adds an icon: an SVG, PNG, JPEG or WebP file in this repository, for example in `icons/`.
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
