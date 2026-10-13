-- Neovim setup for each computer. ~/.config/nvim links to this folder. It needs Neovim 0.12 or later.

-- Version
if vim.fn.has("nvim-0.12") == 0 then
    vim.api.nvim_echo({ { "This config needs Neovim 0.12 or later. Run: brew upgrade neovim", "ErrorMsg" } }, true, {})
    return
end

-- lazy.nvim
-- Install the plugin manager if it is missing. lazy_sha must agree with lazy.nvim in lazy-lock.json.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_sha = "306a05526ada86a7b30af95c5cc81ffba93fef97"
if not vim.uv.fs_stat(lazypath) then
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
    if vim.v.shell_error == 0 then
        out = vim.fn.system({ "git", "-C", lazypath, "checkout", lazy_sha })
    end
    if vim.v.shell_error ~= 0 then
        -- Delete the partial clone, so that the next start tries again.
        vim.fn.delete(lazypath, "rf")
        vim.api.nvim_echo({
            { "The install of lazy.nvim failed:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPush a key to quit.", "Normal" },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

-- Settings
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Plugins
require("lazy").setup("plugins")
