--[[
	Script: EndRoundFX, Shared

	DarkPyro Gaming Servers, https://dpg.tf/
	Copyright © 2018, all rights reserved.

	Any unauthorized distribution or modification
	of the following code will result in persecution
	of said offender to the fullest extent of the law.
]]--

resource.AddFile( "resource/fonts/bebasneue.ttf" )
RunConsoleCommand( "ttt_postround_dm", "1" )

ENDROUNDFX = ENDROUNDFX or {}

function ENDROUNDFX:Print( text )
	MsgC( Color( 0, 148, 255 ), "[EndRoundFX] ", Color( 255, 255, 255 ), text .. "\n" )
end

function ENDROUNDFX:Load()
	if SERVER then
		include( "endroundfx/sv_endroundfx.lua" )
		AddCSLuaFile( "endroundfx/cl_endroundfx.lua" )
	else
		include( "endroundfx/cl_endroundfx.lua" ) 
	end

	self:Print( "Initialized!" )
end

ENDROUNDFX:Load()
