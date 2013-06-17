" Vim color file
" Maintainer:   Hans Fugal <hans@fugal.net>
" Last Change:  5 Oct 2001
" URL:    http://fugal.net/vim/colors/bw.vim

" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors

" if t_Co == 8 in Gnome terminal will use palette entry 8
" (16 is default white) Bad t_Co or bad name mapping ?

set background=light
"set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name="bw"

hi Normal         ctermbg=White         ctermfg=Black
"hi Normal         ctermbg=Black         ctermfg=White
hi SpecialKey     cterm=bold            ctermfg=NONE
hi NonText        cterm=bold            ctermfg=NONE
hi Directory      cterm=bold            ctermfg=NONE
hi ErrorMsg       cterm=standout        ctermfg=NONE
hi IncSearch      cterm=reverse         ctermfg=NONE
hi Search         cterm=reverse         ctermfg=NONE
hi MoreMsg        cterm=bold            ctermfg=NONE
hi ModeMsg        cterm=bold            ctermfg=NONE
hi LineNr         cterm=NONE            ctermfg=NONE
hi Question       cterm=standout        ctermfg=NONE
hi StatusLine     cterm=bold,reverse    ctermfg=NONE
hi StatusLineNC   cterm=reverse         ctermfg=NONE
hi VertSplit      cterm=reverse         ctermfg=NONE
hi Title          cterm=bold            ctermfg=NONE
hi Visual         cterm=reverse         ctermfg=NONE
hi VisualNOS      cterm=bold,underline  ctermfg=NONE
hi WarningMsg     cterm=standout        ctermfg=NONE
hi WildMenu       cterm=standout        ctermfg=NONE
hi Folded         cterm=standout        ctermfg=NONE
hi FoldColumn     cterm=standout        ctermfg=NONE
hi DiffAdd        cterm=bold            ctermfg=NONE
hi DiffChange     cterm=bold            ctermfg=NONE
hi DiffDelete     cterm=bold            ctermfg=NONE
hi DiffText       cterm=reverse         ctermfg=NONE
hi Comment        cterm=NONE            ctermfg=NONE
hi Constant       cterm=NONE            ctermfg=NONE
hi Special        cterm=bold            ctermfg=NONE
hi Identifier     cterm=NONE            ctermfg=NONE
hi Statement      cterm=bold            ctermfg=NONE
hi PreProc        cterm=NONE            ctermfg=NONE
hi Type           cterm=NONE            ctermfg=NONE
hi Underlined     cterm=underline       ctermfg=NONE
hi Ignore         cterm=bold            ctermfg=NONE
hi Error          cterm=reverse         ctermfg=NONE
hi Todo           cterm=standout        ctermfg=NONE
