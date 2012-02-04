 "~/.vimrc should be a link here or contain the following:
"so ~/.unix_config/.vimrc

" Set up the search path for plugins colors and syntax files
set runtimepath=$HOME/dotfiles/vim,$VIMRUNTIME


set scrolloff=3
syntax on
syntax enable
set number

set showmatch
set showmode


set nocompatible	   " Use Vim defaults instead of 100% vi compatibility
set backspace=indent,eol,start	" more powerful backspacing
set history=50          " keep 50 lines of command line history
set ruler               " show the cursor position all the time
set expandtab           " spaces are used instead of tabs
set autoindent          " always set autoindenting on
set tabstop=2           " number of spaces inserted when tab is hit
set shiftwidth=2        " used with autoindent (should equal tabstop)
set softtabstop=2       " if set below tabstop will insert this many spaces 

"Experimenting with vim-ruby
filetype on             " Enable filetype detection
filetype indent on      " Enable filetype-specific indenting
filetype plugin on      " Enable filetype-specific plugins
compiler ruby           " Enable compiler support for ruby

"Set wrapping  http://vimcasts.org/e/16
" NB list shows white space byt breaks linebreak
set wrap linebreak nolist

"Allow cursor to goe 1 character past end of line (for pasting at the end)
set virtualedit=onemore

" Setting upo the status line along the bottom
set showcmd          " Always show command line in the status
set ch=2             " Command line 2 lines high
set ls=2             " Status 2 lines high

set viminfo='20,\"50	" read/write a .viminfo file, don't store more than
" 50 lines of registers

" Spelling corrections moved to seperate file
so $HOME/dotfiles/dotfiles/.vimrc_spelling

" Format the statusline
set statusline=%<%f\ %h%m%r%=%{getcwd()}\ \ \ %-14.(%l,%c%V%)\ %P

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
endif

set mouse=a


"The followin can be written out to a colorscheme.vim 
" file and included sepreately. This would have the added 
" bonus the :colorscheme x could be used to switch back
" Set nice colors
" 0: Black
" 1: Red
" 2: Green
" 3: Orange
" 4: Blue
" 5: Magenta
" 6: Cyan
" 7: White

if has("unix")
  if system("uname") == "Darwin"
    "Setting mac vim font size
    :set guifont=Menlo:h13
  endif
endif

"colorscheme torte
"colorscheme zenburn
colorscheme ir_black



" Console
"highlight Comment             cterm=NONE        ctermfg=2         ctermbg=0
"highlight Error               cterm=NONE        ctermfg=0         ctermbg=4
highlight Todo                cterm=NONE        ctermfg=0         ctermbg=4

" GUI
"highlight Comment             gui=NONE          guifg=Green       guibg=Black
"highlight Error               gui=NONE          guifg=Black       guibg=blue
highlight Todo                gui=NONE          guifg=Black       guibg=blue

" For Projector Presintations
"set background=light
"highlight clear
"colorscheme shine 


"Warn with subtle background colours when over 80 chars long
highlight OverLength ctermbg=red ctermfg=white guibg=#592929 
match OverLength /\%81v.\+/


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

"map : in normal mode
"imap : map key in insert mode
"D apple key
"Ctrl key
"<Esc> escape key
"<CR> Add return to run command 

"map  <D-S-]> gt
"map  <D-S-[> gT
"map  <D-0> :tablast<CR>

"#####################################
"### Key Mappings
"#####################################
if has("unix")
  if system("uname") == "Darwin"
    "map  <D-e> :NERDTreeToggle<CR>
    map  <D-s> :w<cr>
    imap <D-s> <Esc>:w<cr>
    map  <D-S-]> gt
    map  <D-S-[> gT
    map  <D-0> :tablast<CR>
  else
    "map  <C-e> :NERDTreeToggle<CR>
    map  <C-s> :w<cr>
    imap <C-s> <Esc>:w<cr>
    map  <C-S-]> gt
    map  <C-S-[> gT
    map  <C-0> :tablast<CR>
  endif
endif

"imap maping for insert mode
"map  maping for normal mode

" type jjk quickly instead of Escape to leave insert mode
imap jjk <Esc>

"map <D-]> :s/^/#<cr>
"map <D-[> :s/^#/<cr>
"map <C-]> :s/^/escape(b:comment_leader)<cr>
"map <C-[> :s/^#/<cr>

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

set hlsearch "Enable Searcg Highlighting
"Setting up ':Clear' to clear search sstring
:com! Clear let @/ = ""


"get NerdTree
" http://www.vim.org/scripts/script.php?script_id=1658
"TODO add check if NERDTree plugin is in place
"Load NERDTree and put cursor in other window
"autocmd VimEnter * NERDTree
"autocmd VimEnter * wincmd p

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
