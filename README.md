dotfiles (Unix prefs)
=====================

My Unix Config files in a centralised location

Install
-------

    $ cd ~
    $ git clone git://github.com/morganp/dotfiles.git
    $ cd dotfiles
    $ git submodule update --init
    $ ./install --help
    # If you want every thing 
    $ ./install --all

Special features
===============

Bash
----

    ls -file list with colour
    ll -file list with permissions, human redable file sizes(K M G Bytes) & Colour
    la -As ll with hidden files
    prompt in git repository $ server folder (branch)

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

 
