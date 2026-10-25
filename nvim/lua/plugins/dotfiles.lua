-- additions on top of the lazyvim starter: colors from ghostty, extra themes, table view, bash support
return {
  { "nvim-mini/mini.base16", lazy = false, priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "LazyVim/LazyVim", opts = { colorscheme = "ghostty" } },
  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    opts = function() return require("dotfiles.csv") end,
  },
  { "neovim/nvim-lspconfig", opts = { servers = { bashls = {} } } },
  { "mason-org/mason.nvim", opts = { ensure_installed = { "shellcheck" } } },
}
