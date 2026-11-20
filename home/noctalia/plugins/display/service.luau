--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  Display: the background service (no screen of its own).
-- ═══════════════════════════════════════════════════════════════════════════
--  • Asks which screens exist (`wlr-randr --json`, works on Umbriel and any
--    other compositor with the standard output-management protocol)
--    whenever a screen changes, and shares a "snapshot" with the widget and
--    the panel.
--  • Works out sensible SIZE choices for each screen from its pixel density.
--  • When you tap a button: changes the screen right away (wlr-randr), saves
--    the choice in ~/.config/kanshi/display.conf, and tells kanshi to re-read
--    it, so the choice is remembered next time you log in or plug it in.

local SNAPSHOT = "display.snapshot"
local COMMAND = "display.command"
local CONF = noctalia.expandPath("~/.config/kanshi/display.conf")
local TIMEOUT_MS = 5000

local HAS_KANSHI = noctalia.commandExists("kanshictl")

local snapshot = { outputs = {}, error = "" }
local saved = {} -- what display.conf says: saved["<name>"] = { mode = "...", scale = "..." }
local reading = false

-- ── Size choices ────────────────────────────────────────────────────────
-- PPI = pixels per inch: how tightly packed the pixels are.
-- Few pixels per inch (big monitor) -> small scales; many (sharp laptop or
-- 4K screen) -> bigger scales. "recommended" gets a star in the panel.
local function sizeChoices(ppi, isLaptop)
  if ppi < 125 then -- normal desktop monitor, like your 34" Dell (~109 PPI)
    return { 1, 1.1, 1.25, 1.5 }, 1
  elseif ppi < 175 then -- sharp laptop / small 1440p screen (your laptop ~163 PPI)
    return { 1, 1.25, 1.5, 1.75 }, 1.25
  end
  return { 1.5, 1.75, 2, 2.5 }, 2 -- very sharp (4K) screens
end

-- ── display.conf: read and write ───────────────────────────────────────
-- Each line looks like:  output "Dell Inc. DELL S3425DW 3XFTR44" mode 3440x1440@120.000Hz scale 1
local function readSaved()
  saved = {}
  local text = noctalia.readFile(CONF)
  if not text then
    return
  end
  for line in text:gmatch("[^\n]+") do
    local name, rest = line:match('^%s*output%s+"([^"]+)"(.*)$')
    if name then
      saved[name] = { mode = rest:match("mode%s+(%S+)"), scale = rest:match("scale%s+(%S+)") }
    end
  end
end

local function writeSaved()
  local lines = {
    "# Screen settings, written by the Display panel in the bar (Super+Shift+D).",
    '# One line per screen: output "<name>" [mode WIDTHxHEIGHT@HZ] [scale N]',
    "# Delete this file and rebuild to get the defaults back.",
  }
  local names = {}
  for name in pairs(saved) do
    table.insert(names, name)
  end
  table.sort(names)
  for _, name in ipairs(names) do
    local s = saved[name]
    local line = 'output "' .. name .. '"'
    if s.mode then
      line ..= " mode " .. s.mode
    end
    if s.scale then
      line ..= " scale " .. s.scale
    end
    table.insert(lines, line)
  end
  local ok, err = noctalia.writeFile(CONF, table.concat(lines, "\n") .. "\n")
  if not ok then
    noctalia.notifyError("Display", "Could not save your choice: " .. tostring(err))
  end
  return ok
end

-- kanshi names a monitor "maker model serial" (missing parts = "Unknown").
-- The laptop screen is just called by its port, "eDP-1", in home/kanshi.nix.
local function kanshiName(port, o)
  if port:match("^eDP") then
    return port
  end
  return string.format("%s %s %s", o.make or "Unknown", o.model or "Unknown", o.serial or "Unknown")
end

-- 1.25 -> "1.25", 1.0 -> "1"
local function fmtScale(x)
  return (string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", ""))
end

-- ── Reading the screens (wlr-randr --json) ────────────────────────────
-- One entry per screen: name ("eDP-1"), make/model/serial, physical_size in
-- mm, enabled, scale, and modes { width, height, refresh (Hz), current }.
local function buildOutput(o)
  local port = o.name or "?"
  local isLaptop = port:match("^eDP") ~= nil
  local modes = o.modes or {}
  local mode = nil
  for _, m in ipairs(modes) do
    if m.current then
      mode = m
    end
  end
  local width = mode and mode.width or (modes[1] and modes[1].width) or 0
  local height = mode and mode.height or (modes[1] and modes[1].height) or 0
  local wmm = (o.physical_size or {}).width or 0
  local hmm = (o.physical_size or {}).height or 0
  local ppi = wmm > 0 and width / (wmm / 25.4) or 96
  local inches = math.sqrt(wmm * wmm + hmm * hmm) / 25.4
  local choices, recommended = sizeChoices(ppi, isLaptop)

  -- Refresh rates at the current resolution, e.g. 60 / 100 / 120 Hz. Kept in
  -- millihertz (119990 = 119.990 Hz), the exact unit wlr-randr matches on.
  local rates, seen = {}, {}
  for _, m in ipairs(modes) do
    if m.width == width and m.height == height then
      local mhz = math.floor((m.refresh or 0) * 1000 + 0.5)
      local hz = math.floor(mhz / 1000 + 0.5)
      if not seen[hz] or mhz > seen[hz] then
        seen[hz] = mhz
      end
    end
  end
  for hz, mhz in pairs(seen) do
    table.insert(rates, { hz = hz, mhz = mhz })
  end
  table.sort(rates, function(a, b)
    return a.hz < b.hz
  end)

  local name = kanshiName(port, o)
  return {
    port = port,
    name = name,
    title = isLaptop and "Laptop screen" or (o.model or port),
    maker = isLaptop and "Built-in" or (o.make or ""),
    isLaptop = isLaptop,
    enabled = o.enabled == true,
    width = width,
    height = height,
    refresh = mode and math.floor((mode.refresh or 0) * 1000 + 0.5) or 0,
    scale = o.scale or 1,
    inches = math.floor(inches + 0.5),
    ppi = math.floor(ppi + 0.5),
    choices = choices,
    recommended = recommended,
    rates = rates,
    remembered = saved[name] ~= nil, -- is it in display.conf yet?
  }
end

local function refresh()
  if reading then
    return
  end
  reading = true
  readSaved()
  local launched = noctalia.runAsync({ "wlr-randr", "--json" }, function(res)
    reading = false
    local data = res.exitCode == 0 and noctalia.json.decode(res.stdout or "")
    if type(data) ~= "table" then
      snapshot.error = "Could not read the screens (wlr-randr --json failed)."
      noctalia.state.set(SNAPSHOT, table.clone(snapshot))
      return
    end
    local list = {}
    for _, o in ipairs(data) do
      table.insert(list, buildOutput(o))
    end
    -- Screens that are on first, then by name.
    table.sort(list, function(a, b)
      if a.enabled ~= b.enabled then
        return a.enabled
      end
      return a.port < b.port
    end)
    snapshot = { outputs = list, error = "" }
    noctalia.state.set(SNAPSHOT, table.clone(snapshot))
  end, TIMEOUT_MS)
  if not launched then
    reading = false
  end
end

local function findOutput(port)
  for _, o in ipairs(snapshot.outputs) do
    if o.port == port then
      return o
    end
  end
  return nil
end

local function countEnabled()
  local n = 0
  for _, o in ipairs(snapshot.outputs) do
    if o.enabled then
      n += 1
    end
  end
  return n
end

-- Run `wlr-randr --output <port> ...`, then re-read the screens.
local function applyNow(port, args)
  local argv = { "wlr-randr", "--output", port }
  for _, a in ipairs(args) do
    table.insert(argv, a)
  end
  noctalia.runAsync(argv, function(res)
    if res.exitCode ~= 0 then
      noctalia.notifyError("Display", "Could not change the screen: " .. (res.stderr or res.stdout or "error"))
    end
    refresh()
  end, TIMEOUT_MS)
end

-- Save to display.conf, then let kanshi re-read it.
local function remember(o, field, value)
  saved[o.name] = saved[o.name] or {}
  saved[o.name][field] = value
  if writeSaved() and HAS_KANSHI then
    noctalia.runAsync({ "kanshictl", "reload" }, function(res)
      if res.exitCode ~= 0 then
        noctalia.log("kanshictl reload failed: " .. (res.stderr or ""))
      end
    end, TIMEOUT_MS)
  end
end

-- ── Requests from the panel ────────────────────────────────────────────
noctalia.state.watch(COMMAND, function(cmd)
  if type(cmd) ~= "table" then
    return
  end
  local o = findOutput(tostring(cmd.port or ""))
  if not o then
    return
  end

  if cmd.action == "set_scale" then
    local s = fmtScale(tonumber(cmd.value) or 1)
    applyNow(o.port, { "--scale", s }) -- change it now
    remember(o, "scale", s) -- and remember it
  elseif cmd.action == "set_rate" then
    local mhz = tonumber(cmd.value) or 0
    local mode = string.format("%dx%d@%.3f", o.width, o.height, mhz / 1000)
    applyNow(o.port, { "--mode", mode })
    remember(o, "mode", mode .. "Hz")
  elseif cmd.action == "set_power" then
    -- Never switch off the last screen that is on: you'd see nothing.
    if not cmd.value and countEnabled() <= 1 then
      noctalia.notifyError("Display", "That's your only screen that is on.")
      return
    end
    -- Not remembered on purpose: kanshi decides again on the next plug-in.
    applyNow(o.port, { cmd.value and "--on" or "--off" })
  end
end)

-- Noctalia calls this when a screen is plugged in, unplugged or changed.
function onOutputsChanged()
  refresh()
end

-- Also check every 30 s, just in case an event was missed.
function update()
  refresh()
end

noctalia.setUpdateInterval(30000)
refresh()
