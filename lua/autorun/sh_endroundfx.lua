--[[
	Script: EndRoundFX, Shared

	DarkPyro Gaming Servers, https://dpg.tf/
]]--

AddCSLuaFile()

resource.AddFile "resource/fonts/bebasneue.ttf"

RunConsoleCommand( "ttt_postround_dm", "1" )

ENDROUNDFX = ENDROUNDFX or {}

function ENDROUNDFX:Print( text )
	MsgC( Color( 255, 255, 0 ), "[EndRoundFX] ", Color( 255, 255, 255 ), text .. "\n" )
end

function ENDROUNDFX:Load()
	self:Print( "Initializing..." )

	if SERVER then
		include "endroundfx/sv_endroundfx.lua"
		AddCSLuaFile "endroundfx/cl_endroundfx.lua"

		self:Print( "Loaded serverside files..." )
	else
		include "endroundfx/cl_endroundfx.lua"
	end

	self:Print( "Successfully initialized!" )
end

ENDROUNDFX:Load()
