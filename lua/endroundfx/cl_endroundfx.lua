--[[
	Script: EndRoundFX, Clientside

	DarkPyro's Servers, https://darkpyro.gg/
]]--

local TextFX = include( "endroundfx/cl_texteffects.lua" )

local cv_draw = CreateClientConVar( "endroundfx_draw", "1", true, false, "Show the end-of-round text effect.", 0, 1 )
local cv_reduced = CreateClientConVar( "endroundfx_reduced_motion", "0", true, false, "Show the text without animation.", 0, 1 )
local cv_text = GetConVar( "endroundfx_text" )
local cv_y = GetConVar( "endroundfx_y" )
local cv_sound = GetConVar( "endroundfx_sound" )

local FONT = "EndRoundFX"
local FADE_IN = 0.4 -- Seconds.
local PREVIEW_TIME = 6 -- Seconds.

-- Colours used by the effects. Change these to match your server.
local COLOR_PRIMARY = Color( 48, 144, 255 )
local COLOR_FADE = Color( 127, 0, 0 )
local COLOR_ENCHANT = Color( 50, 50, 50 )
local COLOR_SNOW = Color( 255, 255, 255 )
local COLOR_SHINE = Color( 255, 255, 255 )

local function CreateFonts()
	surface.CreateFont( FONT, {
		font = "Bebas Neue",
		size = math.Round( ScreenScaleH( 31 ) ), -- Based on height so ultrawide screens don't get huge text.
		extended = true,
	} )
end
CreateFonts()
hook.Add( "OnScreenSizeChanged", "EndRoundFX.Fonts", CreateFonts )

local CENTER, TOP = TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP

-- The main colour for this round: COLOR_PRIMARY, or the winning team's colour.
local primary = Color( 255, 255, 255 )

local EFFECTS = {
	glow = function( text, x, y ) TextFX.DrawGlowingText( false, text, FONT, x, y, primary, CENTER, TOP ) end,
	fade = function( text, x, y ) TextFX.DrawFadingText( 1, text, FONT, x, y, primary, COLOR_FADE, CENTER, TOP ) end,
	rainbow = function( text, x, y ) TextFX.DrawRainbowText( 1, text, FONT, x, y, CENTER, TOP ) end,
	enchant = function( text, x, y ) TextFX.DrawEnchantedText( 2, text, FONT, x, y, primary, COLOR_ENCHANT, CENTER, TOP ) end,
	bounce = function( text, x, y ) TextFX.DrawBouncingText( 3, 3, text, FONT, x, y, primary, CENTER, TOP ) end,
	electric = function( text, x, y ) TextFX.DrawElectricText( 1, text, FONT, x, y, primary, CENTER, TOP ) end,
	fire = function( text, x, y ) TextFX.DrawFireText( 0.5, text, FONT, x, y, primary, CENTER, TOP, true, true ) end,
	snow = function( text, x, y ) TextFX.DrawSnowingText( 20, text, FONT, x, y, primary, COLOR_SNOW, CENTER, TOP ) end,
	shine = function( text, x, y ) TextFX.DrawShineText( 1, text, FONT, x, y, primary, COLOR_SHINE, CENTER, TOP ) end,
	pulse = function( text, x, y ) TextFX.DrawPulsingText( 1, 0.05, text, FONT, x, y, primary, CENTER, TOP ) end,
	slam = function( text, x, y, elapsed ) TextFX.DrawSlamText( elapsed, text, FONT, x, y, primary, CENTER, TOP ) end,
	typewriter = function( text, x, y, elapsed ) TextFX.DrawTypewriterText( elapsed, 18, text, FONT, x, y, primary, CENTER, TOP ) end,
	glitch = function( text, x, y ) TextFX.DrawGlitchText( 1, text, FONT, x, y, primary, CENTER, TOP ) end,
	prism = function( text, x, y ) TextFX.DrawPrismText( 1, text, FONT, x, y, CENTER, TOP ) end,
}

-- `packed` is 0xRRGGBB from the server, or -1 for COLOR_PRIMARY.
local function UpdatePrimaryColor( packed )
	if packed >= 0 then
		primary.r = bit.band( bit.rshift( packed, 16 ), 255 )
		primary.g = bit.band( bit.rshift( packed, 8 ), 255 )
		primary.b = bit.band( packed, 255 )
	else
		primary.r, primary.g, primary.b = COLOR_PRIMARY.r, COLOR_PRIMARY.g, COLOR_PRIMARY.b
	end
end

-- Local-only preview, set by the endroundfx_preview command.
local preview

local shownEffect, shownAt = 0, 0

hook.Add( "HUDPaint", "EndRoundFX.Paint", function()
	local effect = GetGlobal2Int( ENDROUNDFX.NWKey, 0 )
	local packedColor = GetGlobal2Int( ENDROUNDFX.NWColorKey, -1 )

	if preview then
		if RealTime() > preview.ends then
			preview = nil
		else
			effect, packedColor = preview.effect, -1
		end
	end

	local now = RealTime()
	if effect ~= shownEffect then
		shownEffect, shownAt = effect, now

		local snd = cv_sound:GetString()
		if effect ~= 0 and snd ~= "" and cv_draw:GetBool() then surface.PlaySound( snd ) end
	end

	if effect == 0 or not cv_draw:GetBool() then return end

	local paint = EFFECTS[ ENDROUNDFX.Effects[ effect ] ]
	local text = cv_text:GetString()
	if not paint or text == "" then return end

	UpdatePrimaryColor( packedColor )

	local x, y = ScrW() / 2, ScrH() * cv_y:GetFloat()

	if cv_reduced:GetBool() then
		TextFX.DrawGlowingText( true, text, FONT, x, y, primary, CENTER, TOP )
		return
	end

	local elapsed = now - shownAt
	surface.SetAlphaMultiplier( math.min( elapsed / FADE_IN, 1 ) )
	paint( text, x, y, elapsed )
	surface.SetAlphaMultiplier( 1 )
end )

concommand.Add( "endroundfx_preview", function( _, _, args )
	local name = string.lower( args[ 1 ] or "" )
	local effect = table.KeyFromValue( ENDROUNDFX.Effects, name )

	if not effect then
		if name ~= "" then
			ENDROUNDFX:Print( "Unknown effect '" .. name .. "'. Choose from: " .. table.concat( ENDROUNDFX.Effects, ", " ) )
			return
		end

		effect = math.random( #ENDROUNDFX.Effects )
	end

	preview = { effect = effect, ends = RealTime() + PREVIEW_TIME }
	shownEffect = -1 -- Restart the fade-in even if this effect is already showing.
	ENDROUNDFX:Print( "Previewing '" .. ENDROUNDFX.Effects[ effect ] .. "' (only you can see this)." )
end, function( cmd, argStr )
	local typed = string.lower( string.Trim( argStr ) )
	local options = {}

	for _, name in ipairs( ENDROUNDFX.Effects ) do
		if string.StartsWith( name, typed ) then options[ #options + 1 ] = cmd .. " " .. name end
	end

	return options
end, "Preview an end-of-round effect locally. Leave the name blank for a random one." )
