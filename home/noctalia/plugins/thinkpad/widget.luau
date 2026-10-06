--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  ThinkPad: the part in the bar.  [fan icon] 41°
-- ═══════════════════════════════════════════════════════════════════════════
--  Shows the CPU temperature. The fan icon turns orange while the fan is
--  forced to full speed. Click it for the panel; hover it for details.

local SNAPSHOT = "thinkpad.snapshot"
local PANEL_ID = "otari/thinkpad:panel"

local snap = noctalia.state.get(SNAPSHOT) or { temps = {}, fan = {} }

-- Colour for a temperature: red when hot, yellow when warm, normal otherwise.
local function tempColor(t)
  if not t then
    return nil
  elseif t >= 85 then
    return "error"
  elseif t >= 70 then
    return "tertiary"
  end
  return nil
end

local function fullSpeed()
  return snap.fan and snap.fan.level == "7"
end

local function render()
  local cpu = snap.temps and snap.temps.cpu
  local children = {
    ui.glyph({ name = (snap.fan and (snap.fan.rpm or 0) > 0) and "propeller" or "propeller-off", color = fullSpeed() and "primary" or nil }),
  }
  if not barWidget.isVertical() then
    table.insert(children, ui.label({ text = cpu and (cpu .. "°") or "–", fontWeight = "bold", color = tempColor(cpu) }))
  end
  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 5, align = "center" }, children))

  local t = snap.temps or {}
  local function deg(v)
    return v and (v .. " °C") or "–"
  end
  barWidget.setTooltip({
    { key = "CPU", value = deg(t.cpu) },
    { key = "GPU", value = deg(t.gpu) },
    { key = "SSD", value = deg(t.ssd) },
    { key = "Fan", value = string.format("%s rpm · %s mode", tostring(snap.fan and snap.fan.rpm or 0), tostring(snap.fan and snap.fan.mode or "auto")) },
  })
end

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
