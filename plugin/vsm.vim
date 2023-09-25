if exists("g:loaded_vsm") || &cp || v:version < 700
    finish
endif
let g:loaded_vsm = 1
runtime! autoload/vsm.vim

nnoremap <silent> <Plug>VsmHighlight mz:set opfunc=vsm#HighlightInMotion<CR>g@
nnoremap <silent> <Plug>VsmInteractiveReplace mz:call vsm#InteractiveReplace()<CR>

if !exists("g:pluginname_no_mappings") || ! g:pluginname_no_mappings
    nnoremap <silent> s <Plug>VsmHighlight
    nnoremap <silent> <leader>r <Plug>VsmInteractiveReplace
endif
