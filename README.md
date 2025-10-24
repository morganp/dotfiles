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





Moving to a modern setup, copying structure from [ericsmacedo][em-dot].

[em-dot]: https://github.com/ericsmacedo/dotfiles/tree/master





OLD VERSION
==

Install
-------

    $ cd ~
    $ git clone git://github.com/morganp/dotfiles.git
    $ cd dotfiles
    $ bin/create-hook-symlinks ## Optional links to a post-merge hook to remind about submodule update
    $ git submodule update --init
   
Installer commands, have not been maintained :

    $ ./install --help
    # If you want every thing 
    $ ./install --all

Manual usage

Make you ~/.zshrc ~/.bashrc ~/.vimrc source the versions in ~/dotfiles/dotfile/


Special features
===============

Bash
----

    ls -file list with colour
    ll -file list with permissions, human redable file sizes(K M G Bytes) & Colour
    la -As ll with hidden files
    prompt in git repository $ server folder (branch)
    .. Up a directory

Vim
---

    jk       - Escape sequence
    ;g       - Reindent file (keeping line position)
    ir_black - Colour scheme
    TODO     - Keyword highlighting
    red background after 80 characters

Screen
------

    Virtual tabs across the bottom of screen (in normal colours).

Inputrc 
-------

    Tab completion, not case sensitive.
    Tab completion works with hidden files.

 
