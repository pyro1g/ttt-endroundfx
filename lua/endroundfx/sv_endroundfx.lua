--[[
	Script: EndRoundFX, Serverside

	DarkPyro's Servers, https://darkpyro.gg/
]]--

local cv_enabled = CreateConVar( "endroundfx_enabled", "1", FCVAR_ARCHIVE, "Show the end-of-round text effect.", 0, 1 )
local cv_effect = CreateConVar( "endroundfx_effect", "random", FCVAR_ARCHIVE, "Effect to show: random, or one or more (comma-separated) of " .. table.concat( ENDROUNDFX.Effects, ", " ) .. "." )
local cv_force_dm = CreateConVar( "endroundfx_force_dm", "1", FCVAR_ARCHIVE, "Turn on ttt_postround_dm when the server starts.", 0, 1 )
local cv_winner_color = CreateConVar( "endroundfx_winner_color", "0", FCVAR_ARCHIVE, "Colour the text by the team that won.", 0, 1 )

local EFFECT_INDEX = {}
for i, name in ipairs( ENDROUNDFX.Effects ) do EFFECT_INDEX[ name ] = i end

-- Same colours TTT's HUD uses for the traitor and innocent role boxes.
local COLOR_TRAITOR = Color( 200, 25, 25 )
local COLOR_INNOCENT = Color( 25, 200, 25 )

local lastEffect = 0

-- Parses endroundfx_effect into a list of effect indexes. Empty means "any".
local function EffectPool()
	local pool = {}

	for _, name in ipairs( string.Explode( ",", cv_effect:GetString() ) ) do
		name = string.lower( string.Trim( name ) )

		if name == "random" or name == "" then
			return {}
		elseif EFFECT_INDEX[ name ] then
			pool[ #pool + 1 ] = EFFECT_INDEX[ name ]
		else
			ENDROUNDFX:Print( "Unknown effect '" .. name .. "' in endroundfx_effect, ignoring it." )
		end
	end

	return pool
end

local function PickEffect()
	local pool = EffectPool()
	if #pool == 0 then
		for i = 1, #ENDROUNDFX.Effects do pool[ i ] = i end
	end

	-- Avoid showing the same effect twice in a row.
	local pick
	repeat pick = pool[ math.random( #pool ) ] until pick ~= lastEffect or #pool == 1

	return pick
end

local function WinnerColor( result )
	if result == WIN_TRAITOR then return COLOR_TRAITOR end
	if result == WIN_INNOCENT or result == WIN_TIMELIMIT then return COLOR_INNOCENT end

	-- TTT2 passes the winning team's name, and each team has its own colour.
	local team = isstring( result ) and istable( TEAMS ) and TEAMS[ result ]
	if istable( team ) and IsColor( team.color ) then return team.color end
end

local function PackColor( col )
	if not col then return -1 end
	-- bit ops expect whole numbers.
	local r, g, b = math.floor( col.r ), math.floor( col.g ), math.floor( col.b )
	return bit.bor( bit.lshift( r, 16 ), bit.lshift( g, 8 ), b )
end

local function PostRoundDMEnabled()
	local cv = GetConVar( "ttt_postround_dm" )
	return cv ~= nil and cv:GetBool()
end

-- TTT creates its convars while the gamemode loads, so wait until then.
hook.Add( "Initialize", "EndRoundFX.ForceDM", function()
	if cv_force_dm:GetBool() then
		RunConsoleCommand( "ttt_postround_dm", "1" )
	end
end )

-- The text announces the deathmatch, so only show it when there is one.
-- Other addons can return false from the EndRoundFXShouldShow hook to skip a round.
hook.Add( "TTTEndRound", "EndRoundFX.Show", function( result )
	if not cv_enabled:GetBool() or not PostRoundDMEnabled() then return end
	if hook.Run( "EndRoundFXShouldShow", result ) == false then return end

	lastEffect = PickEffect()
	SetGlobal2Int( ENDROUNDFX.NWColorKey, PackColor( cv_winner_color:GetBool() and WinnerColor( result ) or nil ) )
	SetGlobal2Int( ENDROUNDFX.NWKey, lastEffect )
end )

hook.Add( "TTTPrepareRound", "EndRoundFX.Hide", function()
	SetGlobal2Int( ENDROUNDFX.NWKey, 0 )
end )
