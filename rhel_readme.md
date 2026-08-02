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

## Login Host Labels

The Starship config displays `DOTFILES_HOST` instead of Starship's built-in
hostname module. The shell startup computes this value once when the prompt is
initialized.

For login-node FQDNs, the prompt shows the cluster or site portion rather than
the individual login node number:

```text
login01.cluster.example.com -> cluster
login02.cluster.example.com -> cluster
```

For other hosts, the prompt falls back to the short hostname.

## Bash Startup Optimisation

Keep interactive bash startup small. Expensive tool setup should happen when the
tool is first used, not every time a terminal opens.

Measure startup time before and after changes:

```bash
time bash -i -c exit
```

The unshared `~/.bashrc` should have this shape:

```bash
# Define lazy module/bootstrap wrappers first.
# See the examples below.

# Stop before local interactive setup for non-interactive shells, such as
# scp/sftp/rsync over ssh.
case $- in
  *i*) ;;
  *) return ;;
esac

# Load the shared dotfiles bash setup.
source "$HOME/dotfiles/config/shell/dot-bashrc"

# Keep machine-local aliases, tokens, project helpers, and private paths below
# this point or in another untracked local file.
```

New tmux panes start as login bash shells (`-bash`). Login bash reads
`~/.bash_profile`, not `~/.bashrc`, so keep this unshared shim as well:

```bash
if [[ -r "$HOME/.bashrc" ]]; then
  source "$HOME/.bashrc"
fi
```

On RHEL, keep module initialization in the unshared `~/.bashrc`, not in
`config/shell/dot-bashrc`. Do not eagerly run:

```bash
source /arm/tools/setup/init/bash
module load arm/cluster
```

Those two commands can dominate terminal startup. Instead, make `module` itself
lazy and let tool wrappers initialize the module stack on first use:

```bash
_dotfiles_modules_ready=0
_dotfiles_init_modules() {
  if [ "${_dotfiles_modules_ready:-0}" != 1 ]; then
    source /arm/tools/setup/init/bash
    _dotfiles_modules_ready=1
  fi
}

module() {
  unset -f module
  _dotfiles_init_modules
  module "$@"
}

_dotfiles_module_load() {
  module load "$@"
}
```

Cluster commands should also lazy-load their module:

```bash
bsub() {
  unset -f bsub
  _dotfiles_module_load arm/cluster >/dev/null 2>&1
  command bsub "$@"
}

bjobs() {
  unset -f bjobs
  _dotfiles_module_load arm/cluster >/dev/null 2>&1
  command bjobs "$@"
}

bkill() {
  unset -f bkill
  _dotfiles_module_load arm/cluster >/dev/null 2>&1
  command bkill "$@"
}
```

Prefer this pattern for module-backed tools that are not needed for every
terminal:

```bash
tmux() {
  unset -f tmux
  _dotfiles_module_load util gnu/tmux >/dev/null 2>&1
  command tmux "$@"
}

nvim() {
  unset -f nvim
  _dotfiles_module_load util neovim/neovim >/dev/null 2>&1
  command nvim "$@"
}
```

Use eager `module load` only for tools needed during shell startup itself. Good
lazy-load candidates include editors, browsers, language toolchains, waveform
tools, and other large application stacks. Keep `starship` itself on `PATH`
before prompt initialization; the prompt should not load a module on every draw.

Configure lazy-load wrappers for these RHEL module-backed tools:

```text
tmux          -> module load util  gnu/tmux
stow          -> module load util  gnu/gnustow
python        -> module load util  python/python
google-chrome -> module load util  google/google-chrome
rust/cargo    -> module load util  rust/rust
ctags         -> module load swdev universal-ctags/ctags
vim           -> module load util  vim/vim
nvim          -> module load util  neovim/neovim
```

Leave `git` eager only if the prompt or startup scripts need the module version.
Otherwise, it can use the same lazy-load pattern.

If `vim` is aliased before defining a wrapper, remove the alias first. Otherwise
bash expands the alias while parsing `vim() { ... }`:

```bash
unalias vim 2>/dev/null || true
vim() {
  unset -f vim
  _dotfiles_module_load util vim/vim >/dev/null 2>&1
  command vim -X "$@"
}
```

Use a heavier wrapper for Codex when it needs the full development toolset. This
keeps normal terminal startup fast, but gives Codex the expected tools when it
starts:

```bash
codex() {
  local codex_arg0_root active_path

  unset -f codex

  _dotfiles_module_load util  gnu/tmux >/dev/null 2>&1
  _dotfiles_module_load util  gnu/gnustow >/dev/null 2>&1
  _dotfiles_module_load util  python/python >/dev/null 2>&1
  _dotfiles_module_load util  google/google-chrome >/dev/null 2>&1
  _dotfiles_module_load util  rust/rust >/dev/null 2>&1
  _dotfiles_module_load swdev universal-ctags/ctags >/dev/null 2>&1
  _dotfiles_module_load swdev git/git >/dev/null 2>&1
  _dotfiles_module_load util  vim/vim >/dev/null 2>&1
  _dotfiles_module_load util  neovim/neovim >/dev/null 2>&1

  codex_arg0_root="${CODEX_HOME:-$HOME/.codex}/tmp/arg0"
  active_path="${PATH%%:*}"
  if [ -d "$codex_arg0_root" ]; then
    find "$codex_arg0_root" -mindepth 1 -maxdepth 1 -type d ! -path "$active_path" -exec rm -rf {} + 2>/dev/null || true
  fi

  command codex --no-alt-screen "$@"
}
```

Keep Codex-specific path cleanup and command flags inside this wrapper, so they
run only when Codex starts.

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
