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
*Description and example to be added.*
