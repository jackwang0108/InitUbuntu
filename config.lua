-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- 参考:
--      1. https://www.lunarvim.org/zh-Hans/docs/configuration/options
--      2. https://www.bilibili.com/read/cv22495061/

-- Neovim 可选项:
--    设置可选项:             vim.opt.{option} = {value}
--    查看可选项:             vim.opt.{option}:get()
-- Neovim 变量:
--    设置全局变量:           vim.g.{name} -- global variables (g:)
--    为当前Buffer设置变量:   vim.b.{name} -- variables for the current buffer (b:)
--    为当前窗口设置变量:     vim.w.{name} -- variables for the current window (w:)
--    为当前Tab页设置变量:    vim.t.{name} -- variables for the current tabpage (t:)
--    设置Vim变量:            vim.v.{name} -- predefined Vim variables (v:)
--    设置环境变量:           vim.env.{name} -- environment variables defined in the editor session

-- 使用:help lua-guide-options查看所有设置

-- ========================= 通用设置 =========================
lvim.log.level = "warn"

-- ========================= 外观设置 =========================
-- 配色方案
lvim.colorscheme = "lunar"
-- 透明窗口
lvim.transparent_window = false
-- 底部状态栏
lvim.builtin.lualine.style = "default" -- or "none"

-- ========================= 编辑设置 =========================
-- 1个缩进等价于四个空格
vim.opt.shiftwidth = 4
-- 1个Tab等价于4个空格
vim.opt.tabstop = 4
-- 开启相对行号
vim.opt.relativenumber = true
-- 文本过长时开启折行
vim.opt.wrap = true
-- 根据上一行的缩进来决定是否使用制表符或空格来进行缩进
vim.opt.smarttab = true
-- 由于Tab在不同编辑器显示的宽度不同, 将Tab自动转换为空格
vim.opt.expandtab = true
-- 保存后自动格式化
lvim.format_on_save = true

-- ========================= NeoVIM 键位设置 =========================
-- Leader 键, 默认的Leader键是 Space。 可以通过如下配置更改：
lvim.leader = "space"

-- 不同模式按键映射
--    普通模式下键位映射:      lvim.keys.normal_mode["键位"] = "键位"
--    插入模式下键位映射:      lvim.keys.insert_mode["键位"] = "键位"
--    可视模式下键位映射:      lvim.keys.visual_mode["键位"] = "键位"

-- 删除按键映射：
--    普通模式:               lvim.keys.normal_mode["<C-h>"] = false
--    插入模式:               lvim.keys.insert_mode["<C-h>"] = false
--    可视模式:               lvim.keys.visual_mode["<C-h>"] = false

-- 功能键配置
--    C:        表示 Control 键
--    S:        表示 Shift 键
--    M:        表示 Alt 键（也称为 Meta 键）
--    A:        表示 Command 键（在 macOS 上）或者 Windows 键（在 Windows 上）
--    CR:       表示 回车键
--    <Space>: 表示回车
-- 上面这些按键缩写通常与其他按键组合使用，以创建自定义的键盘映射。例如:
--    <C-S>:    表示同时按下 Control 键和 Shift 键
--    <C-n>:    同时按下 Control 键和字母 "n"
--    <S-Tab>:  按下 Shift 键和 Tab 键
--    <M-x>:    按下 Alt 键（或 Meta 键）和字母 "x"
--    <A-c>:    按下 Command 键（在 macOS 上）或者 Windows 键（在 Windows 上）和字母 "c"

-- 查看键位映射
--    使用 <Leader>sk 来搜索查看当前设置的键位映射
--    普通模式下使用 :map 来查看按键映射

-- ******** 普通模式下键位映射 ********
-- Control+D 映射为向下移动半页
lvim.keys.normal_mode["<C-d>"] = "<C-d>zz"
-- Control+S 映射为保存文件
lvim.keys.normal_mode["<C-s>"] = ":w<CR>"
-- Control+Q 映射为保存文件并退出
lvim.keys.normal_mode["<C-q>"] = ":BufferKill<CR>"
-- lvim.keys.normal_mode["<C-q>"] = ":wq<CR>"
-- Control+/ 映射为注释当前行
lvim.keys.normal_mode["<C-/>"] = "ma<Esc>I-- <Esc>`a"
-- Control+E 打开NVimTree的浏览栏
lvim.keys.normal_mode["<C-e>"] = ":NvimTreeToggle<CR>"
-- Leader+T+F 打开ToggleTerm命令行
lvim.keys.normal_mode["<leader>tf"] = ":ToggleTerm<CR>"
-- Leader+T+F 打开ToggleTerm命令行, tab形式打开
lvim.keys.normal_mode["<leader>tt"] = ":ToggleTerm direction=tab<CR>"
-- Leader+T+F 打开ToggleTerm命令行, 水平打开
lvim.keys.normal_mode["<leader>th"] = ":ToggleTerm direction=horizontal<CR>"
-- Leader+T+F 打开ToggleTerm命令行, 垂直打开
lvim.keys.normal_mode["<leader>tv"] = ":ToggleTerm direction=vertical<CR>"
lvim.keys.normal_mode["<C-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<C-h>"] = ":BufferLineCyclePrev<CR>"
-- Leader + r + n 设置相对行号
lvim.keys.normal_mode["<leader>rn"] = ":set relativenumber<CR>"

-- ******** 插入模式下键位映射 ********
-- jj 映射为Esc键
lvim.keys.insert_mode["jj"] = "<Esc>"
-- Control+S 映射为保存文件
lvim.keys.insert_mode["<C-s>"] = "<Esc>:w<CR>a"
-- Control+Q 映射为保存文件并退出
lvim.keys.insert_mode["<C-q>"] = "<Esc>:wq<CR>"
-- Control+E 打开NVimTree的浏览栏
lvim.keys.normal_mode["<C-e>"] = "<Esc>:NvimTreeToggle<CR>a"

-- ******** 可视模式下键位映射 ********
-- jj 映射为Esc键
-- lvim.keys.visual_mode["jj"] = "<Esc>"

-- ========================= LSP 设置 =========================
-- LunarVIM使用Mason来管理LSP
-- 自动安装LSP
lvim.lsp.installer.setup.automatic_installation = true

-- ========================= Formatter和Linter 设置 =========================
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{ command = "stylua" },
	{
		command = "black",
		filetypes = { "python" },
	},
	-- {
	-- 	command = "prettier",
	-- 	extra_args = { "--print-width", "100" },
	-- 	filetypes = { "typescript", "typescriptreact" },
	-- },
})

local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ command = "flake8", filetypes = { "python" } },
	{
		command = "shellcheck",
		args = { "--severity", "warning" },
	},
	-- {
	--     command = "luacheck",
	--     filetypes = { "lua" },
	-- },
	{
		command = "cpplint",
		filetypes = { "cpp", "c" },
	},
})

-- ========================= 插件设置 =========================
-- LunarVIM 中插件通过 folke/lazy.nvim 管理， 并被分成 核心插件 和 用户插件 两类。
-- 使用 :Lazy 来查看所有已安装的插件
-- 1. 核心插件随LunarVIM安装而安装, 其配置通过 lvim.builtin 表访问
-- 2. 用户插件需用户手动安装, 可通将条目添加到 config.lua 文件中的 lvim.plugins 表来安装用户插件,
--    保存或手动调用 LvimReload 将触发延迟同步用户插件. 用户插件的配置同样保存在 lvim.plugins中

-- 禁用核心插件, 大多数核心插件包含一个 active 属性，可以将其设置为 false 以禁用插件
--    lvim.builtin.alpha.active = true
--    lvim.builtin.dap.active = true

-- ******** 核心插件设置 ********
-- => ToggleTerm插件设置
lvim.builtin.terminal.active = true
-- 打开内建命令行绑定到 Control+T
lvim.builtin.terminal.open_mapping = "<C-t>"

-- => alpha插件设置
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"

-- => Telescope插件设置
-- lvim.builtin.telescope.on_config_done = function(telescope)
--     pcall(telescope.load_extension, "telescope-fzy-native")
--     pcall(telescope.load_extension, "telescope-project")
--     pcall(telescope.load_extension, "frecency")
--     pcall(telescope.load_extension, "neoclip")
--     -- any other extensions loading
-- end

-- => TreeSitter插件设置: 开启彩色圆括号
lvim.builtin.treesitter.rainbow.enable = true
lvim.builtin.treesitter.highlight.enabled = true
lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.ensure_installed = {
	"bash",
	"c",
	"javascript",
	"json",
	"lua",
	"python",
	"typescript",
	"tsx",
	"css",
	"rust",
	"java",
	"yaml",
}

-- => NVimTree设置
-- lvim.builtin.nvimtree.setup.auto_open = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.view.centralize_selection = true
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true
lvim.builtin.nvimtree.setup.renderer.icons.glyphs.folder.arrow_open = ""
lvim.builtin.nvimtree.setup.renderer.icons.glyphs.folder.arrow_closed = ""
-- lvim.builtin.nvimtree.setup.renderer.icons.glyphs.folder.open = ""
-- lvim.builtin.nvimtree.setup.renderer.icons.glyphs.folder.default = ""
-- lvim.builtin.nvimtree.setup.renderer.icons.glyphs.folder.empty = ""
-- lvim.builtin.nvimtree.setup.renderer.icons.glyphs.folder.symlink = ""
-- lvim.builtin.nvimtree.setup.view.cursor = false

-- => WhichKey设置
lvim.builtin.which_key.mappings["e"] = {
	name = "+自定义按键",
	f = { "<cmd>NvimTreeToggle<CR>", "NvimTree打开/关闭文件浏览" },
	n = { "<cmd>Telescope notify<CR>", "Nvim-Notify查看消息" },
	s = { "<cmd>SymbolsOutline<CR>", "Symbols-outline.Nvim打开/关闭符号大纲" },
	t = {
		name = "+ToggleTerm打开命令行",
		t = { "<cmd>ToggleTerm direction=tab<CR>", "页面式命令行" },
		f = { "<cmd>ToggleTerm direction=float<CR>", "悬浮式命令行" },
		v = { "<cmd>ToggleTerm direction=vertical<CR>", "垂直式命令行" },
		h = { "<cmd>ToggleTerm direction=horizontal<CR>", "水平式命令行" },
	},
}

-- => Mason插件设置
-- 设置日志等级
lvim.builtin.mason.log_level = vim.log.levels.INFO
-- LSP并行下载数
lvim.builtin.mason.max_concurrent_installers = 4
-- LSP源, 支持多个源
lvim.builtin.mason.registries = {
	"github:mason-org/mason-registry",
}

-- 设置交互界面LSP标志
lvim.builtin.mason.ui.icons = {
	package_installed = "✓",
	package_pending = "➜",
	package_uninstalled = "✗",
}

-- ******** 用户插件设置 ********
-- 常用用户插件配置:  https://www.lunarvim.org/zh-Hans/docs/configuration/plugins/example-configurations
lvim.plugins = {
	{
		-- vim-surround 是一个非常流行的 Vim 插件，用于快速添加、修改和删除周围字符（surroundings）。它可以帮助您在编辑文本时更高效地操作和修改周围的字符，提高编辑速度和准确性。
		"tpope/vim-surround",
		-- make sure to change the value of `timeoutlen` if it's not triggering correctly
		-- see https://github.com/tpope/vim-surround/issues/117
		init = function()
			vim.o.timeoutlen = 500
		end,
	},
	{
		-- folke/trouble.nvim是一个为Neovim设计的插件，旨在提供一个更好的问题和错误浏览体验。该插件可以帮助开发者更轻松地浏览和导航代码中的问题和错误
		"folke/trouble.nvim",
		cmd = "TroubleToggle",
	},
	{
		-- "lukas-reineke/indent-blankline.nvim"是一个Neovim插件，用于在编辑器中显示缩进线，以提高代码的可读性和可视化效果。它可以帮助开发者更清晰地看到代码中的缩进层次结构。
		"lukas-reineke/indent-blankline.nvim",
	},
	-- {
	--     -- 自动保存 插件
	--     "Pocco81/auto-save.nvim",
	--     config = function()
	--         require("auto-save").setup()
	--     end,
	-- },
	{
		-- vim-cursorword 是一个 Vim 插件，用于在当前光标所在单词的出现位置进行高亮显示。它可以帮助您更好地定位和识别当前编辑的单词，提高代码编辑的准确性和可视化效果。
		"itchyny/vim-cursorword",
		event = { "BufEnter", "BufNewFile" },
		config = function()
			vim.api.nvim_command("augroup user_plugin_cursorword")
			vim.api.nvim_command("autocmd!")
			vim.api.nvim_command("autocmd FileType NvimTree,lspsagafinder,dashboard,vista let b:cursorword = 0")
			vim.api.nvim_command("autocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endif")
			vim.api.nvim_command("autocmd InsertEnter * let b:cursorword = 0")
			vim.api.nvim_command("autocmd InsertLeave * let b:cursorword = 1")
			vim.api.nvim_command("augroup END")
		end,
	},
	{
		-- 增强VIM "." 的插件
		"tpope/vim-repeat",
	},
	-- {
	--     -- 该插件已经弃用, 使用新版的rainbow-delimiters.nvim
	--     -- nvim-ts-rainbow2 是一个 NeoVim 插件，用于在代码编辑器中为括号和其他符号添加彩虹色的高亮显示。它可以帮助您更好地理解和识别代码中的嵌套结构，提高代码的可读性和可视化效果。
	--     "HiPhish/nvim-ts-rainbow2",
	--     lazy = true,
	--     event = { "User FileOpened" },
	-- },
	{
		"HiPhish/rainbow-delimiters.nvim",
		lazy = true,
		event = { "User FileOpened" },
		config = function()
			require("rainbow-delimiters.setup").setup({
				strategy = {
					-- [''] = rainbow_delimiters.strategy['global'],
					-- vim = rainbow_delimiters.strategy['local'],
				},
				query = {
					[""] = "rainbow-delimiters",
					lua = "rainbow-blocks",
				},
				priority = {
					[""] = 110,
					lua = 210,
				},
				highlight = {
					"RainbowDelimiterRed",
					"RainbowDelimiterYellow",
					"RainbowDelimiterBlue",
					"RainbowDelimiterOrange",
					"RainbowDelimiterGreen",
					"RainbowDelimiterViolet",
					"RainbowDelimiterCyan",
				},
			})
		end,
	},
	{
		-- goto-preview 是一个 NeoVim 插件，旨在提供代码导航和预览功能。它可以帮助您快速浏览和跳转到代码中的定义、引用和其他相关位置，从而提高代码阅读和编辑的效率。
		"rmagatti/goto-preview",
		lazy = true,
		keys = { "gp" },
		config = function()
			require("goto-preview").setup({
				width = 120,
				height = 25,
				default_mappings = true,
				debug = false,
				opacity = nil,
				post_open_hook = nil,
				-- You can use "default_mappings = true" setup option
				-- vim.cmd("nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>")
				-- vim.cmd("nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
				-- vim.cmd("nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>")
			})
		end,
	},
	{
		-- nvim-lastplace 是一个 NeoVim 插件，用于在文件中记住上次编辑的位置，并在下次打开文件时将光标自动定位到上次编辑的位置。这个插件可以提高编辑工作流的效率，让您无需手动滚动到上次编辑的位置。
		"ethanholz/nvim-lastplace",
		lazy = true,
		event = { "BufRead" },
		config = function()
			require("nvim-lastplace").setup({
				lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
				lastplace_ignore_filetype = {
					"gitcommit",
					"gitrebase",
					"svn",
					"hgcommit",
				},
				lastplace_open_folds = true,
			})
		end,
	},
	{
		-- nvim-spectre 是一个针对 NeoVim 的插件，旨在提供快速而强大的搜索和替换功能。它可以帮助您在代码库中快速查找、替换和预览文本，从而提高编辑效率。
		"windwp/nvim-spectre",
		lazy = true,
		cmd = { "Spectre" },
		config = function()
			require("spectre").setup()
		end,
	},
	{
		-- marks.nvim 是一个 NeoVim 插件，旨在增强标记（marks）在编辑器中的使用和管理。它提供了一组功能和命令，使您能够更方便地创建、导航和管理标记，从而提高编辑效率。
		"chentoast/marks.nvim",
		lazy = true,
		event = { "User FileOpened" },
		config = function()
			require("marks").setup({
				default_mappings = true,
				-- builtin_marks = { ".", "<", ">", "^" },
				cyclic = true,
				force_write_shada = false,
				refresh_interval = 250,
				sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
				excluded_filetypes = {
					"qf",
					"NvimTree",
					"toggleterm",
					"TelescopePrompt",
					"alpha",
					"netrw",
				},
				bookmark_0 = {
					sign = "",
					virt_text = "hello world",
					annotate = false,
				},
				mappings = {},
			})
		end,
	},
	{
		-- 将没有使用到的变量进行暗淡处理
		"zbirenbaum/neodim",
		event = "LspAttach",
		config = function()
			require("neodim").setup({
				alpha = 0.75,
				blend_color = "#000000",
				hide = {
					underline = true,
					virtual_text = true,
					signs = true,
				},
				regex = {
					"[uU]nused",
					"[nN]ever [rR]ead",
					"[nN]ot [rR]ead",
				},
				priority = 128,
				disable = {},
			})
		end,
	},
	{
		-- windows.nvim 是一个 NeoVim 插件，旨在提供更强大的窗口管理功能。它扩展了 NeoVim 的默认窗口管理功能，使您能够更方便地操作和组织编辑器中的窗口。
		"anuvyklack/windows.nvim",
		lazy = true,
		cmd = { "WindowsMaximize", "WindowsMaximizeVertically", "WindowsMaximizeHorizontally", "WindowsEqualize" },
		dependencies = {
			"anuvyklack/middleclass",
			"anuvyklack/animation.nvim",
		},
		config = function()
			vim.o.winwidth = 10
			vim.o.winminwidth = 10
			vim.o.equalalways = false
			require("windows").setup({
				autowidth = {
					enable = false,
				},
				ignore = {
					buftype = { "quickfix" },
					filetype = {
						"NvimTree",
						"neo-tree",
						"undotree",
						"gundo",
						"qf",
						"toggleterm",
						"TelescopePrompt",
						"alpha",
						"netrw",
					},
				},
			})
		end,
	},
	{
		-- nvim-notify 是一个用于在 NeoVim 编辑器中显示通知消息的插件。它可以帮助您在编辑代码时获取重要的提示、警告或其他通知。
		"rcarriga/nvim-notify",
		lazy = true,
		event = "VeryLazy",
		config = function()
			local notify = require("notify")
			notify.setup({
				-- "fade", "slide", "fade_in_slide_out", "static"
				stages = "slide",
				on_open = nil,
				on_close = nil,
				timeout = 5000,
				fps = 10,
				-- default, minimal, simple, wrapped-compact
				render = "default",
				background_colour = "Normal",
				max_width = math.floor(vim.api.nvim_win_get_width(0) / 2),
				max_height = math.floor(vim.api.nvim_win_get_height(0) / 4),
				-- minimum_width = 50,
				-- ERROR > WARN > INFO > DEBUG > TRACE
				level = "TRACE",
			})

			vim.notify = notify
		end,
	},
	{
		-- 在打开的多个窗口快速跳转、交换
		"s1n7ax/nvim-window-picker",
		lazy = true,
		event = { "WinNew" },
		config = function()
			local picker = require("window-picker")
			picker.setup({
				autoselect_one = true,
				include_current = false,
				filter_rules = {
					bo = {
						filetype = { "neo-tree", "neo-tree-popup", "notify", "quickfix" },
						buftype = { "terminal" },
					},
				},
				other_win_hl_color = "#e35e4f",
			})

			vim.keymap.set("n", ",w", function()
				local picked_window_id = picker.pick_window({
					include_current_win = true,
				}) or vim.api.nvim_get_current_win()
				vim.api.nvim_set_current_win(picked_window_id)
			end, { desc = "Pick a window" })

			-- Swap two windows using the awesome window picker
			local function swap_windows()
				local window = picker.pick_window({
					include_current_win = false,
				})
				local target_buffer = vim.fn.winbufnr(window)
				-- Set the target window to contain current buffer
				vim.api.nvim_win_set_buf(window, 0)
				-- Set current window to contain target buffer
				vim.api.nvim_win_set_buf(0, target_buffer)
			end

			vim.keymap.set("n", ",W", swap_windows, { desc = "Swap windows" })
		end,
	},
	{
		-- symbols-outline.nvim 是一个用于在 NeoVim 编辑器中显示代码符号大纲的插件。它可以帮助您快速浏览和导航代码文件中的函数、变量、类等符号。
		"simrat39/symbols-outline.nvim",
		lazy = true,
		cmd = { "SymbolsOutline", "SymbolsOutlineOpen", "SymbolsOutlineClose" },
		config = function()
			local opts = {
				highlight_hovered_item = true,
				show_guides = true,
				auto_preview = false,
				position = "right",
				relative_width = true,
				width = 25,
				auto_close = false,
				show_numbers = false,
				show_relative_numbers = false,
				show_symbol_details = true,
				preview_bg_highlight = "Pmenu",
				autofold_depth = nil,
				auto_unfold_hover = true,
				fold_markers = { "", "" },
				wrap = false,
				keymaps = { -- These keymaps can be a string or a table for multiple keys
					close = { "<Esc>", "q" },
					goto_location = "<Cr>",
					focus_location = "o",
					hover_symbol = "<C-space>",
					toggle_preview = "K",
					rename_symbol = "r",
					code_actions = "a",
					fold = "h",
					unfold = "l",
					fold_all = "P",
					unfold_all = "U",
					fold_reset = "Q",
				},
				lsp_blacklist = {},
				symbol_blacklist = {},
				symbols = {
					File = { icon = "", hl = "@text.uri" },
					Module = { icon = "", hl = "@namespace" },
					Namespace = { icon = "", hl = "@namespace" },
					Package = { icon = "", hl = "@namespace" },
					Class = { icon = "𝓒", hl = "@type" },
					Method = { icon = "ƒ", hl = "@method" },
					Property = { icon = "", hl = "@method" },
					Field = { icon = "", hl = "@field" },
					Constructor = { icon = "", hl = "@constructor" },
					Enum = { icon = "", hl = "@type" },
					Interface = { icon = "ﰮ", hl = "@type" },
					Function = { icon = "", hl = "@function" },
					Variable = { icon = "", hl = "@constant" },
					Constant = { icon = "", hl = "@constant" },
					String = { icon = "𝓐", hl = "@string" },
					Number = { icon = "#", hl = "@number" },
					Boolean = { icon = "", hl = "@boolean" },
					Array = { icon = "", hl = "@constant" },
					Object = { icon = "", hl = "@type" },
					Key = { icon = "🔐", hl = "@type" },
					Null = { icon = "NULL", hl = "@type" },
					EnumMember = { icon = "", hl = "@field" },
					Struct = { icon = "𝓢", hl = "@type" },
					Event = { icon = "🗲", hl = "@type" },
					Operator = { icon = "+", hl = "@operator" },
					TypeParameter = { icon = "𝙏", hl = "@parameter" },
					Component = { icon = "󰡀", hl = "@function" },
					Fragment = { icon = "", hl = "@constant" },
				},
			}
			require("symbols-outline").setup(opts)
		end,
	},
	{
		-- 打开多窗口时，在当前焦点窗口周围显示紫色的边框
		"nvim-zh/colorful-winsep.nvim",
		lazy = true,
		event = "WinNew",
		config = function()
			require("colorful-winsep").setup()
		end,
	},
	{
		-- 一款很强大的临时轨迹标记插件，它可以使用快捷键保存你当前的位置，然后安心地把光标移到其它地方，之后再按快捷键按顺序跳回原来记录的位置
		"LeonHeidelbach/trailblazer.nvim",
		lazy = true,
		keys = { "<A-s>", "<A-d>" },
		config = function()
			-- local HOME = os.getenv("HOME")
			require("trailblazer").setup({
				auto_save_trailblazer_state_on_exit = false,
				auto_load_trailblazer_state_on_enter = false,
				-- custom_session_storage_dir = HOME .. "/.local/share/trail_blazer_sessions/",
				trail_options = {
					mark_symbol = "•", --  will only be used if trail_mark_symbol_line_indicators_enabled = true
					newest_mark_symbol = "󰝥", -- disable this mark symbol by setting its value to ""
					cursor_mark_symbol = "󰺕", -- disable this mark symbol by setting its value to ""
					next_mark_symbol = "󰬦", -- disable this mark symbol by setting its value to ""
					previous_mark_symbol = "󰬬", -- disable this mark symbol by setting its value to ""
				},
				mappings = {
					nv = {
						motions = {
							new_trail_mark = "<A-s>",
							track_back = "<A-d>",
							peek_move_next_down = "<A-J>",
							peek_move_previous_up = "<A-K>",
							move_to_nearest = "<A-n>",
							toggle_trail_mark_list = "<A-o>",
						},
						actions = {
							delete_all_trail_marks = "<A-L>",
							paste_at_last_trail_mark = "<A-p>",
							paste_at_all_trail_marks = "<A-P>",
							set_trail_mark_select_mode = "<A-t>",
							switch_to_next_trail_mark_stack = "<A-.>",
							switch_to_previous_trail_mark_stack = "<A-,>",
							set_trail_mark_stack_sort_mode = "<A-S>",
						},
					},
				},
				quickfix_mappings = { -- rename this to "force_quickfix_mappings" to completely override default mappings and not merge with them
					-- nv = {
					-- 	motions = {
					-- 		qf_motion_move_trail_mark_stack_cursor = "<CR>",
					-- 	},
					-- 	actions = {
					-- 		qf_action_delete_trail_mark_selection = "d",
					-- 		qf_action_save_visual_selection_start_line = "v",
					-- 	},
					-- 	alt_actions = {
					-- 		qf_action_save_visual_selection_start_line = "V",
					-- 	},
					-- },
					-- v = {
					-- 	actions = {
					-- 		qf_action_move_selected_trail_marks_down = "<C-j>",
					-- 		qf_action_move_selected_trail_marks_up = "<C-k>",
					-- 	},
					-- },
				},
			})
		end,
	},
	{
		-- nvim-recorder 是一个 NeoVim 插件，它允许您记录和回放编辑会话。它可以捕捉您在编辑器中执行的操作，并将其保存为宏，以便稍后重放
		"chrisgrieser/nvim-recorder",
		lazy = true,
		keys = { "q", "Q", "<A-q>", "cq", "yq" },
		config = function()
			require("recorder").setup({
				slots = { "u", "i", "o" },
				mapping = {
					startStopRecording = "q",
					playMacro = "Q",
					switchSlot = "<A-q>",
					editMacro = "cq",
					yankMacro = "yq",
					-- addBreakPoint = "##",
				},
			})
		end,
	},
	-- {
	--  -- 快速跳转还是使用Sneak系的更好， Easymotion系眼睛疼
	-- 	-- hop.nvim 提供了一种快速跳转到文本中指定位置的方式，以提高编辑效率。
	-- 	"smoka7/hop.nvim",
	-- 	-- tag = "*",
	-- 	event = "BufRead",
	-- 	config = function()
	-- 		require("hop").setup({
	-- 			keys = "qwerasdfg",
	-- 		})
	-- 		-- vim.api.nvim_set_keymap("n", "s", ":HopChar2<cr>", { silent = true })
	-- 		-- vim.api.nvim_set_keymap("n", "S", ":HopWord<cr>", { silent = true })
	-- 	end,
	-- },
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		-- -@type Flash.Config
		opts = {},
        -- stylua: ignore
        keys = {
            { "?", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            { "'", mode = { "n", "x", "o" }, function() require("flash").jump(
                {search = {mode = "search", max_length = 0}, label = {after = {0, 0}}, pattern = "^"}
            ) end, desc = "Flash" },
            { "s", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
            { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
        },
	},
	{
		-- diffview 是一个 NeoVim 插件，它提供了一个交互式的界面，用于查看和管理 Git 仓库中的文件差异。
		"sindrets/diffview.nvim",
		event = "BufRead",
	},
	{
		-- nvim-colorizer 是一个 NeoVim 插件，它提供了代码颜色标记的功能，使得代码中的颜色值能够在编辑器中得到正确的显示。
		-- 在编写代码时，经常会使用颜色值来定义样式或者进行调试。然而，这些颜色值通常以十六进制或者 RGB 格式表示，对于人眼来说并不直观。nvim-colorizer 插件通过解析代码中的颜色值，并将其正确地显示为对应的颜色块
		"norcalli/nvim-colorizer.lua",
		event = "BufRead",
		config = function()
			require("colorizer").setup({ "css", "scss", "html", "javascript" }, {
				RGB = true, -- #RGB hex codes
				RRGGBB = true, -- #RRGGBB hex codes
				RRGGBBAA = true, -- #RRGGBBAA hex codes
				rgb_fn = true, -- CSS rgb() and rgba() functions
				hsl_fn = true, -- CSS hsl() and hsla() functions
				css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
				css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
			})
		end,
	},
	{
		-- telescope-file-browser.nvim 是一个用于文件浏览和导航的 Neovim 插件。它是基于 telescope.nvim 插件构建的，提供了一个更直观和交互性更强的文件浏览器界面。
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
	{
		-- telescope-fzy-native.nvim 是 Telescope 插件的一个扩展，它提供了更快速和更高效的模糊搜索算法。它使用了 fzy 算法，这是一个优化过的模糊搜索算法，可以在大型数据集上提供更快的搜索速度。
		"nvim-telescope/telescope-fzy-native.nvim",
		build = "make",
		event = "BufRead",
	},
	{
		"f-person/git-blame.nvim",
		event = "BufRead",
		config = function()
			vim.cmd("highlight default link gitblame SpecialComment")
			vim.g.gitblame_enabled = 0
		end,
	},
	{
		-- fugitive.nvim 与 Git 版本控制系统进行集成。它提供了一组功能强大的命令和快捷键，可以在 Vim 中方便地执行 Git 操作。
		"tpope/vim-fugitive",
		cmd = {
			"G",
			"Git",
			"Gdiffsplit",
			"Gread",
			"Gwrite",
			"Ggrep",
			"GMove",
			"GDelete",
			"GBrowse",
			"GRemove",
			"GRename",
			"Glgrep",
			"Gedit",
		},
		ft = { "fugitive" },
	},
	{
		-- nvim-ts-autotag 是一个适用于 Neovim 的插件，用于自动添加和更新 HTML、XML 和 JSX 标签的闭合标记。
		-- 它是基于 Tree-sitter 解析器的，可以在编辑这些类型文件时自动检测标签，并确保标签的闭合是正确的和完整的。
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		-- vim-gist 是一个适用于 Vim 和 Neovim 的插件，用于与 GitHub Gist 进行交互。
		-- GitHub Gist 是一个在线代码片段分享和存储服务，而 vim-gist 插件使得在 Vim 中创建、编辑和管理 Gist 变得更加方便。
		"mattn/vim-gist",
		event = "BufRead",
		dependencies = "mattn/webapi-vim",
	},
	-- {
	--     -- -nvim-ts-rainbow 通过treesitter解析代码后得到的匹配圆括号进行彩色显示
	--     "p00f/nvim-ts-rainbow",
	-- },
	{
		-- playground 插件直接展示treesitter的上下文信息
		"nvim-treesitter/playground",
		event = "BufRead",
	},
	{
		-- 为neovim新增很多textobjects，它们可以丰富你的快捷键选中、复制、修改等操作的体验
		-- 例如, viS选中当前光标下的子word（如VimEnter，我们使用viw会选中整个VimEnter，但viS只会选中Enter或Vim）
		"chrisgrieser/nvim-various-textobjs",
		lazy = true,
		event = { "User FileOpened" },
		config = function()
			require("various-textobjs").setup({
				useDefaultKeymaps = true,
				lookForwardLines = 10,
			})
			-- example: `an` for outer subword, `in` for inner subword
			vim.keymap.set({ "o", "x" }, "aS", function()
				require("various-textobjs").subword(false)
			end)
			vim.keymap.set({ "o", "x" }, "iS", function()
				require("various-textobjs").subword(true)
			end)
		end,
	},
	{
		-- 本插件基于nvim-treesitter，根据当前光标在文中的位置，配合Comment.nvim，自动选择合适的注释格式
		"JoosepAlviste/nvim-ts-context-commentstring",
		lazy = true,
		event = { "User FileOpened" },
	},
	{
		-- nvim-treesitter-context是一款基于nvim-treesitter的上文文固定插件。
		-- 它可以将当前函数的函数头固定在neovim界面的前几行，让你知道当前在编辑的是什么类、函数或方法
		"romgrk/nvim-treesitter-context",
		lazy = true,
		event = { "User FileOpened" },
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				throttle = true,
				max_lines = 0, -- Maximum number of lines to show for a single context
				line_numbers = true,
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				multiline_threshold = 20,
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
	{
		-- nvim-treesitter-textobjects 是一个 NeoVim 插件，它通过利用 Treesitter 引擎的语法解析功能，提供了更精确和灵活的文本对象选择器，以便在编辑代码时进行更精确的操作
		"nvim-treesitter/nvim-treesitter-textobjects",
		lazy = true,
		commit = "73e44f43c70289c70195b5e7bc6a077ceffddda4",
		event = { "User FileOpened" },
		after = "nvim-treesitter",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter.configs").setup({
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
							["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
							["id"] = "@conditional.inner",
							["ad"] = "@conditional.outer",
						},
						selection_modes = {
							["@parameter.outer"] = "v", -- charwise
							["@function.outer"] = "V", -- linewise
							["@class.outer"] = "<c-v>", -- blockwise
						},
						include_surrounding_whitespace = false,
					},
					move = {
						enable = true,
						set_jumps = true,
						goto_next_start = {
							["]m"] = "@function.outer",
							["]]"] = { query = "@class.outer", desc = "Next class start" },
							--
							-- You can use regex matching and/or pass a list in a "query" key to group multiple queires.
							["]o"] = "@loop.*",
							-- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
							--
							-- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
							-- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
							["]s"] = { query = "@scope", query_group = "locals", desc = "Next scope" },
							["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
						},
						goto_next_end = {
							["]M"] = "@function.outer",
							["]["] = "@class.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
							["[["] = "@class.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
							["[]"] = "@class.outer",
						},
						-- Below will go to either the start or the end, whichever is closer.
						-- Use if you want more granular movements
						-- Make it even more gradual by adding multiple queries and regex.
						goto_next = {
							["]d"] = "@conditional.outer",
						},
						goto_previous = {
							["[d"] = "@conditional.outer",
						},
					},
					swap = {
						enable = false,
						swap_next = {
							["<leader>a"] = "@parameter.inner",
						},
						swap_previous = {
							["<leader>A"] = "@parameter.inner",
						},
					},
				},
			})
			local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

			-- Repeat movement with ; and ,
			-- ensure ; goes forward and , goes backward regardless of the last direction
			vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
			vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

			-- vim way: ; goes to the direction you were moving.
			-- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
			-- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

			-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
			-- vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f)
			-- vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F)
			-- vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t)
			-- vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T)
		end,
	},
	{
		-- folke/todo-comments.nvim 是一个 Neovim 编辑器的插件，用于在代码中管理和突出显示待办事项、注释和标记。
		"folke/todo-comments.nvim",
		event = "BufRead",
		config = function()
			require("todo-comments").setup()
		end,
	},
	{
		-- trouble.nvim 是一个 Neovim 编辑器的插件，用于在代码编辑过程中显示和导航错误、警告、TODO 注释等问题。
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	{
		-- kevinhwang91/nvim-hlslens 是一个用于 Neovim 编辑器的插件，旨在增强代码编辑体验。它提供了一种突出显示和导航代码中的符号的方式，使得阅读和编辑代码更加方便。
		"kevinhwang91/nvim-hlslens",
		event = "VimEnter",
		config = function()
			require("hlslens").setup({
				override_lens = function(render, posList, nearest, idx, relIdx)
					local sfw = vim.v.searchforward == 1
					local indicator, text, chunks
					local absRelIdx = math.abs(relIdx)
					if absRelIdx > 1 then
						indicator = ("%d%s"):format(absRelIdx, sfw ~= (relIdx > 1) and "▲" or "▼")
					elseif absRelIdx == 1 then
						indicator = sfw ~= (relIdx == 1) and "▲" or "▼"
					else
						indicator = ""
					end
					local lnum, col = unpack(posList[idx])
					if nearest then
						local cnt = #posList
						if indicator ~= "" then
							text = ("[%s %d/%d]"):format(indicator, idx, cnt)
						else
							text = ("[%d/%d]"):format(idx, cnt)
						end
						chunks = { { " ", "Ignore" }, { text, "HlSearchLensNear" } }
					else
						text = ("[%s %d]"):format(indicator, idx)
						chunks = { { " ", "Ignore" }, { text, "HlSearchLens" } }
					end
					render.setVirt(0, lnum - 1, col - 1, chunks, nearest)
				end,
			})
			vim.keymap.set("", "n", function()
				require("hlslens").start()
				if vim.v.searchforward == 1 then
					return "n"
				else
					return "N"
				end
			end, { expr = true })
			vim.keymap.set("", "N", function()
				require("hlslens").start()
				if vim.v.searchforward == 1 then
					return "N"
				else
					return "n"
				end
			end, { expr = true })
		end,
	},
	{
		-- petertriho/nvim-scrollbar 是一个用于 Neovim 编辑器的插件，用于定制和增强编辑器的滚动条功能。它可以帮助您在编辑器中显示滚动条，并提供各种配置选项来满足您的需求。
		"petertriho/nvim-scrollbar",
		event = "BufRead",
		config = function()
			require("scrollbar").setup({
				handlers = {
					cursor = true,
					diagnostic = true,
					gitsigns = true,
					handle = true,
					search = true,
				},
			})
		end,
	},
	{
		-- MattesGroeger/vim-bookmarks 是一个用于 Vim 编辑器的插件，旨在帮助您在代码中创建和管理书签，以便更轻松地导航和编辑代码。
		"MattesGroeger/vim-bookmarks",
		event = "BufRead",
		init = function()
			vim.g.bookmark_sign = ""
			vim.g.bookmark_annotation_sign = ""
			vim.g.bookmark_display_annotation = 1
			vim.g.bookmark_no_default_key_mappings = 1
			vim.g.bookmark_auto_save_file = join_paths(get_cache_dir(), "vim-bookmarks")
		end,
		config = function()
			-- vim.cmd('highlight BookmarkAnnotationSignDefault guifg=' .. colors_palette.yellow)
			-- vim.cmd('highlight BookmarkSignDefault guifg=' .. colors_palette.yellow)
			require("which-key").register({
				m = { "<Plug>BookmarkToggle", "Toggle bookmark" },
				i = { "<Plug>BookmarkAnnotate", "Annotate bookmark" },
				n = { "m'<Plug>BookmarkNext", "Next bookmark" },
				p = { "m'<Plug>BookmarkPrev", "Previous bookmark" },
				c = { "<Plug>BookmarkClear", "Clear bookmarks in current file" },
				C = { "<Plug>BookmarkClearAll", "Clear all bookmarks" },
				j = { "<Plug>BookmarkMoveDown", "Move bookmark down" },
				k = { "<Plug>BookmarkMoveUp", "Move bookmark up" },
				g = { "<Plug>BookmarkMoveToLine", "Move bookmark to specified line" },
			}, { prefix = "m", noremap = false })
		end,
	},
	{
		"romgrk/barbar.nvim",
		dependencies = {
			"lewis6991/gitsigns.nvim", -- OPTIONAL: for git status
			"nvim-tree/nvim-web-devicons", -- OPTIONAL: for file icons
		},
		init = function()
			vim.g.barbar_auto_setup = false
		end,
		opts = {
			-- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
			-- animation = true,
			-- insert_at_start = true,
			-- …etc.
		},
		version = "^1.0.0", -- optional: only update when a new 1.x version is released
	},
}
