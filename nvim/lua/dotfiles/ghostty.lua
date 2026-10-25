-- builds a neovim color theme from whichever ghostty theme is active, so the editor matches the terminal.
-- reads the theme name from the ghostty config, finds that theme file, and maps its 16 colors onto base16
local M = {}

local function first_existing(paths)
  for _, p in ipairs(paths) do
    p = vim.fn.expand(p)
    if vim.uv.fs_stat(p) then return p end
  end
end

-- "theme = light:a,dark:b" uses the dark side
function M.theme_name()
  local cfg = first_existing({ "~/Library/Application Support/com.mitchellh.ghostty/config", "~/.config/ghostty/config" })
  if not cfg then return nil end
  local name
  for line in io.lines(cfg) do
    local v = line:match("^%s*theme%s*=%s*(.-)%s*$")
    if v and v ~= "" then name = v end
  end
  if name and name:find(":") then name = name:match("dark:([^,]+)") or name:match(":([^,]+)") end
  return name and vim.trim(name)
end

local function theme_file(name)
  if name:sub(1, 1) == "/" then return first_existing({ name }) end
  return first_existing({ "~/.config/ghostty/themes/" .. name, "/Applications/Ghostty.app/Contents/Resources/ghostty/themes/" .. name })
end

local function read(path)
  local c = { palette = {} }
  for line in io.lines(path) do
    local i, hex = line:match("^%s*palette%s*=%s*(%d+)%s*=%s*#?(%x%x%x%x%x%x)")
    if i then c.palette[tonumber(i)] = "#" .. hex:lower() end
    for _, key in ipairs({ "background", "foreground", "selection%-background" }) do
      local v = line:match("^%s*" .. key .. "%s*=%s*#?(%x%x%x%x%x%x)")
      if v then c[key:gsub("%%", "")] = "#" .. v:lower() end
    end
  end
  return c
end

local function blend(a, b, t)
  local out = "#"
  for i = 2, 6, 2 do
    local x, y = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    out = out .. string.format("%02x", math.floor(x * (1 - t) + y * t + 0.5))
  end
  return out
end

local function is_dark(hex)
  local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 < 0.5
end

-- base00-07 run from background to foreground, base08-0f are the accent colors
local function base16(c)
  local p = c.palette
  local bg, fg = c.background or p[0], c.foreground or p[7]
  local function pc(i) return p[i] or fg end
  return {
    base00 = bg,
    base01 = blend(bg, fg, 0.07),
    base02 = c["selection-background"] or blend(bg, fg, 0.18),
    base03 = blend(bg, fg, 0.45),
    base04 = blend(bg, fg, 0.65),
    base05 = fg,
    base06 = blend(fg, pc(15), 0.5),
    base07 = pc(15),
    base08 = pc(1),
    base09 = blend(pc(1), pc(3), 0.5),
    base0A = pc(3),
    base0B = pc(2),
    base0C = pc(6),
    base0D = pc(4),
    base0E = pc(5),
    base0F = p[13] or pc(5),
  }
end

function M.apply()
  local name = M.theme_name()
  local file = name and theme_file(name)
  if not file then
    vim.notify("ghostty theme not found, using neovim's default colors", vim.log.levels.WARN)
    vim.cmd.colorscheme("default")
    return
  end
  local palette = base16(read(file))
  vim.o.background = is_dark(palette.base00) and "dark" or "light"
  require("mini.base16").setup({ palette = palette, use_cterm = true })
  vim.g.colors_name = "ghostty"
  M.loaded = name

  -- switching themes in ghostty (gtheme) recolors neovim the next time its window gets focus
  vim.api.nvim_create_autocmd("FocusGained", {
    group = vim.api.nvim_create_augroup("dotfiles_ghostty_theme", { clear = true }),
    callback = function()
      if vim.g.colors_name == "ghostty" and M.theme_name() ~= M.loaded then vim.cmd.colorscheme("ghostty") end
    end,
  })
end

return M
