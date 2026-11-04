--!nonstrict
-- AI menu panel: drops down from the bar button, one button per entry in
-- ~/.config/ai-menu/apps.conf ("Name | command | term"). "term" runs the
-- command in foot (terminal apps opened as apps use foot; the default terminal
-- stays WezTerm). Commands run from ~ through sh, so $HOME, pipes and && work.
-- The list is re-read on every open.

local LIST = noctalia.expandPath("~/.config/ai-menu/apps.conf")

local function trim(s)
  return noctalia.string.trim(s or "")
end

local function entries()
  local out = {}
  local text = noctalia.readFile(LIST) or ""
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local l = trim(line)
    if l ~= "" and l:sub(1, 1) ~= "#" then
      local name, cmd, mode = l:match("^([^|]+)|([^|]+)|?(.*)$")
      if name and cmd then
        table.insert(out, { name = trim(name), cmd = trim(cmd), term = trim(mode) == "term" })
      end
    end
  end
  return out
end

-- Single-quote for sh: ' -> '\''
local function shq(s)
  return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

-- Detached from noctalia, started in the home folder
local function run(cmd)
  -- env -u: don't pass noctalia's NVIDIA-only EGL setting on (breaks GL in Flatpaks)
  noctalia.runAsync(`cd "$HOME" && setsid -f env -u __EGL_VENDOR_LIBRARY_FILENAMES {cmd} >/dev/null 2>&1`, function(res)
    if res and res.error then
      noctalia.notify("AI", "Launch failed: " .. tostring(res.error))
    end
  end)
end

local function launch(e)
  if e.term then
    run("foot -e sh -c " .. shq(e.cmd))
  else
    run("sh -c " .. shq(e.cmd))
  end
  panel.close()
end

local function render()
  local list = {}
  for _, e in entries() do
    table.insert(list, ui.button({
      glyph = if e.term then "terminal-2" else "sparkles",
      text = e.name,
      onClick = function() launch(e) end,
    }))
  end
  if #list == 0 then
    list[1] = ui.label({ text = "No entries yet. Use the pencil to add some.", color = "on_surface_variant" })
  end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "sparkles", size = 18, color = "primary" }),
      ui.label({ text = "AI", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
      ui.button({
        glyph = "pencil",
        variant = "ghost",
        onClick = function()
          run("zeditor " .. shq(LIST))
          panel.close()
        end,
      }),
    }),
    ui.scroll({ flexGrow = 1, gap = 6, align = "stretch" }, list),
  }))
end

function onOpen(_context)
  render()
end
