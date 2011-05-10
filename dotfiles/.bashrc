# .bashrc

############################
## Load Files if Present
############################

#if [ -f ~/.unix_config/.bashrc ];
#then
# source ~/.unix_config/.bashrc
#fi
#
#if [ -f ~/.unix_config/.bashrc_work ];
#then
# source ~/.unix_config/.bashrc_work
#fi
#
#if [ -f ~/.unix_config/.bashrc_mac ];
#then
# source ~/.unix_config/.bashrc_mac
#fi
#
#if [ -f ~/.unix_config/.bashrc_webfaction ];
#then
# source ~/.unix_config/.bashrc_webfaction
#fi

#get ssh completion
#source ~/.unix_config/.ssh-completion

if [[ "$unamestr" == 'Darwin' ]]; then
  PATH=/bin:~/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/texbin:/usr/X11/bin
fi

#Bash functions to only add path if not on $PATH
pre_add_path() {
  if [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}
post_add_path() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$PATH:$1"
  fi
}

#Add Paths
post_add_path ./
post_add_path ~/bin

# Control BASH History
export HISTCONTROL=ignoreboth
export HISTSIZE=1000

export EDITOR=vim


## BASH Prompt
## http://www-128.ibm.com/developerworks/linux/library/l-tip-prompt/
## Colours from
## http://www.marksanborn.net/linux/adding-color-and-customize-the-bash-prompt-ps1/
#PS1='\s-\v\$'
#PS1='\h$ '

ps_lgreen='\[\033[01;32m\]'
ps_lblue='\[\033[01;34m\]'
ps_lred='\[\033[01;31m\]'

export PS1='\[\033[01;32m\]\h \[\033[01;34m\]\W' #\$ \[\033[00m\]'

#Added git to status line
export PS1=$PS1"\$(git branch 2>/dev/null | grep '^*' | colrm 1 2 | xargs -I {} echo ' (\[\033[01;31m\]'{}'\[\033[01;34m\])')"
export PS1=$PS1" \$ \[\033[00m\]"



############################
## Standard Alias
############################
alias less="less -r "
alias vi="vim -X"
alias vim="vim -X"
alias n="nedit"


## Subversion Shortcuts
alias ss='svn status -u'
alias gs='git status'

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

#http://stackoverflow.com/questions/394230/detect-os-from-a-bash-script
unamestr=`uname`
gnu=false
bsd=false

if [[ "$unamestr" == 'Linux' ]]; then
  gnu=true
elif [[ "$unamestr" == 'FreeBSD' ]]; then
  bsd=true
elif [[ "$unamestr" == 'Darwin' ]]; then
  bsd=true
fi

#echo '## LS info ##'
#echo `which ls`
#echo `type ls`

if [[ $gnu == true ]]; then
  alias la="ls -laFh --color=tty"
  alias ll="ls -lFh --color=tty"
  alias ls="ls -Fh --color=tty"
elif [[ $bsd == true ]]; then 
  # Colour ls
  export CLICOLOR=1
  alias la="ls -lFhA"
  alias ll="ls -lFh"
  alias ls="ls -Fh"
else 
  echo "/n/nOS type not recognised form uname ls not setup correctly"
fi

export LS_COLORS="no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35:"

#export LS_COLORS="dxfxcxdxbxegedabagacad"


