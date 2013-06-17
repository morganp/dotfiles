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

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name="bw_basic_dark"

hi Normal         cterm=NONE          ctermbg=Black  ctermfg=White
hi SpecialKey     cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi NonText        cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Directory      cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi ErrorMsg       cterm=standout      ctermbg=NONE  ctermfg=NONE
hi IncSearch      cterm=underline     ctermbg=NONE  ctermfg=NONE
hi Search         cterm=underline     ctermbg=NONE  ctermfg=NONE
hi MoreMsg        cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi ModeMsg        cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi LineNr         cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Question       cterm=standout      ctermbg=NONE  ctermfg=NONE
hi StatusLine     cterm=reverse       ctermbg=NONE  ctermfg=NONE
hi StatusLineNC   cterm=reverse       ctermbg=NONE  ctermfg=NONE
hi VertSplit      cterm=reverse       ctermbg=NONE  ctermfg=NONE
hi Title          cterm=bold          ctermbg=NONE  ctermfg=NONE
hi Visual         cterm=reverse       ctermbg=NONE  ctermfg=NONE
hi VisualNOS      cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi WarningMsg     cterm=standout      ctermbg=NONE  ctermfg=NONE
hi WildMenu       cterm=standout      ctermbg=NONE  ctermfg=NONE
hi Folded         cterm=standout      ctermbg=NONE  ctermfg=NONE
hi FoldColumn     cterm=standout      ctermbg=NONE  ctermfg=NONE
hi DiffAdd        cterm=bold          ctermbg=NONE  ctermfg=NONE
hi DiffChange     cterm=bold          ctermbg=NONE  ctermfg=NONE
hi DiffDelete     cterm=bold          ctermbg=NONE  ctermfg=NONE
hi DiffText       cterm=reverse       ctermbg=NONE  ctermfg=NONE
hi Comment        cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Constant       cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Special        cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Identifier     cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Statement      cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi PreProc        cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Type           cterm=NONE          ctermbg=NONE  ctermfg=NONE
hi Underlined     cterm=underline     ctermbg=NONE  ctermfg=NONE
hi Ignore         cterm=bold          ctermbg=NONE  ctermfg=NONE
hi Error          cterm=bold          ctermbg=NONE  ctermfg=NONE
hi Todo           cterm=bold          ctermbg=NONE  ctermfg=NONE
