--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  Display: the part in the bar.  [monitor icon] 1×
-- ═══════════════════════════════════════════════════════════════════════════
--  Shows the size (scale) of the screen you're working on.
--  Click it to open the panel. Hover it to see every screen.

local SNAPSHOT = "display.snapshot"
local PANEL_ID = "otari/display:panel"

local snap = noctalia.state.get(SNAPSHOT) or { outputs = {} }

local function fmtScale(x)
  return (string.format("%.2f", x or 1):gsub("0+$", ""):gsub("%.$", "")) .. "×"
end

-- The screen your mouse/keyboard is on (or the first one that is on).
local function focusedOutput()
  local focused = noctalia.focusedOutputName()
  local first = nil
  for _, o in ipairs(snap.outputs or {}) do
    if o.enabled then
      first = first or o
      if o.port == focused then
        return o
      end
    end
  end
  return first
end

local function render()
  local o = focusedOutput()
  local children = { ui.glyph({ name = (o and o.isLaptop) and "device-laptop" or "device-desktop" }) }
  if o and not barWidget.isVertical() then
    table.insert(children, ui.label({ text = fmtScale(o.scale), fontWeight = "bold" }))
  end
  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 5, align = "center" }, children))

  -- Tooltip: one row per screen, e.g. "DELL S3425DW: 3440×1440 · 120 Hz · 1×"
  local rows = {}
  for _, s in ipairs(snap.outputs or {}) do
    local value = s.enabled
        and string.format("%d×%d · %d Hz · %s", s.width, s.height, math.floor(s.refresh / 1000 + 0.5), fmtScale(s.scale))
      or "off"
    table.insert(rows, { key = s.title, value = value })
  end
  barWidget.setTooltip(rows)
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

noctalia.setUpdateInterval(5000) -- also follows you when you move to another screen
render()
