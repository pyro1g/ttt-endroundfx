--[[
	Script: EndRoundFX, Serverside

	DarkPyro Gaming Servers, https://dpg.tf/
]]--

util.AddNetworkString "EndRoundFX"

function ENDROUNDFX:SendText()
	net.Start "EndRoundFX"
		net.WriteUInt( math.random( 5 ), 3 )
	net.Broadcast()
end
hook.Add( "TTTEndRound", "SendTextFX", ENDROUNDFX.SendText )
