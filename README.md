# self-service-example

An example app collection for [furnish](https://github.com/furnish-self-service/furnish). Copy it as a starting point for your organization's own catalog.

## Apps in this collection

| App | Category | Installs |
|---|---|---|
| `cowsay` | Fun | The `cowsay` package |
| `htop` | System, Monitoring | The `htop` package |

Both apps use the `Furnish/Package` resource. It's bundled with furnish and installs packages with pacman, apt, dnf, zypper or Homebrew.

## Try it

```sh
furnish collection add git@github.com:furnish-self-service/self-service-example.git
furnish list
furnish install cowsay
```

`furnish install` asks for your sudo password when the package manager needs root.

## Add an app

1. Create `apps/<app-name>.dsc.yaml`. The file name, without `.dsc.yaml`, becomes the app's name.
2. Set `metadata.furnish.description` and `metadata.furnish.categories`. The catalog shows both.
3. Under `resources`, list what the app needs in the [DSC v3 configuration format](https://learn.microsoft.com/powershell/dsc/concepts/configuration-documents/overview).
4. Commit and push. Users get the app with `furnish collection update`.

To check an app before you push, point furnish at your local clone:

```sh
furnish collection add /path/to/your/clone --name my-test
furnish list
```

## License

MIT
