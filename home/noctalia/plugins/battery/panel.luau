--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  Battery: the pop-up panel (click the battery in the bar, or Super+B)
-- ═══════════════════════════════════════════════════════════════════════════
--  ┌──────────────────────────────────────┐
--  │ [icon]  Not charging                 │
--  │  48%    Charging mode: Docked        │
--  │         Health 95% · 17 cycles       │
--  │ CHARGING MODE                        │
--  │ [Docked][Drain][Pause][Balanced][Full]│
--  │ Holds 35-40%. Best for battery ...   │
--  │ POWER MODE                           │
--  │ [Saver] [Balanced] [Performance]     │
--  └──────────────────────────────────────┘
--  Buttons don't change anything themselves: they send a request to the
--  service (service.luau), which runs the command.

local SNAPSHOT = "battery.snapshot"
local COMMAND = "battery.command"

local snap = noctalia.state.get(SNAPSHOT) or { percent = 0, status = "Unknown", modes = {} }
local requestCount = 0

-- Send a request to the service.
local function send(action, value)
  requestCount += 1
  noctalia.state.set(COMMAND, { action = action, value = value, id = requestCount })
end

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

-- Small grey heading above a group of buttons.
local function heading(text)
  return ui.label({ text = text, fontSize = 11, fontWeight = "bold", color = "on_surface_variant" })
end

-- The second line under the status: time left, or the power flow.
local function detailLine()
  if snap.eta and snap.eta ~= "" then
    return (snap.status == "Charging" and "Full in " or "") .. snap.eta .. (snap.status == "Charging" and "" or " left")
  elseif (snap.watt or 0) > 0.05 then
    return string.format("%.1f W", snap.watt)
  end
  return string.format("Charges below %d%%, stops at %d%%", snap.start or 0, snap.stop or 100)
end

local function render()
  local active = snap.pendingMode ~= "" and snap.pendingMode or snap.mode

  -- Top card: big icon + percentage on the left, words on the right.
  local sections = {
    ui.row({ gap = 12, align = "center", padding = 10, fill = "surface_variant/0.4", radius = 10 }, {
      ui.column({ align = "center", gap = 2 }, {
        ui.glyph({ name = batteryGlyph(), size = 26, color = "primary" }),
        ui.label({ text = (snap.percent or 0) .. "%", fontWeight = "bold" }),
      }),
      ui.separator({ orientation = "vertical" }),
      ui.column({ gap = 2, flexGrow = 1 }, {
        ui.label({ text = snap.status or "Unknown", fontWeight = "bold" }),
        ui.label({ text = detailLine(), fontSize = 12, color = "on_surface_variant" }),
        ui.label({
          text = (snap.health or 0) > 0 and string.format("Health %d%% · %d cycles", snap.health, snap.cycles or 0) or "",
          fontSize = 12,
          color = "on_surface_variant",
        }),
      }),
    }),
  }

  -- Charging modes: one button per mode from modules/battery.nix.
  -- (Pause has no limits of its own, so the text comes from each mode's hint.)
  if snap.hasModes and #snap.modes > 0 then
    table.insert(sections, heading("CHARGING MODE"))
    local buttons, hint = {}, "Custom limits: pick a mode to reset them."
    for _, mode in ipairs(snap.modes) do
      local isActive = mode.id == active
      if isActive then
        hint = mode.hint
        if snap.pendingMode ~= "" then
          hint = "Switching…"
        end
      end
      table.insert(buttons, ui.button({
        key = mode.id,
        text = mode.name,
        glyph = mode.glyph,
        variant = isActive and "primary" or "outline",
        flexGrow = 1,
        tooltip = mode.hint,
        onClick = function()
          send("set_mode", mode.id)
        end,
      }))
    end
    table.insert(sections, ui.row({ gap = 6 }, buttons))
    table.insert(sections, ui.label({ text = hint, fontSize = 12, color = "on_surface_variant" }))
  end

  -- Power modes (power-profiles-daemon): how fast vs how frugal the laptop runs.
  if snap.hasProfile then
    table.insert(sections, heading("POWER MODE"))
    -- Short names so they fit; the tooltip (hover) explains each one.
    local profiles = {
      { id = "power-saver", name = "Saver", glyph = "leaf", tip = "Power saver: quieter and cooler, battery lasts longer" },
      { id = "balanced", name = "Balanced", glyph = "scale", tip = "Balanced: the normal setting" },
      { id = "performance", name = "Fast", glyph = "gauge", tip = "Performance: fastest, uses more battery and gets warmer" },
    }
    local buttons = {}
    for _, p in ipairs(profiles) do
      table.insert(buttons, ui.button({
        key = p.id,
        text = p.name,
        glyph = p.glyph,
        variant = snap.profile == p.id and "primary" or "ghost",
        flexGrow = 1,
        tooltip = p.tip,
        onClick = function()
          send("set_profile", p.id)
        end,
      }))
    end
    table.insert(sections, ui.row({ gap = 6 }, buttons))
  end

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
