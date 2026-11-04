--!nonstrict
-- Keybinds panel: searchable list of mango keybinds.
-- Data: `keybinds.py --json` -> {"sections":[{"title","rows":[{"label","note","keys"}]}]}.
-- Re-read on every open, so edits to the mango config show up without a reload.

local SOURCE = "python3 \"$HOME/.config/mango/keybinds.py\" --json"

local sections = {}
local query = ""
local status = "Loading keybinds…"
local closeButton = true

local function lower(s)
  return string.lower(s or "")
end

local function rowMatches(row, title)
  if query == "" then
    return true
  end
  local q = lower(query)
  for _, field in { row.label, row.note, row.keys and row.keys[1], title } do
    if field and lower(field):find(q, 1, true) then
      return true
    end
  end
  return false
end

-- "SUPER + SHIFT + S" -> one key cap per key
local function keyCaps(keys)
  local caps = {}
  for part in ((keys or "") .. " + "):gmatch("(.-) %+ ") do
    if part ~= "" then
      table.insert(caps, ui.row({ fill = "secondary/0.18", radius = 6, paddingH = 7, paddingV = 2, align = "center" }, {
        ui.label({ text = part, fontSize = 12, fontWeight = "medium", color = "on_surface" }),
      }))
    end
  end
  return ui.row({ gap = 4, align = "center" }, caps)
end

local function bindRow(row)
  local text = { ui.label({ text = row.label, color = "on_surface" }) }
  if row.note then
    table.insert(text, ui.label({ text = row.note, fontSize = 11, color = "on_surface_variant" }))
  end
  return ui.row({ gap = 12, align = "center" }, {
    ui.column({ gap = 2, flexGrow = 1 }, text),
    keyCaps(row.keys and row.keys[1]),
  })
end

local function body()
  if status then
    return { ui.label({ text = status, color = "on_surface_variant" }) }
  end
  local nodes = {}
  for _, section in sections do
    local rows = {}
    for _, row in section.rows or {} do
      if rowMatches(row, section.title) then
        table.insert(rows, bindRow(row))
      end
    end
    if #rows > 0 then
      table.insert(rows, 1, ui.label({ text = section.title, fontWeight = "bold", color = "primary" }))
      table.insert(nodes, ui.column({ gap = 8, align = "stretch" }, rows))
    end
  end
  if #nodes == 0 then
    nodes[1] = ui.label({ text = `No keybinds match "{query}"`, color = "on_surface_variant" })
  end
  return nodes
end

local function render()
  local header = {
    ui.glyph({ name = "help-circle", size = 18, color = "primary" }),
    ui.label({ text = "Keybinds", fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
  }
  if closeButton then
    table.insert(header, ui.button({ glyph = "close", onClick = function() panel.close() end }))
  end
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    ui.row({ align = "center", gap = 8 }, header),
    ui.input({
      key = "search",
      placeholder = "Search keybinds…",
      onChange = function(value)
        query = value or ""
        render()
      end,
    }),
    ui.scroll({ flexGrow = 1, gap = 18, align = "stretch" }, body()),
  }))
end

local function load()
  noctalia.runAsync(SOURCE, function(res)
    if res == nil or res.error then
      status = "Could not read keybinds: " .. tostring(res and res.error or "no result")
    else
      local ok, data = pcall(noctalia.json.decode, res.stdout or "")
      if ok and type(data) == "table" and type(data.sections) == "table" then
        sections = data.sections
        status = nil
      else
        status = "Could not parse keybinds.py output"
      end
    end
    render()
  end)
end

function onOpen(_context)
  closeButton = noctalia.getSetting("shell.show_close_buttons") ~= false
  render()
  load()
end
