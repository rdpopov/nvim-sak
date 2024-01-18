" Vim plugin to approximate selecion mode in helix/kakoune
"
" Maintainer: Me
" License: This file is placed in the public domain.
"
if exists("g:loaded_vim_sak") || &cp || v:version < 700
    finish
endif
let g:loaded_vim_sak = 1

nnoremap <Plug>VimSakHihglightInMotion mz:set opfunc=v:lua.require'vim-sak'.high_in_motion<CR>g@
nnoremap <Plug>VimSakInteractiveReplace mz:lua require'vim-sak'.interactive_replace()<CR>
nnoremap <Plug>VimSakAccumulate mz:lua require'vim-sak'.accumulate_pattern()<CR>

function! vsm#CleanupRegionHighlight()
    for i in getmatches()
        if has_key(i,'pattern')
            if  i['pattern'] == ".\\%>'<.*\\%<'>.." 
                call matchdelete(i["id"])
            endif
        endif
    endfor
endfunction

au! ModeChanged c:n call vsm#CleanupRegionHighlight()
