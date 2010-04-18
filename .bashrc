# Morgy .bashrc

#Add Paths
export PATH=$PATH:./
export PATH=$PATH:~/bin

#Load standard ruby gem location if it exists
if [ -d $HOME/.gem/ruby/1.8/bin ] 
then 
    export PATH=$PATH:$HOME/.gem/ruby/1.8/bin
fi

# Control BASH History 
export HISTCONTROL=ignoreboth
export HISTSIZE=1000

export EDITOR=vim

LS_COLORS="no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35:"

export LS_COLORS

## BASH Prompt
## http://www-128.ibm.com/developerworks/linux/library/l-tip-prompt/
#PS1='\s-\v\$'
#PS1='\h$ '
export PS1='\[\033[01;32m\]\h \[\033[01;34m\]\W \$ \[\033[00m\]'




############################
## Standard Alias
############################
alias ll="ls -lF --color=tty"
alias ls="ls -AF --color=tty"
alias less="less -r "
alias vi="vim -X"
alias vim="vim -X"
alias n="nedit"


## Subversion Shortcuts
alias ss='svn status -u'

#dont use 'su' as that is for switching users
alias sup="echo \"svn update\" && svn update"
alias sl="echo \"svn lock\" && svn lock"
alias sc="echo \"svn commit\" && svn commit"

alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias cd-='cd -'

alias h='history'

alias reload='source ~/.bashrc'

