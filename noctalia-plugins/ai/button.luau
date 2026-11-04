--!nonstrict
-- Bar widget: left click toggles this plugin's menu panel, right click opens
-- the list for editing.

barWidget.setGlyph("sparkles")
barWidget.setTooltip("AI")

function update()
  noctalia.setUpdateInterval(60000) -- static; nothing to refresh
end

function onClick()
  noctalia.togglePanel("saddevastator/ai:menu")
end

function onRightClick()
  noctalia.runAsync("zeditor \"$HOME/.config/ai-menu/apps.conf\"", function() end)
end
