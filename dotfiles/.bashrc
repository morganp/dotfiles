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

if [[ `uname` == 'Darwin' ]]; then
  # Default
  #Mountain Lion
  #PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin
  
  ## Mavericks
  # Set architecture flags
  export ARCHFLAGS="-arch x86_64"
  # Ensure user-installed binaries take precedence
  PATH=/usr/local/bin:$PATH
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

## Adding 256 color support to terminals
##  Mainly for command line vim
if [[ "$TERM" != *256color* ]]
then
  export TERM=$TERM-256color
fi

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
alias h='history'

## Subversion Shortcuts
alias ss='svn status -u'
alias sup='svn update'

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


## Cd Shortcuts
alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias cd-='cd -'
alias --='cd -'


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
  alias ls="ls --color=tty"
elif [[ $bsd == true ]]; then 
  # Colour ls
  export CLICOLOR=1
  alias la="ls -lFhA"
  alias ll="ls -lFh"
  alias ls="ls "
else 
  echo "/n/nOS type not recognised form uname ls not setup correctly"
fi

#http://twistedcode.blogspot.com/2008/04/lscolors-explained.html#!/2008/04/lscolors-explained.html
#fi file
#di Directory
#ln Link
#ex Executable has unix x set
export LS_COLORS="fi=00:di=01;94:ln=00;36:ex=00;91:"

# Stuff for RVM Ruby version manager
# http://rvm.beginrescueend.com/
# install with $ bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

## brew install bash-completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi
