AddCSLuaFile()

local pulse_net = {}
pulse_net._defs = {}

local json = util.TableToJSON
local parse = util.JSONToTable
local compress = util.Compress
local decompress = util.Decompress

local function register(name)
    if SERVER then
        pulse_net._defs._registered = pulse_net._defs._registered or {}
        if not pulse_net._defs._registered[name] then
            pulse_net._defs._registered[name] = util.AddNetworkString(name)
        end
    end
end

function pulse_net.Define(name, defs)
    if not isstring(name) then error("pnet | name must be a string") end
    if not istable(defs) then error("pnet | definition cannot be empty") end
    pulse_net._defs[name] = defs
    register(name)
end

local function writeValue(t, v)
    if string.match(t, "^UInt%d+$") then
        net.WriteUInt(v, tonumber(string.match(t, "%d+")))
    elseif string.match(t, "^Int%d+$") then
        net.WriteInt(v, tonumber(string.match(t, "%d+")))
    elseif t == "SequentialTable" then
        net.WriteTable(v, true)
    elseif t == "ColorAlpha" then
        net.WriteColor(v, true)
    elseif t == "Data" then
        v = json(v)
        v = compress(v)

        local len = #v
        net.WriteUInt(len, 18)
        net.WriteData(v, len)
    else
        local func = net["Write" .. t]
        if not func then
            net.Abort()
            error("pnet | unknown type: " .. t)
        end
        func(v)
    end
end

if SERVER then
    function pulse_net.Send(name, target, ...)
        local def = pulse_net._defs[name]
        if not def then error("pnet | undefined message name: " .. name) end
        local types = SERVER and def.sc or def.cs
        if not types then error(string.format("pnet | undefined message direction: %s", SERVER and "server to client" or "client to server")) end

        net.Start(name)
        local args = {...}
        for i, t in ipairs(types) do
            writeValue(t, args[i])
        end

        local bytes = net.BytesWritten()
        if bytes > 65535 then
            net.Abort()
            error("pnet | message exceeded byte limit: " .. bytes)
        end

        if IsValid(target) then
            if target:IsPlayer() and def.superadmin and not target:IsSuperAdmin() then
                net.Abort()
                error(string.format("pnet | %s was about to be send a superadmin-only message by the server", target))
            end

            net.Send(target)
        elseif target == nil then
            net.Broadcast()
        else
            net.Abort()
            error("pnet | invalid target")
        end
    end
elseif CLIENT then
    function pulse_net.Send(name, ...)
        local def = pulse_net._defs[name]
        if not def then error("pnet | undefined message name: " .. name) end
        local types = SERVER and def.sc or def.cs
        if not types then error(string.format("pnet | undefined message direction: %s", SERVER and "server to client" or "client to server")) end

        net.Start(name)
        local args = {...}
        for i, t in ipairs(types) do
            writeValue(t, args[i])
        end

        local bytes = net.BytesWritten()
        if bytes > 65535 then
            net.Abort()
            error("pnet | message exceeded byte limit: " .. bytes)
        end

        net.SendToServer()
    end
end

local function readValue(t)
    if string.match(t, "^UInt%d+$") then
        return net.ReadUInt(tonumber(string.match(t, "%d+")))
    elseif string.match(t, "^Int%d+$") then
        return net.ReadInt(tonumber(string.match(t, "%d+")))
    elseif t == "SequentialTable" then
        return net.ReadTable(true)
    elseif t == "ColorAlpha" then
        return net.ReadColor(true)
    elseif t == "Data" then
        local len = net.ReadUInt(18)
        local v = net.ReadData(len)

        v = decompress(v)
        return parse(v)
    else
        local func = net["Read" .. t]
        if not func then error("pnet | unknown type: " .. t) end
        return func()
    end
end

function pulse_net.Receive(name, callback)
    if not isfunction(callback) then error("pnet | missing callback function") end

    net.Receive(name, function(_, ply)
        local def = pulse_net._defs[name]
        if not def then error("pnet | undefined message name: " .. name) end
        local types = SERVER and def.cs or def.sc
        if not types then error(string.format("pnet | undefined message direction: %s", SERVER and "client to server" or "server to client")) end

        if SERVER and def.superadmin and not ply:IsSuperAdmin() then
            error(string.format("pnet | %s attempted to send a superadmin-only message to the server", ply))
        end

        local args = {}
        for _, t in ipairs(types) do
            table.insert(args, readValue(t))
        end

        if SERVER then
            callback(ply, unpack(args))
        elseif CLIENT then
            callback(unpack(args))
        end
    end)
end

_G.pnet = pulse_net