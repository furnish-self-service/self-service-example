# self-service-example

An example app collection for [furnish](https://github.com/furnish-self-service/furnish). Copy it as a starting point for your organization's own catalog.

## Apps in this collection

| App | Category | Recommended for | winget ID on Windows |
|---|---|---|---|
| `gimp` | Graphics, Photo | Design and media | `GIMP.GIMP.3` |
| `inkscape` | Graphics | Design and media | `Inkscape.Inkscape` |
| `krita` | Graphics | Design and media | `KDE.Krita` |
| `kdenlive` | Video | Design and media | `KDE.Kdenlive` |
| `libreoffice` | Office | Office work | `TheDocumentFoundation.LibreOffice` |
| `keepassxc` | Security | Everyone | `KeePassXCTeam.KeePassXC` |
| `git` | Development | Software development | `Git.Git` |
| `hyperfine` | Development | Software development | `sharkdp.hyperfine` |
| `htop` | System, Monitoring | Software development | not available on Windows |
| `cowsay` | Fun | nobody, it's just fun | not available on Windows |

All apps use the `Furnish/Package` resource. It's bundled with furnish and installs packages with pacman, apt, dnf, zypper, Homebrew or nix, and with winget on Windows. Every app is in the official repositories of Arch Linux, Debian, Ubuntu, Fedora and openSUSE, in Homebrew (as a formula or cask) and in nixpkgs.

## Package names that differ per OS

When a package has a different ID on some OS, give each variant its own resource with a DSC `condition`. furnish skips resources whose condition is false. [`apps/hyperfine.dsc.yaml`](apps/hyperfine.dsc.yaml) shows the pattern:

```yaml
resources:
  - name: hyperfine (winget)
    type: Furnish/Package
    condition: "[equals(context().os.family, 'Windows')]"
    properties:
      name: sharkdp.hyperfine
  - name: hyperfine
    type: Furnish/Package
    condition: "[not(equals(context().os.family, 'Windows'))]"
    properties:
      name: hyperfine
```

`context().os.family` returns `Linux`, `macOS` or `Windows`.

Some package managers name a package differently. Properties such as `pacmanName` or `nixName` override `name` for one of them: [`apps/libreoffice.dsc.yaml`](apps/libreoffice.dsc.yaml) installs `libreoffice-fresh` on Arch, [`apps/kdenlive.dsc.yaml`](apps/kdenlive.dsc.yaml) `kdePackages.kdenlive` from nixpkgs.

`htop` and `cowsay` have no Windows package, so their only resource has a Linux/macOS condition, and furnish shows them as not available on Windows.

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
furnish install cowsay
```

`furnish install` asks for your sudo password when the package manager needs root.

## Kits

Kits in [`kits/`](kits) group apps users install together. Kits reference apps of the same collection by name.

| Kit | Required | Optional, preselected | Optional, not preselected |
|---|---|---|---|
| [`terminal-basics`](kits/terminal-basics.yaml) | `htop` | `cowsay` | `hyperfine` |
| [`design-studio`](kits/design-studio.yaml) | `gimp`, `inkscape` | `krita` | |
| [`office`](kits/office.yaml) | `libreoffice`, `keepassxc` | | |

## Icons

The collection's avatar is set in [`collection.yaml`](collection.yaml), each app's in its `metadata.furnish.icon`, and each kit's in its `icon`. The icons are in [`icons/`](icons), as SVG so they stay sharp at every size.

The app icons are the projects' own, taken unchanged from their source repositories:

| Icon | Source | License |
|---|---|---|
| [`gimp.svg`](icons/gimp.svg) | [GNOME/gimp-data](https://gitlab.gnome.org/GNOME/gimp-data/-/blob/main/images/logo/gimp-logo.svg) | CC-BY-SA-4.0 |
| [`inkscape.svg`](icons/inkscape.svg) | [inkscape/inkscape](https://gitlab.com/inkscape/inkscape/-/blob/master/share/branding/inkscape.svg), by Andrew Michael Fitzsimon | CC-BY-SA-3.0 |
| [`krita.svg`](icons/krita.svg) | [graphics/krita](https://invent.kde.org/graphics/krita/-/blob/master/krita/pics/branding/default/sc-apps-krita.svgz) (unzipped) | CC-BY-SA-4.0 |
| [`kdenlive.svg`](icons/kdenlive.svg) | [multimedia/kdenlive](https://invent.kde.org/multimedia/kdenlive/-/blob/master/data/icons/sc-apps-kdenlive.svg), by Julius Künzel | LGPL-3.0-or-later |
| [`libreoffice.svg`](icons/libreoffice.svg) | [LibreOffice/core](https://github.com/LibreOffice/core/blob/master/sysui/desktop/icons/hicolor/scalable/apps/main.svg) | MPL-2.0 |
| [`keepassxc.svg`](icons/keepassxc.svg) | [keepassxreboot/keepassxc](https://github.com/keepassxreboot/keepassxc/blob/develop/share/icons/application/scalable/apps/keepassxc.svg), by Lorenzo Stella | LGPL-2.0 |
| [`git.svg`](icons/git.svg) | [git/git-scm.com](https://github.com/git/git-scm.com/blob/gh-pages/static/images/logos/downloads/Git-Icon-1788C.svg), Git Logo by Jason Long | CC-BY-3.0 |
| [`htop.svg`](icons/htop.svg) | [htop-dev/htop](https://github.com/htop-dev/htop) | GPL-2.0-or-later |

The names and logos remain trademarks of their projects; they identify the apps here.

cowsay and hyperfine have no official icon, so theirs, like the collection's and the kits' (`collection.svg`, `terminal-basics.svg`, `design-studio.svg`, `office.svg`), were drawn for this collection (MIT).

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
