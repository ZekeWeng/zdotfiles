-- Autocommands for Neovim.

local autocmd = vim.api.nvim_create_autocmd

-- Yank
-- Highlight the text that you yank.
autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight_yank", {}),
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Resize
-- Make the splits equal when the terminal changes size.
autocmd({ "VimResized" }, {
    group = vim.api.nvim_create_augroup("resize_splits", {}),
    callback = function()
        local current_tab = vim.fn.tabpagenr()
        vim.cmd("tabdo wincmd =")
        vim.cmd("tabnext " .. current_tab)
    end,
})

-- Treesitter
-- Start Treesitter highlight and indent. The main branch of nvim-treesitter does not start them.
-- If no parser is installed for the filetype, nothing happens.
autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter_highlight", {}),
    callback = function(event)
        local lang = vim.treesitter.language.get_lang(event.match)
        if not lang or not pcall(vim.treesitter.start, event.buf, lang) then
            return
        end
        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

-- Quit
-- Close these filetypes with q.
autocmd("FileType", {
    group = vim.api.nvim_create_augroup("close_with_q", {}),
    pattern = {
        "checkhealth",
        "help",
        "man",
        "qf",
        "query",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})
