# self-service-example

An example app collection for [furnish](https://github.com/furnish-self-service/furnish). Copy it as a starting point for your organization's own catalog.

## Apps in this collection

| App | Category | Installs |
|---|---|---|
| `cowsay` | Fun | The `cowsay` package |
| `htop` | System, Monitoring | The `htop` package |
| `hyperfine` | Development | `hyperfine`, or `sharkdp.hyperfine` from winget on Windows |

All apps use the `Furnish/Package` resource. It's bundled with furnish and installs packages with pacman, apt, dnf, zypper, Homebrew or nix, and with winget on Windows.

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

## Try it

```sh
furnish collection add git@github.com:furnish-self-service/self-service-example.git
furnish list
furnish install cowsay
```

`furnish install` asks for your sudo password when the package manager needs root.

## Kits

[`kits/terminal-basics.yaml`](kits/terminal-basics.yaml) groups apps users install together. `htop` is required; `cowsay` is preselected and `hyperfine` isn't, and users can change both. Kits reference apps of the same collection by name.

## Icons

The collection's avatar is set in [`collection.yaml`](collection.yaml), each app's in its `metadata.furnish.icon`, and the kit's in its `icon`. The icons are in [`icons/`](icons), as SVG so they stay sharp at every size. [`htop.svg`](icons/htop.svg) is htop's own icon (from [htop-dev/htop](https://github.com/htop-dev/htop), GPL-2.0-or-later); cowsay and hyperfine have no official icon, so theirs, like the collection's and the kit's, were drawn for this collection (MIT).

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

MIT
