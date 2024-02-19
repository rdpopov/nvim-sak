M ={}

local states = {
    cursorline = nil,
    lazyredraw = nil,
}

local function setup_options()
    states.cursorline = vim.o.cursorline
    vim.o.cursorline = false
    states.lazyredraw = vim.o.lazyredraw
    vim.o.lazyredraw = true
end

local function revert_options()
    vim.o.cursorline = states.cursorline
    vim.o.lazyredraw = states.lazyredraw
end

local function remove_visual_pattern (rstr)
    local pat = "\\%V"
    local res = rstr

    if string.sub(res,1,#pat) == pat then
        res = string.sub(res,#pat+1)
    end

    if string.sub(res,-#pat) == pat then
        res = string.sub(res,1,-#pat-1)
    end

    return res
end

local function setup_visual_pattern(rstr)
    local ret = rstr
        if vim.o.ignorecase then
            if string.find(rstr,"\\C") == nil and string.find(rstr,"\\c") then
                ret = ret .. "\\c"
            end
        else
            if string.find(rstr,"\\C") == nil and string.find(rstr,"\\c") then
                ret = ret .. "\\C"
            end
        end
    return "\\%V"..ret .. "\\%V"
end

M.compl = function (ArgLead,CmdLine,...)
    local reg = remove_visual_pattern(vim.fn.getreg('/'))
    if reg == "" then
        return ""
    else
        local rstr = reg
        if string.sub(rstr,1,2) == "\\<" then
            rstr = string.sub(rstr,3,-1)
        end
        if string.sub(reg,-2,-1) == "\\>" then
            rstr = string.sub(rstr,0,-3)
        end
        local pre_res_lst = {}
        local cw = vim.fn.expand("<cword>")
        if string.find(CmdLine,"\\w\\+") == nil then
            pre_res_lst[CmdLine .."\\w\\+"] = CmdLine .."\\w\\+"
        end
        if vim.o.ignorecase then
            if string.find(CmdLine,"\\c") == nil then
                pre_res_lst[CmdLine .."\\c"] = CmdLine .."\\c"
            end
        else
            if string.find(CmdLine,"\\C") == nil then
                pre_res_lst[CmdLine .."\\C"] = CmdLine .."\\C"
            end
        end
        pre_res_lst[rstr] = rstr
        pre_res_lst["\\<" .. rstr .. "\\>"] = "\\<" .. rstr .. "\\>"
        pre_res_lst["\\w\\+"] = "\\w\\+"
        pre_res_lst["\\d\\+"] = "\\d\\+"
        pre_res_lst[cw] = cw
        local res_lst = {}
        for _, v in pairs(pre_res_lst) do
            table.insert(res_lst,v)
        end
        return table.concat(res_lst,"\n")
    end
end

local visual_selection_pattern = ".\\%>'<.*\\%<'>.."

M.high_in_motion = function ()
    setup_options()

    vim.cmd(vim.api.nvim_replace_termcodes("norm `]v`[<Esc>",true,true,true))
    local region = vim.fn.matchadd('CursorColumn', visual_selection_pattern )

    vim.cmd(vim.api.nvim_replace_termcodes("norm gv<Esc>",true,true,true))
    vim.cmd [[redraw!]]

    ok_match = false
    local text = vim.ui.input({
        prompt ='Pattern: ',
        completion ="custom,v:lua.require'nvim-sak'.compl",
        highlight = function (cmd)
            ok_match,hl_match = pcall(vim.fn.matchadd,'IncSearch', setup_visual_pattern(cmd) )
            if ok_match then
                vim.cmd [[redraw!]]
                vim.fn.matchdelete(hl_match)
            end
            return {}
        end
    }, function (input)
        if input then
            if ok_match then
                vim.fn.setreg("/", setup_visual_pattern(input))
            end
            vim.opt.hlsearch = true
            vim.cmd[[redraw | norm `z]]
            vim.cmd[[redraw]]
        else
            vim.cmd[[:norm `z]]
        end
        revert_options()
    end)

end

M.complex_replace = function (target)
    -- execute a macro if we do a 'macro'
    if #target > 2 and target[1] == '@' then
        vim.cmd("'<,'>g/" .. vim.fn.getreg('/')  .. "/:norm "  .. string.sub(target,2,-1))
    else
        vim.cmd(':norm gv"zy')
        local pattern = remove_visual_pattern(vim.fn.getreg('/'))
        local res = vim.fn.substitute(vim.fn.getreg('z') , pattern , target  , 'g')
        vim.fn.setreg('z',res)
        vim.cmd(':norm gv"zp')
    end
end

M.interactive_replace = function ()
    setup_options()
    local region = vim.fn.matchadd('CursorColumn', visual_selection_pattern )
    local text = vim.ui.input({
        prompt ='Replace: ',
        default = '\\0',
        highlight = function (cmd)
            local pattern = remove_visual_pattern(vim.fn.getreg('/'))
            local crnt_change_nr = vim.fn.changenr()
            M.complex_replace(cmd)
            -- If there is a change undo it, optherwise don't
            if vim.fn.changenr() > crnt_change_nr then
                vim.cmd("redraw! ")
                vim.cmd("undo!")
            end
            return {}
        end
    }, function (input)
        revert_options()
        if input ~= nil then
            M.complex_replace(input)
        else
            vim.cmd[[:norm `z]]
        end
    end)
    vim.cmd[[call vsm#CleanupRegionHighlight()]]
end


local function get_all_matches_txt(txt,pattern)
    local res = {}
    while true do
        local crnt = vim.fn.matchstrpos(txt,pattern)
        if crnt[1] ~= ""  then
            table.insert(res,crnt[1])
            txt = string.sub(txt,crnt[3]+1)
        else
            break
        end
    end
    return res
end


M.accumulate_pattern = function()
    vim.cmd(':norm gv"zy')
    local txt = vim.fn.getreg('z')
    local pattern = remove_visual_pattern(vim.fn.getreg('/'))
    vim.fn.setreg('+',table.concat(get_all_matches_txt(txt,pattern),"\n"))
    vim.cmd(':norm `z')
end

M.interleave_from_register = function()
    vim.cmd(':norm gv"zy')
    local gets = vim.fn.split (vim.fn.getreg('+'),"\n")
    local get_idx = 1
    local txt = vim.fn.getreg('z')
    local res = {}
    local pattern = remove_visual_pattern(vim.fn.getreg('/'))
    local split_text = vim.fn.split(txt,pattern,true)
    for _,w in pairs(split_text) do
        table.insert(res,w)
        table.insert(res,gets[get_idx])
        get_idx = (get_idx % #gets) + 1
    end
    table.remove(res)
    vim.fn.setreg('z',table.concat(res,""))
    vim.cmd(':norm gv"zp')
    -- vim.cmd[[:norm `z]]
end

M.rotate_patterns = function()
    vim.cmd(':norm gv"zy')
    local pattern = remove_visual_pattern(vim.fn.getreg('/'))
    local txt = vim.fn.getreg('z')
    local all_matches = get_all_matches_txt(txt,pattern)
    if #all_matches == 0  then
        return
    end
    local fst = table.remove(all_matches)
    table.insert(all_matches,1,fst) -- get last and push it to front

    local match_idx = 1;
    local res = {}
    local split_text = vim.fn.split(txt,pattern,true)
    for _,w in pairs(split_text) do
        table.insert(res,w)
        table.insert(res,all_matches[match_idx])
        match_idx = match_idx + 1 end
    vim.fn.setreg('z',table.concat(res,""))
    vim.cmd(':norm gv"zp')
end

M.generate_with_pattern  = function()
    vim.cmd(':norm gv"zy')
    local to_insert = vim.fn.split(vim.fn.getreg('+'),"\n")
    local save_reg = vim.fn.getreg('+')
    local p = vim.fn.getreg('z')
    local result = {}
    for _,w in ipairs(to_insert) do
        if #w > 0 then
            local t = vim.fn.substitute(w , w , p , 'g')
            table.insert(result,t)
        end
    end
    vim.fn.setreg('z',table.concat(result,"\n"))
    vim.cmd(':norm gv"zp')
    vim.fn.setreg('+',save_reg)
end

return M
