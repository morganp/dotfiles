#Standard Exports and Alias for Bash and ZSH

############################
## Perforce Alias
############################
export P4CONFIG=.p4config
export P4MERGE=p4merge
export P4IGNORE=.p4ignore
export P4EDITOR=vim

export EDITOR=vim

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

# Setting up icloud backup python script
alias icloud-download="ICLOUD_EMAIL=morgan.prior@gmail.com /Users/morgan/Documents/Code/icloud-download/icloud-download.py"


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
alias lt="tree -L 1"


#http://twistedcode.blogspot.com/2008/04/lscolors-explained.html#!/2008/04/lscolors-explained.html
#fi file
#di Directory
#ln Link
#ex Executable has unix x set
export LS_COLORS="fi=00:di=01;94:ln=00;36:ex=00;91:"


