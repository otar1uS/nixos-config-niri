--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  ThinkPad: the pop-up panel (click the fan in the bar, or Super+Shift+T)
-- ═══════════════════════════════════════════════════════════════════════════
--  ┌──────────────────────────────────────────┐
--  │  CPU 41°   GPU 40°   SSD 35°   Wi-Fi 44° │
--  │  Fan: 0 rpm (resting) · on charger       │
--  │ FAN                                      │
--  │ [Auto] [Max on charger] [Max]            │
--  │ LID LOGO LED                             │
--  │ [Off] [On] [Charging]                    │
--  └──────────────────────────────────────────┘

local SNAPSHOT = "thinkpad.snapshot"
local COMMAND = "thinkpad.command"

local snap = noctalia.state.get(SNAPSHOT) or { temps = {}, fan = {} }
local requestCount = 0

local function send(kind, mode)
  requestCount += 1
  noctalia.state.set(COMMAND, { kind = kind, mode = mode, id = requestCount })
end

local function heading(text)
  return ui.label({ text = text, fontSize = 11, fontWeight = "bold", color = "on_surface_variant" })
end

local function smallText(text)
  return ui.label({ text = text, fontSize = 12, color = "on_surface_variant" })
end

-- One temperature tile: icon, number, name. Red when hot, yellow when warm.
local function tile(glyph, name, value)
  local color = "on_surface"
  if value and value >= 85 then
    color = "error"
  elseif value and value >= 70 then
    color = "tertiary"
  end
  return ui.column({ gap = 2, align = "center", flexGrow = 1, padding = 8, fill = "surface_variant/0.4", radius = 10 }, {
    ui.glyph({ name = glyph, size = 18, color = "primary" }),
    ui.label({ text = value and (value .. "°") or "–", fontWeight = "bold", color = color }),
    ui.label({ text = name, fontSize = 11, color = "on_surface_variant" }),
  })
end

-- A row of mode buttons. `kind` is "fan" or "led".
local function modeRow(kind, current, modes)
  local buttons = {}
  for _, m in ipairs(modes) do
    local isActive = current == m.id or snap.pending == kind .. ":" .. m.id
    table.insert(buttons, ui.button({
      key = kind .. "-" .. m.id,
      text = m.name,
      glyph = m.glyph,
      variant = isActive and "primary" or "outline",
      flexGrow = 1,
      tooltip = m.tip,
      enabled = kind ~= "fan" or snap.fan.control == true,
      onClick = function()
        send(kind, m.id)
      end,
    }))
  end
  return ui.row({ gap = 6 }, buttons)
end

local FAN_MODES = {
  { id = "auto", name = "Auto", glyph = "wind", tip = "The laptop decides: quiet, factory behaviour" },
  { id = "charger", name = "Max on charger", glyph = "plug-connected", tip = "Full speed while plugged in, auto on battery" },
  { id = "max", name = "Max", glyph = "propeller", tip = "Full speed all the time" },
}

local LED_MODES = {
  { id = "off", name = "Off", glyph = "bulb-off", tip = "The red dot on the lid stays dark" },
  { id = "on", name = "On", glyph = "bulb", tip = "The red dot on the lid stays lit" },
  { id = "charging", name = "Charging", glyph = "battery-charging", tip = "Lit only while the battery is charging" },
}

local FAN_HINTS = {
  auto = "The laptop decides how fast the fan runs.",
  charger = "Full speed while plugged in, the laptop decides on battery.",
  max = "Full speed all the time: coolest, and loudest.",
}

local function render()
  local t = snap.temps or {}
  local fan = snap.fan or {}

  local sections = {
    ui.row({ gap = 6 }, {
      tile("cpu", "CPU", t.cpu),
      tile("device-desktop", "GPU", t.gpu),
      tile("database", "SSD", t.ssd),
      tile("wifi", "Wi-Fi", t.wifi),
    }),
  }

  if not snap.available then
    table.insert(sections, smallText("The `thinkpad` command is missing (modules/thinkpad.nix)."))
    panel.render(ui.column({ gap = 8, padding = 12 }, sections))
    return
  end

  -- Fan
  local rpm = tonumber(fan.rpm) or 0
  local state = rpm == 0 and "resting" or (fan.level == "7" and "full speed" or "running")
  table.insert(sections, heading("FAN"))
  table.insert(sections, smallText(string.format("%d rpm (%s) · %s", rpm, state, snap.plugged and "on charger" or "on battery")))
  table.insert(sections, modeRow("fan", fan.mode, FAN_MODES))
  if fan.control then
    table.insert(sections, smallText(FAN_HINTS[fan.mode] or ""))
  else
    table.insert(sections, smallText("Fan control turns on after one reboot (driver setting from modules/thinkpad.nix)."))
  end

  -- Lid LED
  table.insert(sections, heading("LID LOGO LED"))
  table.insert(sections, modeRow("led", snap.led, LED_MODES))

  panel.render(ui.column({ gap = 8, padding = 12 }, sections))
end

function onOpen(_context)
  snap = noctalia.state.get(SNAPSHOT) or snap
  render()
end

noctalia.state.watch(SNAPSHOT, function(value)
  if type(value) == "table" then
    snap = value
    render()
  end
end)
