# .bashrc

############################
## Load Files if Present
############################

#if [ -f ~/.unix_config/.bashrc ];
#then
# source ~/.unix_config/.bashrc
#fi

#get ssh completion
#source ~/.unix_config/.ssh-completion

if [[ `uname` == 'Darwin' ]]; then
  # Default
  #Mountain Lion
  #PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin
  #scutil --set HostName name-of-host

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

# Change max size of Core files
ulimit -c 0

# Ensure the umask is private even if you have a uid >99 and a
# personal group as your primary gid
umask 0022


## Bash History from : http://briancarper.net/blog/248/
shopt -s histappend
# Using this all terminals will have there history in sync
# Not sure if this is nice, will not apply to ssh session etc.
# but will keep local history in ordered by absolute time.
export PROMPT_COMMAND="history -a"




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

ps_lgreen='\[\033[01;32m\]'
ps_lblue='\[\033[01;34m\]'
ps_lred='\[\033[01;31m\]'

export PS1='\[\033[01;32m\]\h \[\033[01;34m\]\W' #\$ \[\033[00m\]'

#Added git to status line
export PS1=$PS1"\$(git branch 2>/dev/null | grep '^*' | colrm 1 2 | xargs -I {} echo ' (\[\033[01;31m\]'{}'\[\033[01;34m\])')"
export PS1=$PS1" \$ \[\033[00m\]"

#Trying this out Escape character to return to the beginning of the line
#http://jonisalonen.com/2012/your-bash-prompt-needs-this/
export PS1="\[\033[G\]$PS1"

function mace(){
  echo -en "\033]0;$1\a"
  # Changing from $1 to "$@" to capture the -w workspace options
  ace "$@"
  #stream=`p4 -F %Stream% -ztag client -o`
  #echo -en "\033]0;$1-$stream\a"
  echo -en "\033]0;$1 ($VARIANT)\a"
  ## Default PS1 looks like ss_dac_nicholls [morgan@ediws102 dev-burns-2]$
  PS1='\[\e[1m\]$PROJ\[\e[0m\] ($VARIANT) \W $ '
}


#Load standard Exports and Alias
source '~/dotfiles/dotfiles/.profile'

alias reload='source ~/.bashrc'


# Stuff for RVM Ruby version manager
# http://rvm.beginrescueend.com/
# install with $ bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

## brew install bash-completion
if [[ "$unamestr" == 'Darwin' ]]; then
  if [ -f $(brew --prefix)/etc/bash_completion ]; then
      . $(brew --prefix)/etc/bash_completion
  fi
  #Set default brew app folder to Users Applications 
  export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
fi
