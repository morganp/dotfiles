# RHEL setup

## Starship

Install Starship into the user-local bin directory:

```bash
mkdir -p "$HOME/.local/bin"
curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y
```

Verify the binary:

```bash
command -v starship
starship --version
```

Link the shared Starship config into `~/.config` with GNU Stow. On Arm RHEL
systems, `stow` is available from the `gnu/gnustow` module:

```bash
source /arm/tools/setup/init/bash
module load util gnu/gnustow

cd "$HOME/dotfiles/config"
stow starship -t "$HOME/.config"
```

Verify the config link:

```bash
ls -l "$HOME/.config/starship.toml"
```

For bash, initialize Starship from `config/shell/dot-bashrc`:

```bash
if [[ $- == *i* ]] && command -v starship >/dev/null 2>&1; then
  if [[ -r "$HOME/.config/starship.local.toml" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship.local.toml"
  fi
  eval "$(starship init bash)"
fi
```

## Private Starship Paths

Do not commit internal project paths or project-code aliases to
`config/starship/starship.toml`. Keep those mappings in a local-only override:

```bash
cp "$HOME/dotfiles/config/starship/starship.toml" \
  "$HOME/.config/starship.local.toml"
chmod 600 "$HOME/.config/starship.local.toml"
```

Add private path mappings to the local file under `[directory.substitutions]`.
The tracked bash setup automatically uses this file when it exists:

```bash
export STARSHIP_CONFIG="$HOME/.config/starship.local.toml"
```

Start a new terminal or reload bash:

```bash
source "$HOME/.bashrc"
```

## VictorMono Nerd Font

Install the VictorMono Nerd Font user-locally:

```bash
font_dir="$HOME/.local/share/fonts/VictorMonoNerdFont"
tmp_dir="$(mktemp -d)"

mkdir -p "$font_dir"
curl -fL --retry 3 \
  -o "$tmp_dir/VictorMono.tar.xz" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/VictorMono.tar.xz"

tar -xJf "$tmp_dir/VictorMono.tar.xz" -C "$font_dir"
fc-cache -f "$font_dir"
```

This RHEL environment sets `XDG_DATA_HOME=$HOME/dotfiles/data`, so fontconfig
does not search plain `~/.local/share/fonts` by default. Expose the font through
the legacy `~/.fonts` directory and rebuild the default cache:

```bash
mkdir -p "$HOME/.fonts"
ln -sfn "$HOME/.local/share/fonts/VictorMonoNerdFont" \
  "$HOME/.fonts/VictorMonoNerdFont"

fc-cache -fv
```

Verify that fontconfig can see the font:

```bash
fc-match "VictorMono Nerd Font"
fc-match "VictorMono Nerd Font Mono"
fc-list | rg -i "VictorMono|Victor Mono"
```

Set the terminal font to one of these family names:

```text
VictorMono Nerd Font
VictorMono Nerd Font Mono
```
