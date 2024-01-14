" Vim plugin to approximate selecion mode in helix/kakoune
"
" Maintainer: Me
" License: This file is placed in the public domain.
"
if exists("g:loaded_vsm") || &cp || v:version < 700
    finish
endif
let g:loaded_vsm = 1
let s:visual_selection_pattern = ".\\%>'<.*\\%<'>.."

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
    let l:t = ""
    execute "norm `]v`[\<esc>"
    let w:region = matchadd('CursorColumn', s:visual_selection_pattern )
    exe "redraw"
    let l:t = input({'prompt':'Pattern: ','default':'','completion':"custom,vsm#CompletionForSearchAndReplaceToken",'highlight':'vsm#HighlightWhileTypingVisual'})
    if l:t == ""
        execute ":norm `z"
        return
    endif
    call setreg("/", "\\%V" . l:t)
    exe "redraw"
    execute ":norm `z"
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
    let w:region = matchadd('CursorColumn', s:visual_selection_pattern )
    let l:target = input({'prompt':'Replace ','default':'\0' ,'canelreturn':-1,'highlight':'vsm#HighlightWhileReplace'})
    if l:target == -1
        execute ":norm `<"
        return
    endif
    call vsm#ComplexRepalce(l:target)
    execute ":norm `<"
endfunction

function! vsm#CleanupRegionHighlight()
    for i in getmatches()
        if has_key(i,'pattern')
            if  i['pattern'] == s:visual_selection_pattern 
                call matchdelete(i["id"])
            endif
        endif
    endfor
endfunction

function! vsm#AccPattern()
    exe ':norm gv"zy'
    let l:pattern = getreg('/')
    let l:txt = getreg('z')
    let l:res = []
    if l:pattern[:2] == "\\%V"
        let l:pattern = l:pattern[3:]
    endif
    while v:true
        let l:crnt = matchstrpos(l:txt,l:pattern,0)
        if l:crnt[2] != -1
            let l:strt = l:crnt[2]
            let l:res = l:res + [l:crnt[0]]
            let l:txt = l:txt[l:strt:]
        else
            break
        endif
    endwhile
    call setreg('+',join(l:res,"\n"))
endfunction
" if function is canceled with ctl-c i won't be able to cleanup highlights
au! ModeChanged c:n call vsm#CleanupRegionHighlight()

nnoremap <silent> <Plug>VsmHighlightInMotion mz:set opfunc=vsm#HighlightInMotion<CR>g@
nnoremap <Plug>VsmAcc mz:call vsm#AccPattern()<CR>
nnoremap <silent> <Plug>VsmInteractiveReplace mz:call vsm#InteractiveReplace()<CR>

