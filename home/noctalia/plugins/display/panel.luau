--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  Display: the pop-up panel (click the monitor in the bar, or Super+P)
-- ═══════════════════════════════════════════════════════════════════════════
--  One card per screen:
--  ┌────────────────────────────────────────────┐
--  │ [icon] DELL S3425DW                         │
--  │        Dell Inc. · 34" · 109 PPI · 3440×1440│
--  │ SIZE                                        │
--  │ [★ 1×] [1.1×] [1.25×] [1.5×]                │
--  │ Feels like a 3440×1440 screen               │
--  │ REFRESH RATE                                │
--  │ [60 Hz] [100 Hz] [120 Hz]                   │
--  └────────────────────────────────────────────┘
--  Buttons send a request to the service (service.luau), which applies it
--  right away and remembers it.

local SNAPSHOT = "display.snapshot"
local COMMAND = "display.command"

local snap = noctalia.state.get(SNAPSHOT) or { outputs = {} }
local requestCount = 0

local function send(action, port, value)
  requestCount += 1
  noctalia.state.set(COMMAND, { action = action, port = port, value = value, id = requestCount })
end

local function fmtScale(x)
  return (string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", "")) .. "×"
end

-- Two scales count as "the same" if they're within 0.01 (niri rounds a bit).
local function same(a, b)
  return math.abs(a - b) < 0.01
end

local function heading(text)
  return ui.label({ text = text, fontSize = 11, fontWeight = "bold", color = "on_surface_variant" })
end

local function smallText(text)
  return ui.label({ text = text, fontSize = 12, color = "on_surface_variant" })
end

-- Any screen on besides the laptop? (Then the laptop screen is "docked".)
local function externalOn()
  for _, o in ipairs(snap.outputs) do
    if o.enabled and not o.isLaptop then
      return true
    end
  end
  return false
end

local function card(o)
  local info = string.format('%s · %d" · %d PPI · %d×%d', o.maker, o.inches, o.ppi, o.width, o.height)

  -- Header: icon, name, details, and an on/off button for the laptop screen.
  local header = {
    ui.glyph({ name = o.isLaptop and "device-laptop" or "device-desktop", size = 24, color = o.enabled and "primary" or "on_surface_variant" }),
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = o.title, fontWeight = "bold" }),
      smallText(info),
    }),
  }
  if o.isLaptop and externalOn() then
    table.insert(header, ui.button({
      text = o.enabled and "Turn off" or "Turn on",
      glyph = o.enabled and "screen-share-off" or "screen-share",
      variant = "outline",
      controlSize = "sm",
      tooltip = "Until you unplug or re-plug the monitor",
      onClick = function()
        send("set_power", o.port, not o.enabled)
      end,
    }))
  end
  local children = { ui.row({ gap = 10, align = "center" }, header) }

  if not o.enabled then
    table.insert(children, smallText("Off while a monitor is connected (kanshi turns it off)."))
    return ui.column({ gap = 8, padding = 10, fill = "surface_variant/0.35", radius = 10 }, children)
  end

  -- SIZE: one button per sensible scale for THIS screen. ★ = recommended.
  table.insert(children, heading("SIZE"))
  local sizeButtons = {}
  for _, s in ipairs(o.choices) do
    local w, h = math.floor(o.width / s + 0.5), math.floor(o.height / s + 0.5)
    table.insert(sizeButtons, ui.button({
      key = o.port .. "-scale-" .. s,
      text = fmtScale(s),
      glyph = same(s, o.recommended) and "star" or nil,
      variant = same(s, o.scale) and "primary" or "outline",
      flexGrow = 1,
      tooltip = string.format("Feels like a %d×%d screen%s", w, h, same(s, o.recommended) and " · recommended" or ""),
      onClick = function()
        send("set_scale", o.port, s)
      end,
    }))
  end
  table.insert(children, ui.row({ gap = 6 }, sizeButtons))
  table.insert(children, smallText(string.format(
    "Feels like a %d×%d screen%s",
    math.floor(o.width / o.scale + 0.5),
    math.floor(o.height / o.scale + 0.5),
    o.remembered and "" or " · new monitor: forgotten when unplugged"
  )))

  -- REFRESH RATE: only if the screen offers more than one.
  if #o.rates > 1 then
    table.insert(children, heading("REFRESH RATE"))
    local rateButtons = {}
    local currentHz = math.floor(o.refresh / 1000 + 0.5)
    for _, r in ipairs(o.rates) do
      table.insert(rateButtons, ui.button({
        key = o.port .. "-rate-" .. r.hz,
        text = r.hz .. " Hz",
        variant = r.hz == currentHz and "primary" or "outline",
        flexGrow = 1,
        tooltip = r.hz >= 100 and "Smoother motion" or "Standard",
        onClick = function()
          send("set_rate", o.port, r.mhz)
        end,
      }))
    end
    table.insert(children, ui.row({ gap = 6 }, rateButtons))
  end

  return ui.column({ gap = 8, padding = 10, fill = "surface_variant/0.35", radius = 10 }, children)
end

local function render()
  local cards = {}
  if snap.error and snap.error ~= "" then
    table.insert(cards, smallText(snap.error))
  end
  for _, o in ipairs(snap.outputs) do
    table.insert(cards, card(o))
  end
  table.insert(cards, smallText("Changes apply right away and are remembered (saved in ~/.config/kanshi/display.conf)."))
  panel.render(ui.scroll({ gap = 10, padding = 12 }, cards))
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
