function! vsm#CompletionForSearchAndReplaceToken(ArgLead, CmdLine,...)
    let empty_line = "^$"
    let r = trim(getreg('/'),"\\%V")
    if r == ""
        return join([''],"\n")
    else
        let l:rstr = trim(r,"\<|\>")
        let l:res_list = uniq([rstr,"\\<".rstr."\\>","\\w\\+","\\d\\+"])
        if len(res_list) == 2
            let l:res_list += [""]
        endif
        return join(l:res_list,"\n")
    endif
endfunction

function! vsm#CompletionForSearchAndReplaceTarget(ArgLead, CmdLine,...)
    let r = trim(getreg('/'),"\\%V")
    if r == ""
        return join([''],"\n")
    else
        let l:rstr = r "trim(r,"\<|\>")
        let l:res_list = uniq([r,rstr,"<delete>",a:ArgLead])
        if len(l:res_list) == 2
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
    call vsm#ComplexRepalce(a:cmdline)
    exe "redraw"
    exe ":undo!"
    return []
endfunction

function! vsm#HighlightInMotion(type, ...)
    let l:t = ""
    set nohlsearch
    execute "norm `]v`[\<esc>"
    let l:t = input({'prompt':'Pattern: ','default':'','completion':"custom,vsm#CompletionForSearchAndReplaceToken",'highlight':'vsm#HighlightWhileTypingVisual'})
    if l:t == ""
        execute ":norm `z"
        return
    endif
    call setreg("/", "\\%V" . l:t)
    exe "redraw"
    execute ":norm `z"
    set hlsearch
endfunction

function! vsm#ComplexRepalce(target)
    if a:target == "<delete>"
        let a:target = ""
    endif
    if a:target[0] == '@'
        if len(a:target) > 2
            exe "g/" . getreg('/')  . "/:norm " . a:target[1:]
        endif
    else
        if line("'<") == line("'>") " if marks are on the same line, the '> wont be adjusted so it wiull bew broken or lines change
            exe ':norm gv"xy'
            let l:pattern = getreg('/')
            if l:pattern[:2] == "\\%V"
                let l:pattern = l:pattern[3:]
            endif
            let l:res = substitute(getreg('x') , l:pattern , a:target , 'g')
            call setreg('x',l:res)
            exe ':norm gv"_d"xp'
        else
            let l:pattern = trim(getreg('/'),"\%V")
            exe "'<,'>s/" . l:pattern . "/".a:target. "/g"
        endif
    endif
endfunction

function! vsm#InteractiveReplace()
    let l:target = input({'prompt':'Replace: ','default':'','completion':"custom,vsm#CompletionForSearchAndReplaceTarget",'highlight':'vsm#HighlightWhileReplace'})
    if l:target == ""
        execute ":norm `z"
        return
    endif
    call vsm#ComplexRepalce(l:target)
    execute ":norm `z"
endfunction
