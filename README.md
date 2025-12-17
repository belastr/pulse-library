# Pulse Library
Powerful Lua modules for GMod: net & sql wrappers, customizable layer for HUD elements, a derma library, and an in-game config system for other addons.
Built from years of GLua experience, designed to streamline addon and gamemode development, and used in all my other addons.

# Modules
### pulse_config (pconf)
A centralized, serverside configuration framework that decouples addon settings from hardcoded values.
Addons register configurable options instead of rolling their own config logic, supporting Int, Float, String, Boolean, and structured Table types for data-driven systems.
All registered settings are exposed through a single in-game menu for superadmins, with optional live updates via simple integration, letting systems react immediately without restarts or reloads.

**Example (excerpt from pulse_survival):**

```lua
pconf.Register("pulseSurvival")
	:AddConfig("staminaDrain", {
		type = "Float", min = 0.01, max = 10, default = 2m
		desc = "Stamina to drain per quarter second when running"
	})
	:AddConfig("staminaRegeneration", {
		type = "Float", min = 0.01, max = 10, default = 1.75,
		desc = "Stamina to regain per quarter second when not running"
	})
	:AddConfig("staminaCrouchRegeneration", {
		type = "Float", min = 0.01, max = 10, default = 2,
		desc = "Stamina to regain per quarter second when crouching"
	})
	:AddConfig("hungerTimer", {
		type = "Int", min = 1, max = 600, default = 36,
		desc = "Time to loose one hunger point, in seconds"
	})
	:AddConfig("thirstTimer", {
		type = "Int", min = 1, max = 600, default = 36,
		desc = "Time to loose one thirst point, in seconds"
	})
:End()

PULSE_SURVIVAL.staminaDrain = pconf.Get("pulseSurvival", "staminaDrain")
PULSE_SURVIVAL.regeneration = pconf.Get("pulseSurvival", "staminaRegeneration")
PULSE_SURVIVAL.crouchRegen = pconf.Get("pulseSurvival", "staminaCrouchRegeneration")
PULSE_SURVIVAL.hungerTimer = pconf.Get("pulseSurvival", "hungerTimer")
PULSE_SURVIVAL.thirstTimer = pconf.Get("pulseSurvival", "thirstTimer")

hook.Add("PulseConfigSet", "pulse_survival", function(section, keyname, value)
	if section == "pulseSurvival" then
		PULSE_SURVIVAL[keyname] = value

		pnet.Send("pulse_survival", nil, PULSE_SURVIVAL)
	end
end)

hook.Add("PlayerLoaded", "pulse_survival", function(ply)
	pnet.Send("pulse_survival", ply, PULSE_SURVIVAL)
end)
```

### pulse_hud (phud)
A modular, player-customizable HUD framework that decouples HUD drawing from fixed screen positions.
Addons register HUD elements instead of drawing directly, letting players enable/disable elements, move them freely, scale them, while fonts adjust at runtime.
Elements receive layout data (position, scale) from Pulse HUD while keeping their original draw logic intact.

**Example (excerpt from pulse_survival):**

Code
```lua
phud.AddElement("pulseSurvivalStamina", {
	w = ScrW() * 0.11953125,
	h = ScrH() * 0.05,
	fonts = {["font"] = {
		font = "Verdana",
		size = ScrH() < 1200 and 20 or 24,
		weight = 900,
		antialias = true,
		additive = true
	}},
	defaults = {x = 0.01875, y = 0.72, scale = 1, visible = true},
	draw = function(x, y, scale)
		draw.RoundedBox(
			8, x, y,
			ScrW() * 0.11953125 * scale,
			ScrH() * 0.05 * scale,
			Color(0, 0, 0, 85)
		)

		draw.SimpleText(
			"STAMINA", "pulseSurvivalStamina_font",
			x + ScrW() * 0.01015625 * scale,
			y + ScrH() * 0.00902777 * scale,
			Color(255, 255, 0, 200)
		)

		local w = ((ScrW() * 0.11953125 * scale) - 72) / 13
		for val = 0, 10 do
			if stamina >= val * LocalPlayer():GetMaxStamina() / 10 then
				surface.SetDrawColor(255, 255, 0, 200)
			else
				surface.SetDrawColor(115, 115, 50, 150)
			end

			surface.DrawRect(
				x + ScrW() * 0.01015625 * scale + val * (w + 6),
				y + ScrH() * 0.03055555 * scale,
				w, 8
			)
		end
	end
})
```

Result

![GIF Result Showcase](./docs/pulse_hud_result.gif)

### pulse_net (pnet)
A GMod net messaging wrapper: send messages in one line and handle them in a function with pre-read parameters.
Validates types before sending, does not exceed net message limits and supports messages restricted to superadmins.
Define message types once when registering—simple and safe networking in efficient code.

**Example:**

Before
```lua
if CLIENT then
    local configJSON = util.TableToJSON(local_config)
    local configCompressed = util.Compress(configJSON)
    local bytes_amount = #configCompressed

    net.Start("UpdateConfig")
        net.WriteUInt(bytes_amount, 16)
        net.WriteData(configCompressed, bytes_amount)
    net.SendToServer()
end

if SERVER then
    util.AddNetworkString("UpdateConfig")

	net.Receive("UpdateConfig", function(_, ply)
		local bytes_amount = net.ReadUInt(16)
		local configCompressed = net.ReadData(bytes_amount)

        local configJSON = util.Decompress(configCompressed)
        local configTable = util.JSONToTable(configJSON)

        config = table.Copy(configTable)
        print(string.format("%s updated the config.", ply))
	end)
end
```

After
```lua
pnet.Define("UpdateConfig", {cs = {"Data"}}) -- cs: client-to-server

if CLIENT then
    pnet.Send("UpdateConfig", local_config)
end

if SERVER then
    pnet.Receive("UpdateConfig", function(ply, configTable)
        config = table.Copy(configTable)
        print(string.format("%s updated the config.", ply))
    end)
end
```


### pulse_sql (psql)
This module provides a minimal ORM‑like wrapper around GMod's built‑in SQLite, letting you define a table and perform basic CRUD operations (insert, select, update, delete).
It auto-generates CREATE TABLE statements from a schema table and builds simple WHERE clauses from Lua tables.
Useful for quickly persisting structured addon data without manual SQL string assembly.

**Example (excerpt from pulse_config):**
```lua
local db = psql("pulse_config", {
	section = "VARCHAR(255) NOT NULL",
	keyname = "VARCHAR(255) NOT NULL",
	value = "TEXT",

	constraints = {
		"PRIMARY KEY (section, keyname)"
	}
})

function pconfBuilder:End()
	local section = self._name
	pulse_config._sections[section] = pulse_config._sections[section] or {}

	for keyname, def in pairs(self._configs) do
		local row = db:select({section = section, keyname = keyname})

		local value
		if istable(row[1]) then
			value = decode(row[1].value, def.default)
		else
			value = def.default
			db:insert({section = section, keyname = keyname, value = encode(def.default)})
		end

		def.value = value
		pulse_config._sections[section][keyname] = def
	end

	return self._configs
end

function pulse_config.Set(section, keyname, value)
	...

	db:update({value = encode(value)}, {section = section, keyname = keyname})
end
```
