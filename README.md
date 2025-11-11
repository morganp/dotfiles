dotfiles (Unix prefs)
=====================

unix config files in a central location.

~/.zshrc can load dotfiles

    source ~/dotfiles/config/shell/dot-zshrc

~/vimrc can load dotfiles

    so ~/dotfiles/config/vim/dot-vimrc_clean

Others can be linked with stow

    cd ~/dotfiles/config
    stow git --dotfiles -t ~/
    stow input --dotfiles -t ~/
    stow screen --dotfiles -t ~/
    stow tmux --dotfiles -t ~/




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

 
