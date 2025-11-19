dotfiles (Unix prefs)
=====================

MacOS/*nix config files in a central location.


ZSH
--
~/.zshrc source dotfiles:

    source ~/dotfiles/config/shell/dot-zshrc

Vim
-
~/vimrc source dotfiles

    so ~/dotfiles/config/vim/dot-vimrc_clean


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

    brew bundle install --file=~/dotfiels/config/brew

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

 
