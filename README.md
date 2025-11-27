# Pulse Library
Powerful Lua modules for GMod: net & sql wrappers, customizable layer for HUD elements, a derma library, and an in-game config system for other addons.
Built from years of GLua experience, designed to streamline addon and gamemode development, and used in all my other addons.

# Modules
### pulse_config (pconf)
*Description and example to be added.*

### pulse_hud (phud)
*Description and example to be added.*

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
