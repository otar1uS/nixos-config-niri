--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  Battery: the part in the bar.  [battery icon] 48%  (+ the mode icon in Full/Drain/Pause)
-- ═══════════════════════════════════════════════════════════════════════════
--  It only DRAWS what the service shares; it never reads the battery itself.
--  Click it to open the panel. Hover it for details.

local SNAPSHOT = "battery.snapshot"
local PANEL_ID = "otari/battery:panel"

local snap = noctalia.state.get(SNAPSHOT) or { percent = 0, status = "Unknown", modes = {} }

-- Pick a battery icon that matches the charge level.
local function batteryGlyph()
  if snap.status == "Charging" then
    return "battery-charging"
  end
  local p = snap.percent or 0
  if p >= 86 then
    return "battery-4"
  elseif p >= 56 then
    return "battery-3"
  elseif p >= 31 then
    return "battery-2"
  elseif p >= 11 then
    return "battery-1"
  end
  return "battery"
end

-- The mode table (name, glyph...) for the current charging mode.
local function currentMode()
  for _, m in ipairs(snap.modes or {}) do
    if m.id == snap.mode then
      return m
    end
  end
  return nil
end

-- Colours are names from the theme (Gruvbox): primary = orange accent.
local function color()
  if snap.status == "Charging" then
    return "primary"
  elseif snap.status == "Discharging" and (snap.percent or 100) <= 15 then
    return "error" -- low battery: red
  end
  return nil -- nil = the bar's normal text colour
end

local function tooltip()
  local rows = {
    { key = "Battery", value = (snap.percent or 0) .. "% · " .. (snap.status or "Unknown") },
  }
  if snap.eta and snap.eta ~= "" then
    table.insert(rows, { key = snap.status == "Charging" and "Full in" or "Time left", value = snap.eta })
  end
  local mode = currentMode()
  if mode then
    table.insert(rows, { key = "Charging mode", value = mode.name })
  end
  if (snap.health or 0) > 0 then
    table.insert(rows, { key = "Health", value = string.format("%d%% · %d cycles", snap.health, snap.cycles or 0) })
  end
  return rows
end

local function render()
  local c = color()
  local children = { ui.glyph({ name = batteryGlyph(), color = c }) }
  if not barWidget.isVertical() then
    table.insert(children, ui.label({ text = (snap.percent or 0) .. "%", fontWeight = "bold", color = c }))
  end
  -- In the temporary modes (Full, Drain, Pause), show the mode icon too, as a
  -- reminder to switch back.
  local mode = currentMode()
  if mode and (mode.id == "full" or mode.id == "drain" or mode.id == "pause") then
    table.insert(children, ui.glyph({ name = mode.glyph, color = "primary" }))
  end
  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 5, align = "center" }, children))
  barWidget.setTooltip(tooltip())
end

-- Redraw whenever the service shares a new snapshot.
noctalia.state.watch(SNAPSHOT, function(value)
  if type(value) == "table" then
    snap = value
    render()
  end
end)

function update()
  render()
end

function onClick()
  noctalia.togglePanel(PANEL_ID)
end

noctalia.setUpdateInterval(30000)
render()
