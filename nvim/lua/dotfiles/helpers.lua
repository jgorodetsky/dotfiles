-- beginner helpers: cheat sheet, cmd+s to save, see-through background, csv/tsv as tables, a first hint.
-- set vim.g.dotfiles_hint = false in options.lua to stop the hint at startup
local M = {}

-- background groups cleared so ghostty's opacity, blur and background image show through
local see_through = { "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "LineNr", "CursorLineNr", "FoldColumn" }

local function clear_backgrounds()
  if not vim.g.dotfiles_transparent then return end
  for _, group in ipairs(see_through) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg, hl.ctermbg = nil, nil
    vim.api.nvim_set_hl(0, group, hl)
  end
end

-- the cheat sheet (cheat.md next to init.lua) in a floating window
local function cheat()
  local lines = vim.fn.readfile(vim.fn.stdpath("config") .. "/cheat.md")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  local width, height = math.min(90, vim.o.columns - 4), math.min(#lines, vim.o.lines - 6)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1, col = math.floor((vim.o.columns - width) / 2),
    title = " cheat sheet - j/k to scroll, q to close ", title_pos = "center",
  })
  for _, key in ipairs({ "q", "<esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = buf, nowait = true })
  end
end

function M.setup()
  vim.g.dotfiles_transparent = vim.g.dotfiles_transparent ~= false
  vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_backgrounds })

  vim.api.nvim_create_user_command("Cheat", cheat, { desc = "Beginner cheat sheet" })
  vim.keymap.set("n", "<leader>C", cheat, { desc = "Cheat sheet" })

  vim.api.nvim_create_user_command("Transparent", function()
    vim.g.dotfiles_transparent = not vim.g.dotfiles_transparent
    vim.cmd.colorscheme(vim.g.colors_name or "default")
  end, { desc = "Toggle see-through background" })

  -- cmd+s and ctrl+s save, like a mac app
  for _, lhs in ipairs({ "<D-s>", "<C-s>" }) do
    vim.keymap.set({ "n", "i", "x" }, lhs, "<cmd>write<cr><esc>", { desc = "Save file" })
  end

  -- csv and tsv files open as a table: aligned columns, borders, header pinned at the top
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "csv", "tsv" },
    callback = function()
      vim.wo.wrap = false
      vim.cmd("CsvViewEnable")
    end,
  })

  if vim.g.dotfiles_hint ~= false then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        vim.defer_fn(function()
          vim.notify("new to vim? :Cheat (or space then C) for the cheat sheet, :Tutor for the built-in lesson.\npress space and wait a second to see what every key does.")
        end, 300)
      end,
    })
  end
end

return M
