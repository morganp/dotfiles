dotfiles (Unix prefs)
=====================

MacOS/*nix config files in a central location.


ZSH
---

Portable Zsh setup lives in `config/shell/dot-zprofile`. Keep machine-local or
internal configuration in `~/.zprofile`, and source the tracked configuration
first:

    source "$HOME/dotfiles/config/shell/dot-zprofile"

The local file is intentionally not linked by `run_stow`; on this machine it
also contains the internal Codex updater and architecture-specific Codex path.
API keys remain in `~/.config/codex/env` and are never stored in this repository.

`~/.zshrc` delegates interactive non-login shells to the same configuration
without loading login shells twice, and sets the prompt:

    if [[ ! -o login ]]; then
      source "$HOME/.zprofile"
    fi

    source "$HOME/dotfiles/config/shell/dot-zprompt"

The prompt has to be initialised from `~/.zshrc`, not `~/.zprofile`. Zsh reads
`~/.zprofile`, then `/etc/zshrc`, then `~/.zshrc`, and the macOS `/etc/zshrc`
sets `PS1="%n@%m %1~ %# "`. A prompt configured in `~/.zprofile` is silently
discarded in every login shell, which is what a new terminal window opens.

Oh My Zsh has no Homebrew formula, so install it separately:

    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

The `git` plugin is bundled with Oh My Zsh. The Starship prompt,
`zsh-autosuggestions`, and `zsh-syntax-highlighting` are installed through the
Brewfile below. Starship is configured in `config/starship/starship.toml`, which
`run_stow` links to `~/.config/starship.toml`; it keeps the minimal prompt order
(user, dir, git, line break, char) that the setup used previously. The right
left prompt opens with the OS and its major.minor version and the hostname, so
a shell on a remote RHEL box is distinguishable at a glance. Starship's own `os`
module reports a name but no version, so `dot-zprompt` builds the label once per
shell and exports it as `DOTFILES_OS` for the `env_var` module to read. It
parses `/etc/os-release` on Linux and `SystemVersion.plist` on macOS with zsh
builtins, costing about 1.4ms; `sw_vers` would cost 13ms per call, and a
starship `custom` module would pay that on every redraw. The right
prompt carries transient detail about the command that just ran: exit status,
backgrounded job count, duration once it exceeds 500ms, and the clock.
`dot-zprompt` sets `TRANSIENT_RPROMPT` so that detail is erased from earlier
lines, leaving scrollback with only commands and their output. The prompt is
initialised by `config/shell/dot-zprompt`, sourced from `~/.zshrc`.
The Brewfile also installs Victor Mono Nerd Font for the prompt glyphs.

Vim
-
~/vimrc source dotfiles

    so ~/dotfiles/config/vim/dot-vimrc_clean


All configs live under `config/`. Stow targets operate from that directory.
Submodules (e.g. skillbook) live under `config/shared/`.

The Rest can be linked with stow, and homebrew to manage packages

Tmux
--

Tmux uses the `$XDG_CONFIG_HOME` variable, which is set in config/shell/dot-profile

    $XDG_CONFIG_HOME/tmux/tmux.conf

For the tmux plugin manager, clone to this area:

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

Packages (brew)
--

Install homebrew

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Install Brew packages (includes Stow)

    brew bundle install --file=~/dotfiles/config/brew/Brewfile

The Rest
--

Link the remaining dot files using run_stow

    cd ~/dotfiles/config
    run_stow

Example of run_stow:

    cd ~/dotfiles/config
    stow git --dotfiles -t ~/
    stow input --dotfiles -t ~/
    stow screen --dotfiles -t ~/

AI skills are managed as a submodule at `config/shared/skillbook`.
`run_stow` initializes that submodule and creates `~/.codex/skills` and
`~/.claude/skills` pointing there directly.
    




Moving to a modern setup, copying structure from [ericsmacedo][em-dot].

[em-dot]: https://github.com/ericsmacedo/dotfiles/tree/master





features
=========

Shell (Bash & ZSH)
----

    ls : file list with colour
    ll : file list with permissions, human redable file sizes(K M G Bytes) & Colour
    la : As ll with hidden files
    lt : ls but using tree
    .. Up a directory

Screen
------

    Virtual tabs across the bottom of screen (in normal colours).

Inputrc 
-------

    Tab completion, not case sensitive.
    Tab completion works with hidden files.

 
