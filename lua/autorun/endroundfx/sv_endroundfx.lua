--[[
	Script: EndRoundFX, Serverside

	DarkPyro Gaming Servers, https://dpg.tf/
	Copyright © 2018, all rights reserved.

	Any unauthorized distribution or modification
	of the following code will result in persecution
	of said offender to the fullest extent of the law.
]]--

util.AddNetworkString "EndRoundFX"

function ENDROUNDFX:SendText()
	net.Start "EndRoundFX"
		net.WriteUInt( math.random( 5 ), 3 )
	net.Broadcast()
end
hook.Add( "TTTEndRound", "SendTextFX", ENDROUNDFX.SendText )
