" Vim plugin to approximate selecion mode in helix/kakoune
"
" Maintainer: Me
" License: This file is placed in the public domain.
"
if exists("g:loaded_vsm") || &cp || v:version < 700
    finish
endif
let g:loaded_vsm = 1

" TODO:
" Add configuration registers to use and marks and maybe color groups

function! vsm#CompletionForSearchAndReplaceToken(ArgLead, CmdLine,...)
    let l:r = getreg('/')
    if l:r[:2] == "\\%V"
        let l:r = l:r[3:]
    endif
    if l:r == ""
        return join([''],"\n")
    else
        let l:rstr = r
        if l:r[:1] == "\\<"
            let l:rstr = l:rstr[2:]
        endif
        if l:rstr[-2:] == "\\>"
            let l:rstr = l:rstr[:-3]
        endif
        let l:res_list = uniq([l:rstr,"\\<".l:rstr."\\>","\\w\\+","\\d\\+"])
        if len(res_list) == 2
            let l:res_list += [""]
        endif
        return join(l:res_list,"\n")
    endif
endfunction

function! vsm#HighlightWhileTypingVisual(cmdline)
    let w:h = matchadd('IncSearch', "\\%V" . a:cmdline)
    exe "redraw"
    call matchdelete(w:h)
    return []
endfunction

function! vsm#HighlightWhileReplace(cmdline)
    let l:pattern = trim(getreg('/'),"\%V")
    let l:crnt_changenr = changenr()
    try
        call vsm#ComplexRepalce(a:cmdline)
    endtry
    " If there is a change undo it, optherwise don't
    if changenr() > l:crnt_changenr
        exe "redraw"
        exe ":undo!"
    endif
    return []
endfunction

function! vsm#HighlightInMotion(type, ...)
    let w:region = matchadd('CursorColumn', ".\\%>'<.*\\%<'>.." )
    let l:t = ""
    set nohlsearch
    execute "norm `]v`[\<esc>"
    exe "redraw"
    let l:t = input({'prompt':'Pattern: ','default':'','completion':"custom,vsm#CompletionForSearchAndReplaceToken",'highlight':'vsm#HighlightWhileTypingVisual'})
    if l:t == ""
        execute ":norm `z"
        call matchdelete(w:region)
        return
    endif
    call setreg("/", "\\%V" . l:t)
    exe "redraw"
    execute ":norm `z"
    call matchdelete(w:region)
    set hlsearch
    exe "redraw"
endfunction

function! vsm#ComplexRepalce(target)
    if len(a:target) >= 2 && a:target[0] == '@'
        exe "'<,'>g/" . getreg('/')  . "/:norm " . a:target[1:]
    else
        exe ':norm gv"zy'
        let l:pattern = getreg('/')
        if l:pattern[:2] == "\\%V"
            let l:pattern = l:pattern[3:]
        endif
        let l:res = substitute(getreg('z') , l:pattern , a:target  , 'g')
        call setreg('z',l:res)
        exe ':norm gv"zp'
    endif
endfunction


function! vsm#InteractiveReplace()
    let w:region = matchadd('CursorColumn', ".\\%>'<.*\\%<'>.." )
    let l:target = input({'prompt':'Replace ','default':'' ,'canelreturn':-1,'highlight':'vsm#HighlightWhileReplace'})
    if l:target == -1
        execute ":norm `<"
        call matchdelete(w:h)
        return
    endif
    call vsm#ComplexRepalce(l:target)
    call matchdelete(w:region)
    execute ":norm `<"
endfunction

nnoremap <silent> <Plug>VsmHighlightInMotion mz:set opfunc=vsm#HighlightInMotion<CR>g@
nnoremap <silent> <Plug>VsmInteractiveReplace mz:call vsm#InteractiveReplace()<CR>
