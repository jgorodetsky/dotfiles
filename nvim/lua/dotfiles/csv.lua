-- table view settings for csv and tsv files (csvview.nvim)
return {
  -- no comment markers, so a header that starts with # still counts as the header
  parser = { comments = {} },
  view = {
    display_mode = "border",
    header_lnum = true,
    sticky_header = { enabled = true, separator = "─" },
    -- first two columns stay put when you scroll right
    sticky_columns = { enabled = true, count = 2 },
  },
  keymaps = {
    textobject_field_inner = { "if", mode = { "o", "x" } },
    textobject_field_outer = { "af", mode = { "o", "x" } },
    jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
    jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
    jump_next_row = { "<Enter>", mode = { "n", "v" } },
    jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
  },
}
