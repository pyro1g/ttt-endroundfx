--[[
	Script: EndRoundFX, Shared

	Animated text shown during TTT's post-round deathmatch.
	https://github.com/pyro1g/ttt-endroundfx

	DarkPyro's Servers, https://darkpyro.gg/
]]--

-- TTT and TTT2 both run from the "terrortown" folder. There's nothing to do anywhere else.
if engine.ActiveGamemode() ~= "terrortown" then return end

AddCSLuaFile()

ENDROUNDFX = ENDROUNDFX or {}
ENDROUNDFX.Version = "2.2.1"

-- The index of each effect is what gets networked, so only ever append to this list.
ENDROUNDFX.Effects = {
	"glow", "fade", "rainbow", "enchant", "bounce", "electric", "fire", "snow",
	"shine", "pulse", "slam", "typewriter", "glitch", "prism",
}

-- Global vars: the current effect index (0 when nothing should be drawn),
-- and the winning team's colour packed as 0xRRGGBB (-1 to use the default colour).
ENDROUNDFX.NWKey = "EndRoundFX.Effect"
ENDROUNDFX.NWColorKey = "EndRoundFX.Color"

-- Settings clients need to know about. Only the server saves them.
local REPLICATED = SERVER and { FCVAR_ARCHIVE, FCVAR_REPLICATED } or FCVAR_REPLICATED
CreateConVar( "endroundfx_text", "EndRound Deathmatch", REPLICATED, "Text shown during the post-round deathmatch." )
CreateConVar( "endroundfx_y", "0.1", REPLICATED, "Vertical position of the text, as a fraction of screen height.", 0, 1 )
CreateConVar( "endroundfx_sound", "", REPLICATED, "Sound played when the text appears, relative to sound/. Leave empty for none." )

function ENDROUNDFX:Print( text )
	MsgC( Color( 255, 255, 0 ), "[EndRoundFX] ", color_white, text, "\n" )
end

if SERVER then
	resource.AddFile( "resource/fonts/bebasneue.ttf" )

	AddCSLuaFile( "endroundfx/cl_texteffects.lua" )
	AddCSLuaFile( "endroundfx/cl_endroundfx.lua" )
	include( "endroundfx/sv_endroundfx.lua" )
	include( "endroundfx/sv_respawn.lua" )
else
	include( "endroundfx/cl_endroundfx.lua" )
end

ENDROUNDFX:Print( "Loaded v" .. ENDROUNDFX.Version )
