# asdf-turmeric

[Turmeric](https://github.com/rjungemann/turmeric) compiler plugin for
[`mise`](https://mise.jdx.dev) and [`asdf`](https://asdf-vm.com).

Installs Turmeric compiler versions from the official GitHub releases and
falls back to a source build when no prebuilt asset exists for the host.
You do **not** need [`tvm`](https://github.com/rjungemann/turmeric/tree/main/tvm)
to use this plugin -- the install path is fully self-contained.

## Supported hosts

| OS    | Arch    | Prebuilt? |
| ----- | ------- | --------- |
| Linux | x86_64  | yes       |
| Linux | aarch64 | yes       |
| macOS | arm64   | yes       |
| macOS | x86_64  | source build fallback |
| other |         | source build fallback (needs `cmake` >= 3.5 and a C compiler) |

## Usage with [`mise`](https://mise.jdx.dev)

`mise` natively supports asdf-style plugins.

### Install `mise`

If you don't already have `mise`, follow
<https://mise.jdx.dev/getting-started.html>. On macOS:

```sh
brew install mise
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc      # or .bashrc
exec $SHELL
```

### Add the plugin

```sh
mise plugin install turmeric https://github.com/rjungemann/asdf-turmeric.git
```

### Install a Turmeric version

```sh
mise install turmeric@latest         # latest stable release
mise install turmeric@0.23.1         # explicit version
mise ls-remote turmeric              # list installable versions
```

### Pin a version for a project

Inside the project directory:

```sh
mise use turmeric@0.23.1
```

This writes `.mise.toml` (or appends to `.tool-versions`). After that,
`tur` on `PATH` resolves to the pinned version. The plugin exports
`TUR_STDLIB_DIR` automatically so the bundled stdlib is found without any
extra setup.

### One-off invocations

```sh
mise exec turmeric@0.23.1 -- tur --version
```

## Usage with [`asdf`](https://asdf-vm.com)

### Install `asdf`

If you don't already have `asdf`, follow <https://asdf-vm.com/guide/getting-started.html>.
On macOS:

```sh
brew install asdf
echo '. /opt/homebrew/opt/asdf/libexec/asdf.sh' >> ~/.zshrc      # or .bashrc
exec $SHELL
```

### Add the plugin

```sh
asdf plugin add turmeric https://github.com/rjungemann/asdf-turmeric.git
```

### Install a Turmeric version

```sh
asdf install turmeric latest         # latest stable release
asdf install turmeric 0.23.1         # explicit version
asdf list all turmeric               # list installable versions
```

### Pin a version

Globally:

```sh
asdf global turmeric 0.23.1
```

Per project (writes `.tool-versions` in the current directory):

```sh
asdf local turmeric 0.23.1
```

After that, `tur` on `PATH` resolves to the pinned version.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `GITHUB_TOKEN` | Optional. Lifts the 60-req/hr unauthenticated GitHub API rate limit when calling `list-all` from CI. |
| `TURMERIC_REPO` | Override the upstream repo slug (default `rjungemann/turmeric`). Useful for forks. |
| `ASDF_TURMERIC_FORCE_SOURCE` | Set to `1` to force the source-build path even when a prebuilt asset is available. Used by the plugin's CI to exercise the fallback. |

## How the plugin works

The plugin consumes the existing release contract published by the
turmeric repo. For each release `vX.Y.Z` the workflow attaches:

- `turmeric-vX.Y.Z-<os>-<arch>.tar.gz` per supported host
- `sha256sums.txt` containing one line per asset

The install script downloads the matching tarball, verifies it against
`sha256sums.txt`, extracts it, and normalizes the layout to
`<install>/bin/tur` + `<install>/stdlib/`. When no prebuilt tarball exists
for the host (e.g. macOS x86_64 today), it falls back to building from the
source tarball.

`tvm` and this plugin are independent installers that consume the same
release artifacts -- you only need one of them.

## License

MIT. See [LICENSE](LICENSE).
