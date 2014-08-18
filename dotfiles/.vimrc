"~/.vimrc should be a link here or contain the following:
"so ~/.unix_config/.vimrc

" This has been checked on:
" RHEL4     gvim TODO 
" RHEL4      vim DONE
" RHEL5     gvim DONE 
" RHEL5      vim DONE
" macvim    mvim TODO 
" macvim     vim TODO
" webfaction vim TODO



" Set up the search path for plugins colors and syntax files
set runtimepath=$HOME/dotfiles/vim,$VIMRUNTIME

" Trying out Pathogen
" https://github.com/tpope/vim-pathogen
execute pathogen#infect()

" some things borrowed from
"   http://code.charles-keepax.co.uk/mydotfiles/src/dbea2a3b27f71d572f2aaf9d95a24b8fc148fb63/_vimrc?at=default

set nocompatible	   " Use Vim defaults instead of 100% vi compatibility
set backspace=indent,eol,start	" more powerful backspacing
set history=50          " keep 50 lines of command line history
"set ruler               " show the cursor position all the time

set scrolloff=3
set number

if &t_Co > 2 || has("gui_running")
  syntax on
  syntax enable
  set hlsearch " Enable search highlighting
endif


" Show
set showmatch    " Show matching brackets.
set showmode     " Display indication that insert mode is on
set showcmd		   " Show (partial) command in status line.

"Tab settings
set expandtab           " spaces are used instead of tabs
set tabstop=2           " number of spaces inserted when tab is hit
set shiftwidth=2        " used with autoindent (should equal tabstop)
set softtabstop=2       " if set below tabstop will insert this many spaces 

"Search settings
set ignorecase		" Do case insensitive matching
set incsearch		" Incremental search

" Auto
set autowrite		  " Automatically save before commands like :next and :make

"http://amix.dk/vim/vimrc.txt
" No annoying sound on errors
 set noerrorbells
 set novisualbell
 set t_vb=
 set tm=500
 "--

" Gui Options
":set guioptions-=m  "remove menu bar
:set guioptions-=T  "remove toolbar
":set guioptions-=r  "remove right-hand scroll bar

"Allow Code Folding with {{{ }}} markers
" zc close fold, zo open fold
set foldmethod=marker

"Experimenting with vim-ruby
filetype on             " Enable filetype detection
filetype indent on      " Enable filetype-specific indenting
filetype plugin on      " Enable filetype-specific plugins
compiler ruby           " Enable compiler support for ruby

"Set wrapping  http://vimcasts.org/e/16
" NB list shows white space but breaks linebreak
set wrap linebreak nolist

if version >= 604
  "Allow cursor to go 1 character past end of line 
  "for pasting at the end, I should use p instead of P
  set virtualedit=onemore
endif

" Setting the status line along the bottom
set showcmd          " Always show command line in the status
set ch=2             " Command line 2 lines high
set ls=2             " Status 2 lines high

set viminfo='20,\"50	" read/write a .viminfo file, don't store more than
" 50 lines of registers


" Format the status line
"set statusline=%<%f\ %h%m%r%=%{getcwd()}\ \ \ %-14.(%l,%c%V%)\ %P
" m is the [+] when modified
" %3( ... %) Group min width 3, stops status line moving on modified files
set statusline=%3(%h%m%r%)
set statusline+=\ %f
set statusline+=\ \ FileType:%y
set statusline+=%= "Switch to right side
set statusline+=\ \ Line\ %l/%L

if has("unix")
  if system("uname") == "Darwin"
    "Setting Mac Vim font size
    :set guifont=Menlo:h13
  else 
    "Other Unix systems
    :set guifont=Monospace\ 12
    " set guifont=-*-courier-medium-r-normal-*-*-180-*-*-m-*-*
  endif
endif

" In many terminal emulators the mouse works.
if has('mouse')
  set mouse=a
endif


" Colorschemes can be compared at
" https://code.google.com/p/vimcolorschemetest/
" colorscheme help
" :help highlight-cterm
" Colorschemes I have :
"  ir_black
"  oceanblack256
"  xterm16
"  bw_black
"
" ## Light backgrounds
" bw_white

" Set colorscheme dependant on terminal type
if has("gui_running")
  " GUI
  colorscheme ir_black

  " Turn on caret cross-hairs
  set cursorline
  set cursorcolumn

elseif &t_Co >= 256
  " 256 Color Console
  colorscheme xterm16 "oceanblack256
elseif &t_Co >= 16
  "  16 Color Console
  colorscheme xterm16
elseif &t_Co >= 8
  "   8 Color Console
  colorscheme bw_white
else  
  " Console
  colorscheme bw_white
end


" Enable Spelling after loading colorscheme
so $HOME/dotfiles/dotfiles/.vimrc_spelling

" For Projector Presentations
"set background=light
"highlight clear
"colorscheme shine 

if has("gui_running") || &t_Co >= 16
  "Warn with subtle background colours when over 80 chars long
  highlight OverLength ctermbg=red ctermfg=white guibg=#592929 
  match OverLength /\%81v.\+/
end

" Only do this part when compiled with support for autocommands.
" http://learnvimscriptthehardway.stevelosh.com/chapters/14.html
if has("autocmd")
  " Enable file type detection.
  filetype plugin indent on
  
  " Group commands
  augroup filetype_verilog
    " Clear auto-commands
    autocmd! 

    "autocmd BufNewFile,BufRead *.va,*.vams set ft=verilogams
  augroup END

  augroup remmeber_position_group
    " Clear auto-commands
    autocmd! 

    " When editing a file, always jump to the last known cursor position.
    " Except when position is invalid or inside an event handler
    " (happens when dropping a file on gvim).
    autocmd BufReadPost *
      \ if line("'\"") > 1 && line("'\"") <= line("$") |
      \   exe "normal! g`\"" |
      \ endif
  augroup END

else
  " If we can not set filetype specific file indentation set generic
  set autoindent		
endif " has("autocmd")


" Source a global configuration file if available
"if filereadable("/etc/vimrc")
"  source /etc/vimrc
"endif

"#####################################
"### Key Mappings
"#####################################
"imap maping for insert mode
"map  maping for normal mode

if has("unix")
  if system("uname") == "Darwin"
    " Mac Vim Defaults overide This
    "map  <D-s> :w<cr>
    "imap <D-s> <Esc>:w<cr>
    map  <D-S-]> gt
    map  <D-S-[> gT
    map  <D-0> :tablast<CR>
  else
    map  <C-s> :w<cr>
    imap <C-s> <Esc>:w<cr>
    map  <C-S-]> gt
    map  <C-S-[> gT
    map  <C-0> :tablast<CR>
  endif
endif

noremap <Up>     :echo 'Use k'<CR> 
noremap <Down>   :echo 'Use j'<CR> 
noremap <Left>   :echo 'Use h'<CR> 
noremap <Right>  :echo 'Use l'<CR> 

" type jk quickly instead of Escape to leave insert mode
imap  jk <Esc>

" Enabling the Ruby Txt Object by nelstrom
" Relies on other things
filetype plugin on 
runtime macros/matchit.vim


"http://technotales.wordpress.com/2010/03/31/preserve-a-vim-function-that-keeps-your-state/
function! Preserve(command)
  " Preparation: save last search, and cursor position.
  let _s=@/
  let l = line(".")
  let c = col(".")
  " Do the business:
  execute a:command
  " Clean up: restore previous search history, and cursor position
  let @/=_s
  call cursor(l, c)
endfunction


"so ~/.unix_config/comments.vim
map ;g :call Preserve("normal! gg=G")<CR>

"Setting up ':Clear' to clear search sstring
:com! Clear let @/ = ""

:com! StatsLine %s//\r/g 

" Aliasing :W to :w from 
"   http://stackoverflow.com/questions/3878692/aliasing-a-command-in-vim
cnoreabbrev <expr> W ((getcmdtype() is# ':' && getcmdline() is# 'w')?('W'):('w'))

" Toggle fold state between closed and opened. 
" 
" If there is no fold at current line, just moves forward. 
" If it is present, reverse it's state. 
fun! ToggleFold() 
  if foldlevel('.') == 0 
    normal! l 
  else
    if foldclosed('.') < 0 
      . foldclose 
    else 
      . foldopen 
    endif 
  endif 
  " Clear status line 
  echo 
endfun 

" Map this function to Space key. 
noremap <space> :call ToggleFold()<CR>

" Turn on the fold column
set foldcolumn=1

" gf goto_file, automatically add search for these file extensions
:set suffixesadd+=.v
:set suffixesadd+=.sv
:set suffixesadd+=.bh.v

if version >= 604
  " Add location of project tag-file if the $work environment variable is defined
  if len($work) > 0
    set tags+=$work/tags
  endif
endif

" Some machine require backspace mappings when using xterm256-color
" The following match string is quite specific.
let need_backspacefix = matchstr(hostname(), 'edsrvcomp')
if !empty(need_backspacefix)
  ":help fixdel
  if &term ==? "screen-256color"
    set t_kb=
  endif
  if &term ==? "xterm-256color"
    set t_kb=
  endif
endif

