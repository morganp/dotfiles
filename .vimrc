
"~/.vimrc should be a link here or contain the following:
"so ~/.unix_config/.vimrc

set scrolloff=3
syntax on
syntax enable
set number

set showmatch
set showmode


set nocompatible	" Use Vim defaults instead of 100% vi compatibility
set backspace=indent,eol,start	" more powerful backspacing
set history=50         " keep 50 lines of command line history
set ruler              " show the cursor position all the time
set expandtab          " spaces are used instead of tabs
set autoindent         " always set autoindenting on
set tabstop=3          " number of spaces inserted when tab is hit
set shiftwidth=3       " used with autoindent (should equal tabstop)
set softtabstop=3      " if set below tabstop will insert this many spaces (when greater then tab will convert to tab) 

"Set wrapping  http://vimcasts.org/e/16
" NB list shows white space byt breaks linebreak
set wrap linebreak nolist


" Setting upo the status line along the bottom
set showcmd          " Always show command line in the status
set ch=2             " Command line 2 lines high
set ls=2             " Status 2 lines high

" Now we set some defaults for the editor
" set linebreak		" Don't wrap words by default
" set textwidth=0		" Don't wrap lines by default
" set nobackup		   " Don't keep a backup file
set viminfo='20,\"50	" read/write a .viminfo file, don't store more than
			" 50 lines of registers
         " 
" Spelling Corrections
ab teh the
ab fro for



" Format the statusline
set statusline=%<%f\ %h%m%r%=%{getcwd()}\ \ \ %-14.(%l,%c%V%)\ %P


" Suffixes that get lower priority when doing tab completion for filenames.
" These are files we are not likely to want to edit or read.
"set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc

" We know xterm-debian is a color terminal
"if &term =~ "xterm-debian" || &term =~ "xterm-xfree86"
"  set t_Co=16
"  set t_Sf=[3%dm
"  set t_Sb=[4%dm
"endif

" Set color stuff
" " t_Co=16 becuase t_Co=8 disalbes bold font
if &term =~ "xterm"
   if has("terminfo")
      set t_Co=16
      set t_Sf=^[[3%pl%dm
      set t_Sb=^[[4%pl%dm
   else
      set t_Co=16
      set t_Sf=^[[3%dm
      set t_Sb=^[[4%dm
   endif
   set mouse=a
endif

set mouse=a

" Set nice colors
" 0: Black
" 1: Red
" 2: Green
" 3: Orange
" 4: Blue
" 5: Magenta
" 6: Cyan
" 7: White
set background=dark
highlight clear

highlight Normal              cterm=NONE      ctermfg=2          ctermbg=0
highlight Statement           cterm=bold      ctermfg=7          ctermbg=0
highlight StatementInclude    cterm=bold      ctermfg=7          ctermbg=0
highlight Comment             cterm=NONE      ctermfg=6          ctermbg=0
highlight PreProc             cterm=NONE      ctermfg=5          ctermbg=0

highlight StatusLine          cterm=bold      ctermfg=0          ctermbg=7
highlight NonText                                                ctermbg=0
highlight Constant            cterm=NONE      ctermfg=3          ctermbg=0
highlight Special             cterm=NONE      ctermfg=7          ctermbg=0
highlight ModeMsg             cterm=bold      ctermfg=0          ctermbg=7

highlight StatusLine          cterm=NONE      ctermfg=0          ctermbg=7
highlight StatusLineNC        cterm=NONE      ctermfg=DarkGray   ctermbg=7

highlight Cursor              cterm=reverse   ctermfg=2          ctermbg=2
highlight iCursor             cterm=reverse   ctermfg=3          ctermbg=3

highlight Visual              cterm=NONE      ctermfg=0          ctermbg=7
highlight IncSearch           cterm=reverse   ctermfg=2          ctermbg=0
highlight Search              cterm=reverse   ctermfg=2          ctermbg=0
highlight MatchParen          cterm=NONE      ctermfg=4          ctermbg=0
highlight Pmenu               cterm=NONE      ctermfg=darkgrey   ctermbg=lightgrey
highlight PmenuSel            cterm=NONE      ctermfg=white      ctermbg=darkgrey

highlight Error               cterm=NONE      ctermfg=0          ctermbg=4
highlight Todo                cterm=NONE      ctermfg=0          ctermbg=4

highlight Type                cterm=NONE      ctermfg=7          ctermbg=0
highlight Identifier          cterm=NONE      ctermfg=1          ctermbg=0

highlight LineLenWarn         cterm=NONE      ctermfg=1          ctermbg=0

"Warn with subttle background colours when over 80 chars long
highlight OverLength ctermbg=red ctermfg=white guibg=#592929 
match OverLength /\%81v.\+/


"Somthing in the above does not work well with gvim
colorscheme torte


augroup cprog
  " Remove all cprog autocommands
  au!

  " When starting to edit a file:
  "    For *.c and *.h files set formatting of comments and set C-indenting on.
  "    For other files switch it off.
  "    Don't change the order, it's important that the line with * comes first.
  autocmd BufRead * set formatoptions=tcql nocindent comments&
  " autocmd BufRead *.c,*.h set formatoptions=croql cindent comments=sr:/*,mb:*,el:*/,://
  " File types
  au BufNewFile,BufRead *.v,*.vh,*.args,*.f,*.verilog,*.v_[A-Za-z0-9_]*,*.v.* set ft=verilog
augroup END

au BufNewFile,BufRead *.va,*.vams set ft=verilogams
au BufNewFile,BufRead *.sv, set ft=verilog

" Make p in Visual mode replace the selected text with the "" register.
"vnoremap p <Esc>:let current_reg = @"<CR>gvdi<C-R>=current_reg<CR><Esc>

"if has("autocmd")
 " Enabled file type detection
 " Use the default filetype settings. If you also want to load indent files
 " to automatically do language-dependent indenting add 'indent' as well.
" filetype plugin on
"endif " has ("autocmd")


" The following are commented out as they cause vim to behave a lot
" different from regular vi. They are highly recommended though.
set showcmd		   " Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set incsearch		" Incremental search
set autowrite		" Automatically save before commands like :next and :make

" Source a global configuration file if available
"if filereadable("/etc/vimrc")
"  source /etc/vimrc
"endif

map <D-S-]> gt
map <D-S-[> gT
map <D-0> :tablast<CR>

"get NerdTree
" http://www.vim.org/scripts/script.php?script_id=1658
"TODO add check if NERDTree plugin is in place
"Load NERDTree and put cursor in other window
autocmd VimEnter * NERDTree
autocmd VimEnter * wincmd p

