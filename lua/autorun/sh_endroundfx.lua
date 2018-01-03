--[[
	Script: EndRoundFX, Shared

	DarkPyro Gaming Servers, https://dpg.tf/
]]--

AddCSLuaFile()

resource.AddFile "resource/fonts/bebasneue.ttf"
RunConsoleCommand( "ttt_postround_dm", "1" )

ENDROUNDFX = ENDROUNDFX or {}

function ENDROUNDFX:Load()
	if SERVER then
		include "endroundfx/sv_endroundfx.lua"
		AddCSLuaFile "endroundfx/cl_endroundfx.lua"
	else
		include "endroundfx/cl_endroundfx.lua"
	end

	MsgC( Color( 0, 148, 255 ), "[EndRoundFX] ", Color( 255, 255, 255 ), "Initialized!" .. "\n" )
end

ENDROUNDFX:Load()
