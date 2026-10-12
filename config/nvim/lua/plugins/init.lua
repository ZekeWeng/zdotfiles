-- Plugins for Neovim.

return {
    -- Colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("catppuccin-mocha")
        end,
    },

    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
        },
        config = function()
            require("nvim-tree").setup()
        end,
    },

    -- Fuzzy search
    {
        "nvim-telescope/telescope.nvim",
        -- No tag pin. lazy-lock.json gives the version, and :Lazy update can move it.
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
        },
        config = function()
            require("telescope").setup()
        end,
    },

    -- Syntax highlight
    -- The main branch of nvim-treesitter needs the tree-sitter command, from tree-sitter-cli in brew/tools.Brewfile.
    -- The FileType autocmd in lua/config/autocmds.lua starts the highlight.
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install({
                "c",
                "lua",
                "vim",
                "vimdoc",
                "query",
                "markdown",
                "markdown_inline",
                "javascript",
                "typescript",
                "tsx",
                "python",
                "go",
                "rust",
                "bash",
                "json",
                "yaml",
            })
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "catppuccin-mocha",
                },
            })
        end,
    },

    -- Autopairs
    -- Close brackets and quotes automatically.
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Git integration
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end,
    },
}
