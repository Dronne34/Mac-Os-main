-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.cmd([[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight NormalNC guibg=NONE
]])

-- Alt+Up to move the current line above
vim.api.nvim_set_keymap("n", "<A-Up>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Alt+Down to move the current line below
vim.api.nvim_set_keymap("n", "<A-Down>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<A-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })

-- vim.cmd("colorscheme nord")
--
-- Mutare linie în jos cu Shift + Down
vim.keymap.set("n", "<S-Down>", ":m .+1<CR>==", { noremap = true, silent = true })

-- Mutare linie în sus cu Shift + Up
vim.keymap.set("n", "<S-Up>", ":m .-2<CR>==", { noremap = true, silent = true })

-- Pentru mutare pe selecție vizuală:
vim.keymap.set("v", "<S-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

vim.opt.expandtab = true -- convertește tab-urile în spații
vim.opt.shiftwidth = 4 -- 4 spații la indentare cu >> sau <<
vim.opt.tabstop = 4 -- 4 spații pentru un tab vizual
vim.opt.smartindent = true -- indentare inteligentă automată

vim.keymap.set("n", "qq", ":q<CR>")
