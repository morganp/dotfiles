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
without loading login shells twice:

    if [[ ! -o login ]]; then
      source "$HOME/.zprofile"
    fi

Oh My Zsh has no Homebrew formula, so install it separately:

    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

The `git` plugin is bundled with Oh My Zsh. The Spaceship prompt,
`zsh-autosuggestions`, and `zsh-syntax-highlighting` are installed through the
Brewfile below. Spaceship uses the optimized prompt order from
[Scott Spence's Zsh setup](https://scottspence.com/posts/speeding-up-my-zsh-shell).
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

 
