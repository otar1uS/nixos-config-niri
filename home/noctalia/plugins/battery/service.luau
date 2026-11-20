--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  Battery: the background service (no screen of its own).
-- ═══════════════════════════════════════════════════════════════════════════
--  Every few seconds it reads the battery and the charging mode, then shares
--  one "snapshot" table with the bar widget and the panel. When the panel
--  asks for a change (a button press), the change is done here.
--
--  Based on piero-93/battery-power-management (GPL-3.0). Changed: the
--  charge-limit slider is replaced by charging MODES that set both the
--  start and stop numbers through `battery-mode` (modules/battery.nix),
--  and battery health / charge cycles were added.
--  (In Luau, a line starting with -- is a comment.)

local SNAPSHOT = "battery.snapshot" -- the shared table's name
local COMMAND = "battery.command" -- where the panel drops its requests

local POLL_MS = 5000 -- read the battery every 5 seconds
local PROBE_EVERY = 3 -- power mode + time left: every 3rd read (~15 s)
local TIMEOUT_MS = 5000 -- give up on a command after 5 seconds
local BATTERY = "/sys/class/power_supply/BAT0"

-- Which helper programs are installed?
local HAS_PPD = noctalia.commandExists("powerprofilesctl")
local HAS_UPOWER = noctalia.commandExists("upower")
local HAS_MODES = noctalia.commandExists("battery-mode")

local snapshot = {
  percent = 0,
  status = "Unknown", -- Charging / Discharging / Full / Not charging / Unknown
  watt = 0.0, -- power going in or out right now
  eta = "", -- "1h 20m" until empty or full, "" when unknown
  health = 0, -- battery capacity left compared to new, in %
  cycles = 0, -- how many full charge cycles the battery has done
  profile = "balanced", -- power mode: power-saver / balanced / performance
  hasProfile = HAS_PPD,
  mode = "", -- charging mode id: docked / drain / pause / balanced / full / custom
  start = 0, -- charging starts below this %
  stop = 100, -- charging stops at this %
  modes = {}, -- every mode from modules/battery.nix
  hasModes = false,
  pendingMode = "", -- the mode being switched to right now
}

local tick = 0
local busy = { battery = false, modes = false, probe = false }

-- Share a fresh copy, so the widget and panel notice the change.
local function publish()
  local copy = table.clone(snapshot)
  copy.modes = table.clone(snapshot.modes)
  noctalia.state.set(SNAPSHOT, copy)
end

-- upower writes times like "1.2 hours" or "34.5 minutes": make "1h 12m".
local MINUTES_PER = { hou = 60, min = 1, sec = 1 / 60, day = 1440 }
local function formatUpowerTime(value)
  local numStr, unit = value:match("^(%S+)%s*(%a*)")
  local num = tonumber(numStr)
  if not num then
    return ""
  end
  local total = math.floor(num * (MINUTES_PER[unit:sub(1, 3)] or 1) + 0.5)
  if total >= 60 then
    return string.format("%dh %dm", total // 60, total % 60)
  end
  return string.format("%dm", total)
end

-- The kernel describes the battery as KEY=value lines in "uevent".
local function parseBattery(content)
  local v = {}
  for line in content:gmatch("[^\n]+") do
    local key, value = line:match("^POWER_SUPPLY_([%w_]+)=(.*)$")
    if key then
      v[key] = value
    end
  end
  snapshot.percent = tonumber(v.CAPACITY) or snapshot.percent
  snapshot.status = v.STATUS and noctalia.string.trim(v.STATUS) or snapshot.status
  snapshot.cycles = tonumber(v.CYCLE_COUNT) or 0

  -- POWER_NOW is in microwatts. Some batteries only give current x voltage.
  local power, current, voltage = tonumber(v.POWER_NOW), tonumber(v.CURRENT_NOW), tonumber(v.VOLTAGE_NOW)
  if power then
    snapshot.watt = math.abs(power) / 1e6
  elseif current and voltage then
    snapshot.watt = math.abs(current * voltage) / 1e12
  end

  -- Health = how much it holds now / how much it held when new.
  local full = tonumber(v.ENERGY_FULL) or tonumber(v.CHARGE_FULL)
  local design = tonumber(v.ENERGY_FULL_DESIGN) or tonumber(v.CHARGE_FULL_DESIGN)
  if full and design and design > 0 then
    snapshot.health = math.floor(full / design * 100 + 0.5)
  end
end

local function readBattery()
  if busy.battery then
    return
  end
  busy.battery = true
  local launched = noctalia.runAsync({ "cat", BATTERY .. "/uevent" }, function(res)
    busy.battery = false
    if res.exitCode == 0 then
      parseBattery(res.stdout or "")
      publish()
    end
  end, TIMEOUT_MS)
  if not launched then
    busy.battery = false
  end
end

-- `battery-mode json` prints the current mode and the full mode list.
local function readModes()
  if not HAS_MODES or busy.modes then
    return
  end
  busy.modes = true
  local launched = noctalia.runAsync({ "battery-mode", "json" }, function(res)
    busy.modes = false
    local data = res.exitCode == 0 and noctalia.json.decode(res.stdout or "")
    if type(data) == "table" then
      snapshot.mode = data.current or "custom"
      snapshot.start = data.start or 0
      snapshot.stop = data.stop or 100
      snapshot.modes = data.modes or {}
      snapshot.hasModes = true
      if snapshot.pendingMode == snapshot.mode then
        snapshot.pendingMode = "" -- the switch has finished
      end
      publish()
    end
  end, TIMEOUT_MS)
  if not launched then
    busy.modes = false
  end
end

-- Power mode and time left come from two daemons; ask both in one go.
local function probe()
  if busy.probe or not (HAS_PPD or HAS_UPOWER) then
    return
  end
  busy.probe = true
  local SEP = "__SPLIT__"
  local cmd = (HAS_PPD and "powerprofilesctl get" or "true")
    .. "; echo " .. SEP .. "; "
    -- LC_ALL=C: print numbers as 1.5, not 1,5 (your Georgian number format).
    .. (HAS_UPOWER and "LC_ALL=C upower -i /org/freedesktop/UPower/devices/battery_BAT0" or "true")
  local launched = noctalia.runAsync(cmd, function(res)
    busy.probe = false
    local out = res.stdout or ""
    local at = out:find(SEP, 1, true)
    local profile = noctalia.string.trim(at and out:sub(1, at - 1) or "")
    if HAS_PPD and profile ~= "" then
      snapshot.profile = profile
    end
    snapshot.eta = ""
    for line in (at and out:sub(at + #SEP) or ""):gmatch("[^\n]+") do
      local l = noctalia.string.trim(line)
      local value = l:match("^time to empty:%s*(.+)$") or l:match("^time to full:%s*(.+)$")
      if value then
        snapshot.eta = formatUpowerTime(value)
        break
      end
    end
    publish()
  end, TIMEOUT_MS)
  if not launched then
    busy.probe = false
  end
end

local function modeName(id)
  for _, m in ipairs(snapshot.modes) do
    if m.id == id then
      return m
    end
  end
  return nil
end

-- Requests from the panel arrive here.
noctalia.state.watch(COMMAND, function(cmd)
  if type(cmd) ~= "table" then
    return
  end

  if cmd.action == "set_profile" and HAS_PPD then
    snapshot.profile = tostring(cmd.value) -- show it right away; the next probe confirms
    publish()
    noctalia.runAsync({ "powerprofilesctl", "set", tostring(cmd.value) }, function(res)
      if res.exitCode ~= 0 then
        noctalia.notifyError("Power mode", "Could not switch: " .. (res.stderr or ""))
      end
      probe()
    end, TIMEOUT_MS)
  elseif cmd.action == "set_mode" and HAS_MODES then
    local mode = modeName(tostring(cmd.value))
    if not mode then
      return
    end
    snapshot.pendingMode = mode.id
    publish()
    noctalia.runAsync({ "battery-mode", mode.id }, function(res)
      if res.exitCode == 0 then
        noctalia.notify(
          mode.name .. " charging mode",
          mode.hint
        )
      else
        snapshot.pendingMode = ""
        noctalia.notifyError("Charging mode", "Could not switch: " .. (res.stderr or ""))
      end
      readModes()
      readBattery()
    end, TIMEOUT_MS)
  end
end)

-- Called by Noctalia every POLL_MS.
function update()
  readBattery()
  if tick % PROBE_EVERY == 0 then
    probe()
    readModes()
  end
  tick += 1
end

noctalia.setUpdateInterval(POLL_MS)

-- First round right away, so the bar isn't empty for 5 seconds.
publish()
readBattery()
readModes()
probe()
