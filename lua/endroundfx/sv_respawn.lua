--[[
	Script: EndRoundFX, End-Round Respawn (Serverside)

	Brings everyone back for the post-round deathmatch, optionally clearing corpses
	first and handing out a weapon to anyone without a gun.

	DarkPyro's Servers, https://darkpyro.gg/
]]--

local cv_respawn = CreateConVar( "endroundfx_respawn", "0", FCVAR_ARCHIVE, "Respawn everyone for the post-round deathmatch.", 0, 1 )
local cv_clear = CreateConVar( "endroundfx_respawn_clear_ragdolls", "1", FCVAR_ARCHIVE, "Remove player corpses before respawning. Requires endroundfx_respawn 1.", 0, 1 )
local cv_give = CreateConVar( "endroundfx_respawn_give_weapon", "1", FCVAR_ARCHIVE, "Give a weapon to anyone without a gun. Requires endroundfx_respawn 1.", 0, 1 )
local cv_weapon = CreateConVar( "endroundfx_respawn_weapon", "weapon_zm_revolver", FCVAR_ARCHIVE, "Weapon class to give out. Requires endroundfx_respawn 1 and endroundfx_respawn_give_weapon 1." )

-- Seconds to wait before handing out the weapon, so pointshop/loadout addons
-- that give guns on spawn get to go first.
local GIVE_DELAY = 1

local function ClearCorpses()
	-- TTT flags player corpses, so map ragdolls are left alone.
	for _, rag in ipairs( ents.FindByClass( "prop_ragdoll" ) ) do
		if rag.player_ragdoll then rag:Remove() end
	end
end

local function Respawn( ply )
	-- TTT's own helper skips forced spectators and heals anyone still alive.
	if ply.SpawnForRound then
		return ply:SpawnForRound( true )
	end

	if ply:Alive() and ply:Team() == TEAM_TERROR then return false end

	ply:SetTeam( TEAM_TERROR )
	ply:Spawn()
	return true
end

-- True if the player already carries a pistol or heavy weapon.
local function HasGun( ply )
	for _, wep in ipairs( ply:GetWeapons() ) do
		if wep.Kind == WEAPON_PISTOL or wep.Kind == WEAPON_HEAVY then return true end
	end

	return false
end

local function GiveWeapon( ply, class )
	if not IsValid( ply ) or not ply:Alive() or ply:Team() ~= TEAM_TERROR then return end
	if HasGun( ply ) or ply:HasWeapon( class ) then return end

	-- Give goes through TTT's PlayerCanPickupWeapon, so it can still fail if the slot is taken.
	local wep = ply:Give( class )
	if not IsValid( wep ) then return end

	-- TTT weapons define how much reserve ammo they can hold. Top it up for the deathmatch.
	local maxAmmo = wep.Primary and wep.Primary.ClipMax
	local ammoType = wep:GetPrimaryAmmoType()
	if isnumber( maxAmmo ) and ammoType >= 0 then
		ply:SetAmmo( math.max( ply:GetAmmoCount( ammoType ), maxAmmo ), ammoType )
	end

	ply:SelectWeapon( class )
end

hook.Add( "TTTEndRound", "EndRoundFX.Respawn", function()
	-- Everything below depends on endroundfx_respawn, and respawning is pointless without the deathmatch.
	if not cv_respawn:GetBool() or not ENDROUNDFX:PostRoundDMEnabled() then return end

	if cv_clear:GetBool() then ClearCorpses() end

	for _, ply in player.Iterator() do
		Respawn( ply )
	end

	if not cv_give:GetBool() then return end

	local class = string.Trim( cv_weapon:GetString() )
	if class == "" then return end

	if not weapons.GetStored( class ) then
		ENDROUNDFX:Print( "endroundfx_respawn_weapon '" .. class .. "' isn't an installed weapon, so nothing was given out." )
		return
	end

	timer.Simple( GIVE_DELAY, function()
		-- The next round may have started if ttt_posttime_seconds is very short.
		if GetRoundState() ~= ROUND_POST then return end

		for _, ply in player.Iterator() do
			GiveWeapon( ply, class )
		end
	end )
end )
