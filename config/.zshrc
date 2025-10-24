# Morgan centralised .zshrc

alias mergepdfs="gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=merged.pdf *.pdf"

#Setup Homebrew Path
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/Users/morgan/.local/bin:$PATH"

#Shell Specific Reload Commmand
alias reload="source ~/.zshrc"

# Tab for auto-complete
# https://stackoverflow.com/a/66363252/97073
bindkey '^I' expand-or-complete

# Completion
autoload -U compinit
compinit -i

source ~/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh

#History
SAVEHIST=5000
HISTSIZE=5000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE

# Standard Aliases for Bash and zsh
# https://stackoverflow.com/questions/764600/how-can-you-export-your-bashrc-to-zshrc
[[ -e ~/dotfiles/dotfiles/.profile ]] && emulate sh -c 'source ~/dotfiles/dotfiles/.profile' 

