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
  # Default
  #PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
  PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin
  #PATH=/bin:~/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/texbin:/usr/X11/bin
fi

#Bash functions to only add path if not on $PATH
pre_add_path() {
  if [ -s "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}
post_add_path() {
  if [ -s "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$PATH:$1"
  fi
}


# usage 
# $ check_env_var foobar
function check_env_var()
{

  #VAR is then name of the variable to look for
  VAR=$1
  eval test=\${$VAR}

  if [ "$test" == "" ]
  then
    echo "Enviroment Variable $VAR has not been set"
    echo "  enter value then press return"
    #CAPTURE='test'
    read -e CAPTURE

    # Set it now in the Enviroment
    export $VAR=$CAPTURE

    # Add to bashrc so will it be set next time
    echo "export $VAR=$CAPTURE"  >> ~/.bashrc

    #return $CAPTURE
  else
    echo "$VAR is set to $test"
    #return $test
  fi

}



#Add Paths
post_add_path .
post_add_path ~/bin
post_add_path ~/dotfiles/bin

# Control BASH History
export HISTCONTROL=ignoreboth
export HISTSIZE=1000

## Bash History from : http://briancarper.net/blog/248/
shopt -s histappend
# Using this all terminals will have there history in sync
# Not sure if this is nice, will not apply to ssh session etc.
# but will keep local history in ordered by absolute time.
#export PROMPT_COMMAND="history -n; history -a"
export PROMPT_COMMAND="history -a"


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

#Trying this out Escape character to return to the begining of the line
#http://jonisalonen.com/2012/your-bash-prompt-needs-this/
export PS1="\[\033[G\]$PS1"


############################
## Standard Alias
############################
alias less="less -r "
alias vi="vim -X"
alias vim="vim -X"
alias n="nedit"


## Subversion Shortcuts
alias ss='svn status -u'
#dont use 'su' as that is for switching users
alias sup='svn update'
alias sp='svn update'
alias sl='svn lock'
alias sc='svn commit'

## Git Shortcuts (http://barkingiguana.com/2010/07/07/my-dot-files-dot-aliases/)
alias g='git'
alias gs='git status'
alias gc='git commit'
alias gca='git commit -a'
alias gup='git pull'
alias gp='git pull'
alias ga='git add'
alias gco='git checkout'
alias gb='git branch'
alias gm='git merge'
alias gd='git diff'
alias gl='git log --graph --pretty="format:%C(yellow)%h%Cblue%d%Creset %s %C(white) %an, %ar%Creset"'



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

#http://twistedcode.blogspot.com/2008/04/lscolors-explained.html#!/2008/04/lscolors-explained.html
#export LS_COLORS="no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35:"

#fi file
#di Directory
#ln Link
#ex Executable has unix x set
#setenv LS_COLORS "fi=00:di=01;94:ln=00;36:ex=00;91:"
export LS_COLORS="fi=00:di=01;94:ln=00;36:ex=00;91:"

# Stuff for RVM Ruby version manager
# http://rvm.beginrescueend.com/
# install with $ bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
