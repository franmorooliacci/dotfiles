-- ~/.config/nvim/init.lua
-- Neovim 0.11.5 – React / TypeScript / MUI + Django / FastAPI

------------------------------------------------------------
-- Basics
------------------------------------------------------------
vim.g.mapleader = ' '
vim.g.python3_host_prog = vim.fn.exepath('python3.13')

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

-- Auto-reload buffers when modified externally (OpenCode / Git)
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
    pattern = "*",
    command = "if mode() != 'c' | checktime | endif",
})

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
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'neovim/nvim-lspconfig' },

    -- Completion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'L3MON4D3/LuaSnip' },
    { 'saadparwaiz1/cmp_luasnip' },

    -- Editing helpers
    { 'windwp/nvim-ts-autotag', opts = {} },
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
            formatters = {
                prettier = {
                    prepend_args = { '--tab-width', '4' },
                },
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

map('n', '<leader>ff', function() require('telescope.builtin').find_files({hidden = true, previewer = false}) end)
map('n', '<leader>fg', function() require('telescope.builtin').live_grep() end)
map('n', '<leader>fb', function() require('telescope.builtin').buffers() end)
map('n', '<leader>gs', function() require('telescope.builtin').git_status() end, { desc = 'List modified files' })
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

-- Oil navigation
map('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

-- Fast split navigation
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left split' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom split' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to top split' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right split' })

-- Navigate and review agent changes
local gs = package.loaded.gitsigns
map('n', ']c', function()
    if vim.wo.diff then return ']c' end
    vim.schedule(function() gs.next_hunk() end)
    return '<Ignore>'
end, { expr = true, desc = 'Jump to next change' })

map('n', '[c', function()
    if vim.wo.diff then return '[c' end
    vim.schedule(function() gs.prev_hunk() end)
    return '<Ignore>'
end, { expr = true, desc = 'Jump to previous change' })

map('n', '<leader>hp', function() gs.preview_hunk() end, { desc = 'Preview hunk diff' })
map('n', '<leader>gd', function() gs.diffthis() end, { desc = 'Side-by-side Git diff' })

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
require('mason').setup({
    pip = {
        upgrade_pip = true,
        python_path = vim.fn.exepath('python3.13')
    },
})

require('mason-lspconfig').setup({
    ensure_installed = {
        'ts_ls',
        'eslint',
        'basedpyright',
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

vim.lsp.config('basedpyright', {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        basedpyright = {
            analysis = {
                typeCheckingMode = 'basic', 
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticSeverityOverrides = {
                    --------------------------------------------------------
                    -- 1. Django Framework Architecture Fixes
                    --------------------------------------------------------
                    -- Silences errors when overriding inner classes like `class Meta:`
                    reportIncompatibleVariableOverride = "none",
                    -- Silences errors when overriding model methods like `save(*args, **kwargs)`
                    reportIncompatibleMethodOverride = "none",
                    
                    --------------------------------------------------------
                    -- 2. Dynamic Attribute Fixes (The "Django Magic" Rules)
                    --------------------------------------------------------
                    -- Stops errors when using `.objects`, forward/reverse relations (`_set`), or dynamically attached properties
                    reportGeneralTypeIssues = "none",
                    -- Prevents errors when libraries don't ship with explicit typing files (.pyi)
                    reportMissingTypeStubs = "none",

                    --------------------------------------------------------
                    -- 3. Implicit Typings (Prevents the "Type Everything" warnings)
                    --------------------------------------------------------
                    -- Lets you write `fields = [...]` or `model = X` without forcing you to add an explicit type annotation to every single line
                    reportUnknownMemberType = "none",
                    reportUnknownVariableType = "none",
                    reportUnknownArgumentType = "none",
                    reportUninitializedInstanceVariable = "none",
                    
                    --------------------------------------------------------
                    -- 4. Generics Simplification
                    --------------------------------------------------------
                    -- Stops DRF from demanding things like `serializers.ModelSerializer[OrdenCompra]` instead of just `serializers.ModelSerializer`
                    reportMissingTypeArgument = "none",
                },
            },
        },
    },
})

vim.lsp.enable({
    'ts_ls',
    'eslint',
    'basedpyright',
    'html',
    'cssls',
    'jsonls',
    'yamlls',
})

vim.cmd.colorscheme('dracula')

