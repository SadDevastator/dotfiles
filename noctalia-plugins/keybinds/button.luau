--!nonstrict
-- Bar widget: a help icon that toggles the keybinds panel.

barWidget.setGlyph("help-circle")
barWidget.setTooltip("Keybinds")

function update()
  noctalia.setUpdateInterval(60000) -- static; nothing to refresh
end

function onClick()
  noctalia.togglePanel("saddevastator/keybinds:panel")
end
