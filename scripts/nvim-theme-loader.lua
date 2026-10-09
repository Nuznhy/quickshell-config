-- Generated integration loader. Colors and paths are supplied by the renderer.
local name = 'quickshell-config'
local path = __COLOR_PATH__
local group = vim.api.nvim_create_augroup('QuickshellThemeSync', { clear = true })
local prior = vim.g.quickshell_prior_theme or vim.g.colors_name or 'default'
local prior_background = vim.g.quickshell_prior_background or vim.o.background
vim.g.quickshell_prior_theme = prior
vim.g.quickshell_prior_background = prior_background
local function version()
    local stat = (vim.uv or vim.loop).fs_stat(path)
    return stat and (stat.mtime.sec .. ':' .. stat.mtime.nsec .. ':' .. stat.size) or nil
end
local last
local function refresh(force)
    local current = version()
    if not current then
        if vim.g.colors_name == name then
            vim.o.background = prior_background
            pcall(vim.cmd.colorscheme, prior)
        end
        vim.api.nvim_del_augroup_by_id(group)
        pcall(vim.api.nvim_del_user_command, 'QuickshellThemeReload')
        vim.g.quickshell_prior_theme = nil
        vim.g.quickshell_prior_background = nil
        return
    end
    if (force or current ~= last) and (force or vim.g.colors_name == name) then
        local ok, error = pcall(vim.cmd.colorscheme, name)
        if ok then last = current else vim.notify(tostring(error), vim.log.levels.WARN) end
    end
end
vim.api.nvim_create_autocmd('FocusGained', { group = group, callback = function() refresh(false) end })
vim.api.nvim_create_user_command('QuickshellThemeReload', function() refresh(true) end, { force = true })
refresh(true)
