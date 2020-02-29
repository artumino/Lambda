AddCSLuaFile()

local DbgPrint = GetLogging("MapScript")
local MAPSCRIPT = {}

MAPSCRIPT.PlayersLocked = false
MAPSCRIPT.DefaultLoadout =
{
    Weapons =
    {
        "weapon_medkit",
        "weapon_fists",
        "weapon_crowbar",
        "arcticvr_hl2mmod_pistol",
        "arcticvr_m9",
        "arcticvr_glock",
        "arcticvr_hl2mmod_smg1",
        "arcticvr_hl2mmod_357",
        "arcticvr_deagle",
    },
    Ammo =
    {
        ["Pistol"] = 60,
        ["SMG1"] = 60,
    },
    Armor = 0,
    HEV = true,
}

MAPSCRIPT.InputFilters =
{
}

MAPSCRIPT.EntityFilterByClass =
{
    --["env_global"] = true,
}

MAPSCRIPT.EntityFilterByName =
{
    ["global_newgame_entmaker"] = true,
}

function MAPSCRIPT:Init()
end

function MAPSCRIPT:PostInit()

    if SERVER then

    end

end

function MAPSCRIPT:PostPlayerSpawn(ply)

    --DbgPrint("PostPlayerSpawn")

end

return MAPSCRIPT
