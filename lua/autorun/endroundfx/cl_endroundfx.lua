--[[
	Script: EndRoundFX, Clientside

	DarkPyro Gaming Servers, https://dpg.tf/
]]--

include "autorun/moat_texteffects.lua"

surface.CreateFont( "EndRoundFXFont", { font = "BebasNeue", size = ScreenScale( 23 ) } )

function ENDROUNDFX:PaintText()
	local txt = "EndRound Deathmatch"
	local rnd = net.ReadUInt( 3 )
	local font = "EndRoundFXFont"

	hook.Add( "HUDPaint", "PaintEndRoundFX", function()
		if rnd == 1 then
			DrawGlowingText( false, txt, font, ScrW() / 2, ScrH() / 10, Color( 48, 144, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		elseif rnd == 2 then
			DrawFadingText( 1, txt, font, ScrW() / 2, ScrH() / 10, Color( 48, 144, 255 ), Color( 127, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		elseif rnd == 3 then
			DrawRainbowText( 1, txt, font, ScrW() / 2, ScrH() / 10, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		elseif rnd == 4 then
			DrawEnchantedText( 2, txt, font, ScrW() / 2, ScrH() / 10, Color( 48, 144, 255 ), Color( 50, 50, 50 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		elseif rnd == 5 then
			DrawBouncingText( 3, 3, txt, font, ScrW() / 2, ScrH() / 10, Color( 48, 144, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
		end
	end )
end
net.Receive( "EndRoundFX", ENDROUNDFX.PaintText )

function ENDROUNDFX:RemoveText()
	hook.Remove( "HUDPaint", "PaintEndRoundFX" )
end
hook.Add( "TTTPrepareRound", "RemoveTextFX", ENDROUNDFX.RemoveText )
