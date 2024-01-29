" Nvim plugin to approximate selecion mode in helix/kakoune
"
" Maintainer: Me
" License: This file is placed in the public domain.
"
if exists("g:loaded_vim_sak") || &cp || v:version < 700
    finish
endif
let g:loaded_vim_sak = 1

nnoremap <silent> <Plug>NvimSakHihglightInMotion mz:set opfunc=v:lua.require'nvim-sak'.high_in_motion<CR>g@
nnoremap <silent> <Plug>NvimSakInteractiveReplace mz:lua require'nvim-sak'.interactive_replace()<CR>
nnoremap <silent> <Plug>NvimSakAccumulate mz:lua require'nvim-sak'.accumulate_pattern()<CR>

nnoremap <silent> <Plug>NvimSakInterleave mz:lua require'nvim-sak'.interleave_from_register()<CR>
nnoremap <silent> <Plug>NvimSakRotate mz:lua require'nvim-sak'.rotate_patterns()<CR>

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
