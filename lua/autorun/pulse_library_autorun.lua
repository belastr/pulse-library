if SERVER then
    AddCSLuaFile("derma/derma_extra_utils.lua")
    AddCSLuaFile("skins/pulse_skin.lua")
elseif CLIENT then
    include("derma/derma_extra_utils.lua")
    include("skins/pulse_skin.lua")
end