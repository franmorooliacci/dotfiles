-- ~/.config/nvim/init.lua
-- Neovim 0.11.5 – React / TypeScript / MUI + Django / FastAPI

------------------------------------------------------------
-- Basics
------------------------------------------------------------
vim.g.mapleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.cursorline = true

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

vim.opt.splitright = true
vim.opt.splitbelow = true

-- Folding
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr()'
vim.o.foldcolumn = '0'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

------------------------------------------------------------
-- Bootstrap lazy.nvim
------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- Plugins
------------------------------------------------------------
require('lazy').setup({

    -- UI / QoL
    { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
    { 'Mofiqul/dracula.nvim', name = 'dracula', priority = 1000 },
    { 'tanvirtin/monokai.nvim', name = 'monokai', priority = 1000 },
    {
        'ellisonleao/gruvbox.nvim',
        priority = 1000,
        config = function()
            vim.o.background = 'dark'
            vim.cmd.colorscheme('gruvbox')
        end,
    },
    { 'nvim-tree/nvim-web-devicons', lazy = true },
    { 'folke/which-key.nvim', opts = {} },
    {
        'nvim-lualine/lualine.nvim',
            opts = {
                options = {
                    theme = 'auto',
            	    icons_enabled = true,
                },
            },
    },
    { 'lewis6991/gitsigns.nvim', opts = {} },
    { 'folke/trouble.nvim', opts = {} },
    {
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        opts = {
            indent = {char = '┊'},
            scope = {enabled = false},
        },
    },

    -- File explorer
    { 'stevearc/oil.nvim', opts = {} },

    -- Telescope
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            defaults = {
                mappings = {
                    i = {
                        ['<C-j>'] = 'move_selection_next',
                        ['<C-k>'] = 'move_selection_previous',
                    },
                },
                file_ignore_patterns = {
                    'venv/.*',
                    '.venv/.*',
                    'node_modules/.*',
                    '.git*',
                },
            },
        },
    },

    --------------------------------------------------------
    -- Treesitter (SAFE)
    --------------------------------------------------------
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        opts = {
            ensure_installed = {
                'lua',
                'vim',
                'vimdoc',
                'typescript',
                'tsx',
                'javascript',
                'html',
                'css',
                'json',
                'yaml',
                'python',
                'bash',
                'markdown',
            },
            highlight = { enable = true },
            indent = { enable = true },
        },
        config = function(_, opts)
            local ok, configs = pcall(require, 'nvim-treesitter.configs')
            if not ok then
                return
            end
            configs.setup(opts)
        end,
    },

    -- LSP tooling
    { 'williamboman/mason.nvim', opts = {} },
    { 'williamboman/mason-lspconfig.nvim', opts = {} },
    { 'neovim/nvim-lspconfig' },

    -- Completion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'L3MON4D3/LuaSnip' },
    { 'saadparwaiz1/cmp_luasnip' },

    -- Editing helpers
    { 'windwp/nvim-autopairs', opts = {} },
    { 'numToStr/Comment.nvim', opts = {} },
    { 'kylechui/nvim-surround', opts = {} },

    -- Formatting
    {
        'stevearc/conform.nvim',
        opts = {
            format_on_save = function()
                return { timeout_ms = 1500, lsp_fallback = false }
            end,
            formatters_by_ft = {
                javascript = { 'prettier' },
                javascriptreact = { 'prettier' },
                typescript = { 'prettier' },
                typescriptreact = { 'prettier' },
                json = { 'prettier' },
                yaml = { 'prettier' },
                html = { 'prettier' },
                css = { 'prettier' },
                python = { 'ruff_format' },
            },
        },
    },

    -- Lint
    {
        'mfussenegger/nvim-lint',
        config = function()
            local lint = require('lint')
            lint.linters_by_ft = {
                python = { 'ruff' },
            }

            vim.api.nvim_create_autocmd(
                { 'BufWritePost', 'BufEnter', 'InsertLeave' },
                { callback = function() lint.try_lint() end }
            )
        end,
    },
})

------------------------------------------------------------
-- Keymaps
------------------------------------------------------------
local map = vim.keymap.set

map('n', '<leader>ff', function() require('telescope.builtin').find_files({hidden = true}) end)
map('n', '<leader>fg', function() require('telescope.builtin').live_grep() end)
map('n', '<leader>fb', function() require('telescope.builtin').buffers() end)
map('n', '<leader>e', function() require('oil').open() end)
map('n', '<leader>xx', function() require('trouble').toggle() end)

-- LSP
map('n', 'gd', vim.lsp.buf.definition)
map('n', 'gr', vim.lsp.buf.references)
map('n', 'K', vim.lsp.buf.hover)
map('n', '<leader>rn', vim.lsp.buf.rename)
map('n', '<leader>ca', vim.lsp.buf.code_action)
map('n', '<leader>f', function()
    require('conform').format({ async = true, lsp_fallback = true })
end)

-- Diagnostics
map('n', '<leader>dn', vim.diagnostic.goto_next)
map('n', '<leader>dp', vim.diagnostic.goto_prev)
map('n', '<leader>de', vim.diagnostic.open_float)

------------------------------------------------------------
-- Diagnostics (inline errors / warnings)
------------------------------------------------------------
vim.diagnostic.config({
    virtual_text = {
        spacing = 2,
        prefix = "●",
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = "if_many"
    }
})

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)

------------------------------------------------------------
-- Completion (nvim-cmp)
------------------------------------------------------------
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    }),
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
})

------------------------------------------------------------
-- LSP (Neovim 0.11.5)
------------------------------------------------------------
require('mason').setup()

require('mason-lspconfig').setup({
    ensure_installed = {
        'ts_ls',
        'eslint',
        'pyright',
        'html',
        'cssls',
        'jsonls',
        'yamlls',
    },
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if ok_cmp then
    capabilities = cmp_lsp.default_capabilities(capabilities)
end

local function on_attach(client)
    if client.name == 'ts_ls' or client.name == 'eslint' then
        client.server_capabilities.documentFormattingProvider = false
    end
end

vim.lsp.config('ts_ls', { capabilities = capabilities, on_attach = on_attach })
vim.lsp.config('eslint', { capabilities = capabilities, on_attach = on_attach })
vim.lsp.config('html', { capabilities = capabilities, on_attach = on_attach })
vim.lsp.config('cssls', { capabilities = capabilities, on_attach = on_attach })
vim.lsp.config('jsonls', { capabilities = capabilities, on_attach = on_attach })
vim.lsp.config('yamlls', { capabilities = capabilities, on_attach = on_attach })

vim.lsp.config('pyright', {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        python = {
            analysis = {
                typeCheckingMode = 'basic',
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
            },
        },
    },
})

vim.lsp.enable({
    'ts_ls',
    'eslint',
    'pyright',
    'html',
    'cssls',
    'jsonls',
    'yamlls',
})

vim.cmd.colorscheme('gruvbox')

