M ={}

M.compl = function (ArgLead,CmdLine,...)
    local reg = vim.fn.getreg('/')
    if string.sub(reg,1,3) == "\\%V" then
        reg = string.sub(reg,4,-1)
    end
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
        if string.find(CmdLine,"\\w\\+") == nil then
            pre_res_lst[CmdLine .."\\w\\+"] = CmdLine .."\\w\\+"
        end
        pre_res_lst[rstr] = rstr
        pre_res_lst["\\<" .. rstr .. "\\>"] = "\\<" .. rstr .. "\\>"
        pre_res_lst["\\w\\+"] = "\\w\\+"
        pre_res_lst["\\d\\+"] = "\\d\\+"
        local res_lst = {}
        for _, v in pairs(pre_res_lst) do
            table.insert(res_lst,v)
        end
        return table.concat(res_lst,"\n")
    end
end

local visual_selection_pattern = ".\\%>'<.*\\%<'>.."

M.high_in_motion = function ()
    -- set  '< '> marks
    local head = vim.api.nvim_buf_get_mark(0,'[')
    vim.api.nvim_buf_set_mark(0,'<',head[1],head[2],{})
    local tail = vim.api.nvim_buf_get_mark(0,']')
    vim.api.nvim_buf_set_mark(0,'>',tail[1],tail[2],{})

    -- higlight region with light hihglight
    local region = vim.fn.matchadd('CursorColumn', visual_selection_pattern )
    vim.cmd(vim.api.nvim_replace_termcodes("norm gvO<Esc>",true,true,true))
    vim.cmd [[redraw!]]
    local text = vim.ui.input({
        prompt ='Pattern: ',
        completion ="custom,v:lua.require'vim-sak'.compl",
        highlight = function (cmd)
            local match = vim.fn.matchadd('AerialLine', "\\%V"..cmd )
            vim.cmd [[redraw!]]
            vim.fn.matchdelete(match)
            return {}
        end
    }, function (input)
        -- vim.fn.matchdelete(region)
        if input then
            vim.fn.setreg("/", "\\%V" .. input)
            vim.opt.hlsearch = true
            vim.cmd[[redraw | norm `z]]
            vim.cmd[[redraw]]
        else
            vim.cmd[[:norm `z]]
        end

    end)
end

M.complex_replace = function (target)
    -- execute a macro if we do a 'macro'
    if #target > 2 and target[0] == '@' then
        vim.cmd("'<,'>g/" .. vim.fn.getreg('/')  .. "/:norm "  .. string.sub(target,2,-1))
    else
        vim.cmd(':norm gv"zy')
        local pattern = vim.fn.getreg('/')
        if string.sub(pattern,1,3) == "\\%V" then
            pattern = string.sub(pattern,4,-1)
        end
        local res = vim.fn.substitute(vim.fn.getreg('z') , pattern , target  , 'g')
        vim.fn.setreg('z',res)
        vim.cmd(':norm gv"zp')
    end
end

M.interactive_replace = function ()
    local region = vim.fn.matchadd('CursorColumn', visual_selection_pattern )
    vim.cmd('set lazyredraw')
    local text = vim.ui.input({
        prompt ='Replace: ',
        default = '\\0',
        highlight = function (cmd)
            local pattern = vim.fn.trim(vim.fn.getreg('/'),"\\%V")
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
        vim.cmd('set nolazyredraw')
        if input ~= nil then
            M.complex_replace(input)
        else
            vim.cmd[[:norm `z]]
        end
    end)
end


function get_all_matches_txt(txt,pattern)
    res = {}
    while true do
        local crnt = vim.fn.matchstrpos(txt,pattern)
        if crnt[1] ~= ""  then
            table.insert(res,crnt[1])
            txt = string.sub(txt,crnt[3])
        else
            break
        end
    end
end


M.accumulate_pattern = function()
    vim.cmd(':norm gv"zy')
    local pattern = vim.fn.getreg('/')
    local txt = vim.fn.getreg('z')
    if string.sub(pattern,1,3) == "\\%V" then
        pattern = string.sub(pattern,4,-1)
    end
    vim.fn.setreg('+',table.concat(get_all_matches_txt(txt,pattern),"\n"))
    vim.cmd[[:norm `z]]
end


M.interleave_from_register = function()
    vim.cmd(':norm gv"zy')
    local gets = vim.fn.split (vim.fn.getreg('+'),"\n")
    local get_idx = 1
    local pattern = vim.fn.getreg('/')
    local txt = vim.fn.getreg('z')
    local res = {}
    if string.sub(pattern,1,3) == "\\%V" then
        pattern = string.sub(pattern,4,-1)
    end
    local split_text = vim.fn.split(txt,pattern,true)
    for _,w in pairs(split_text) do
        table.insert(res,w)
        table.insert(res,gets[get_idx])
        get_idx = (get_idx % #gets) + 1
    end
    vim.fn.setreg('+',table.concat(res,""))
    vim.cmd(':norm gv"zp')
    vim.cmd[[:norm `z]]
end

M.rotate_patterns = function()
    vim.cmd(':norm gv"zy')
    local pattern = vim.fn.getreg('/')
    local txt = vim.fn.getreg('z')
    local all_matches = get_all_matches_txt(txt,pattern)
    if #all_matches == 0  then
        return
    end
    table.insert(all_matches,table.remove(all_matches)) -- get last and push it to front
    local match_idx = 1;
    local res = {}
    if string.sub(pattern,1,3) == "\\%V" then
        pattern = string.sub(pattern,4,-1)
    end
    local split_text = vim.fn.split(txt,pattern,true)
    for _,w in pairs(split_text) do
        table.insert(res,w)
        table.insert(res,all_matches[match_idx])
        match_idx = match_idx + 1
    end
    vim.fn.setreg('+',table.concat(res,""))
    vim.cmd(':norm gv"zp')
    vim.cmd[[:norm `z]]
end


return M
