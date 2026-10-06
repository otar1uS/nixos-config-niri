--!nonstrict
-- ═══════════════════════════════════════════════════════════════════════════
--  ThinkPad: the background service (no screen of its own).
-- ═══════════════════════════════════════════════════════════════════════════
--  Every 3 seconds it runs `thinkpad json` (from modules/thinkpad.nix) and
--  shares the result with the bar widget and the panel. Button presses in
--  the panel arrive here and become `thinkpad fan <mode>` / `thinkpad led <mode>`.

local SNAPSHOT = "thinkpad.snapshot"
local COMMAND = "thinkpad.command"
local POLL_MS = 3000
local TIMEOUT_MS = 5000

local HAS_CMD = noctalia.commandExists("thinkpad")

local snapshot = {
  available = HAS_CMD,
  temps = {}, -- cpu / gpu / ssd / wifi in °C
  fan = { rpm = 0, level = "auto", mode = "auto", control = false },
  led = "",
  plugged = false,
  pending = "", -- e.g. "fan:max" while a switch is running
}
local busy = false

local function publish()
  local copy = table.clone(snapshot)
  copy.temps = table.clone(snapshot.temps)
  copy.fan = table.clone(snapshot.fan)
  noctalia.state.set(SNAPSHOT, copy)
end

local function read()
  if not HAS_CMD or busy then
    return
  end
  busy = true
  local launched = noctalia.runAsync({ "thinkpad", "json" }, function(res)
    busy = false
    local data = res.exitCode == 0 and noctalia.json.decode(res.stdout or "")
    if type(data) == "table" then
      snapshot.temps = data.temps or {}
      snapshot.fan = data.fan or snapshot.fan
      snapshot.led = data.led or ""
      snapshot.plugged = data.plugged == true
      -- A switch has finished once the remembered mode matches it.
      if snapshot.pending == "fan:" .. tostring(snapshot.fan.mode) or snapshot.pending == "led:" .. snapshot.led then
        snapshot.pending = ""
      end
      publish()
    end
  end, TIMEOUT_MS)
  if not launched then
    busy = false
  end
end

-- Requests from the panel: { kind = "fan" | "led", mode = "..." }
noctalia.state.watch(COMMAND, function(cmd)
  if type(cmd) ~= "table" or (cmd.kind ~= "fan" and cmd.kind ~= "led") then
    return
  end
  local mode = tostring(cmd.mode or "")
  snapshot.pending = cmd.kind .. ":" .. mode
  publish()
  noctalia.runAsync({ "thinkpad", cmd.kind, mode }, function(res)
    if res.exitCode ~= 0 then
      snapshot.pending = ""
      noctalia.notifyError("ThinkPad", "Could not switch: " .. (res.stderr or ""))
    end
    read()
  end, TIMEOUT_MS)
end)

function update()
  read()
end

noctalia.setUpdateInterval(POLL_MS)
publish()
read()
