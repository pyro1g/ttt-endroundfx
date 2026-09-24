--[[
	Script: EndRoundFX, Text Effects (Clientside)

	Based on moat's text effects (https://github.com/moat7/moat-texteffects).
	Kept as a local module instead of the original globals so it can't clash with
	other addons that ship their own copy. Changes from the original:
	  - Every alignment now works for every effect. The per-character and particle
	    effects used to double-apply or ignore it.
	  - Text is split by UTF-8 character instead of by byte.
	  - Blended colours reuse one table instead of allocating every frame, and keep alpha.
	  - New effects: shine, pulse, slam, typewriter, glitch and prism.

	Usage: local TextFX = include( "endroundfx/cl_texteffects.lua" )
]]--

local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local draw_SimpleText = draw.SimpleText
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local math_Rand = math.Rand
local math_random = math.random
local math_sin = math.sin
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_floor = math.floor
local math_ceil = math.ceil
local render_SetScissorRect = render.SetScissorRect
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix
local RealTime = RealTime
local FrameTime = FrameTime
local HSVToColor = HSVToColor

local TextFX = {}

-- Scratch colours. draw.SimpleText reads a colour immediately, so reusing these is safe.
local blendColor = Color( 255, 255, 255 )
local glowColor = Color( 255, 255, 255 )
local shadowColor = Color( 0, 0, 0 )
local splitRed = Color( 255, 0, 60 )
local splitCyan = Color( 0, 220, 255 )
local shineColor = Color( 255, 255, 255 )

local DEFAULT_ENCHANT = Color( 127, 0, 255 )
local BOUNCE_HEIGHT = 5 -- Raise for a heavier bounce.

-- Returns the top-left corner and size of text drawn at x, y with the given alignment.
-- Leaves the surface font set to `font`.
local function TopLeft( text, font, x, y, xalign, yalign )
	surface_SetFont( font )
	local w, h = surface_GetTextSize( text )

	if xalign == TEXT_ALIGN_CENTER then x = x - w / 2
	elseif xalign == TEXT_ALIGN_RIGHT then x = x - w end

	if yalign == TEXT_ALIGN_CENTER then y = y - h / 2
	elseif yalign == TEXT_ALIGN_BOTTOM then y = y - h end

	return x, y, w, h
end

-- Splits text into UTF-8 characters, falling back to bytes if the string isn't valid UTF-8.
local charCache = {}
local function Chars( text )
	local chars = charCache[ text ]
	if chars then return chars end

	chars = {}
	if utf8.len( text ) then
		for _, code in utf8.codes( text ) do chars[ #chars + 1 ] = utf8.char( code ) end
	else
		for i = 1, #text do chars[ i ] = text:sub( i, i ) end
	end

	charCache[ text ] = chars
	return chars
end

-- Blends from `a` towards `b` by `t` (0-1).
local function Blend( a, b, t )
	local aa, ba = a.a or 255, b.a or 255
	blendColor.r = a.r + ( b.r - a.r ) * t
	blendColor.g = a.g + ( b.g - a.g ) * t
	blendColor.b = a.b + ( b.b - a.b ) * t
	blendColor.a = aa + ( ba - aa ) * t
	return blendColor
end
TextFX.Blend = Blend

-- Runs fn() with 2D drawing scaled by `scale` around (cx, cy).
local scaleMatrix, scaleVec, translateVec = Matrix(), Vector(), Vector()
local function DrawScaled( scale, cx, cy, fn, ... )
	scaleMatrix:Identity()
	translateVec:SetUnpacked( cx, cy, 0 )
	scaleMatrix:Translate( translateVec )
	scaleVec:SetUnpacked( scale, scale, 1 )
	scaleMatrix:Scale( scaleVec )
	translateVec:SetUnpacked( -cx, -cy, 0 )
	scaleMatrix:Translate( translateVec )

	-- Keeps scaled glyphs smooth instead of pixelated.
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	cam_PushModelMatrix( scaleMatrix, true )
		fn( ... )
	cam_PopModelMatrix()
	render.PopFilterMin()
	render.PopFilterMag()
end
TextFX.DrawScaled = DrawScaled

function TextFX.DrawShadowedText( shadow, text, font, x, y, color, xalign, yalign )
	shadowColor.a = color.a or 255
	draw_SimpleText( text, font, x + shadow, y + shadow, shadowColor, xalign, yalign )
	draw_SimpleText( text, font, x, y, color, xalign, yalign )
end

-- Each character pulses between `color` and `glow`, rippling left to right.
function TextFX.DrawEnchantedText( speed, text, font, x, y, color, glow, xalign, yalign )
	glow = glow or DEFAULT_ENCHANT
	x, y = TopLeft( text, font, x, y, xalign, yalign )

	local t = RealTime()
	for i, char in ipairs( Chars( text ) ) do
		draw_SimpleText( char, font, x, y, Blend( glow, color, math_abs( math_sin( ( t - i * 0.08 ) * speed ) ) ) )
		x = x + surface_GetTextSize( char )
	end
end

-- The whole string pulses between `color` and `fade`.
function TextFX.DrawFadingText( speed, text, font, x, y, color, fade, xalign, yalign )
	local c = Blend( color, fade or color_white, math_abs( math_sin( RealTime() * speed ) ) )
	draw_SimpleText( text, font, x, y, c, xalign, yalign )
end

function TextFX.DrawRainbowText( speed, text, font, x, y, xalign, yalign )
	draw_SimpleText( text, font, x, y, HSVToColor( RealTime() * 70 * speed % 360, 1, 1 ), xalign, yalign )
end

function TextFX.DrawGlowingText( static, text, font, x, y, color, xalign, yalign )
	local g = static and 1 or math_abs( math_sin( ( RealTime() - 0.1 ) * 2 ) )
	glowColor.r, glowColor.g, glowColor.b = color.r, color.g, color.b

	for i = 1, 2 do -- Raise the 2 for a heavier glow.
		glowColor.a = ( 20 - i * 5 ) * g -- 20 is the starting glow alpha, 5 is how much it drops per ring.
		draw_SimpleTextOutlined( text, font, x, y, color, xalign, yalign, i, glowColor )
	end

	draw_SimpleText( text, font, x, y, color, xalign, yalign )
end

-- style 1 hops up, style 2 dips down, style 3 waves.
function TextFX.DrawBouncingText( style, intensity, text, font, x, y, color, xalign, yalign )
	x, y = TopLeft( text, font, x, y, xalign, yalign )

	local t = RealTime()
	for i, char in ipairs( Chars( text ) ) do
		local wave = math_sin( ( t - i * 0.1 ) * 2 * intensity )
		local offset

		if style == 1 then offset = 1 - math_abs( wave )
		elseif style == 2 then offset = 1 + math_abs( wave )
		else offset = 1 - wave end

		draw_SimpleText( char, font, x, y - BOUNCE_HEIGHT * offset, color )
		x = x + surface_GetTextSize( char )
	end
end

local nextZap, zapAlpha = 0, 0
function TextFX.DrawElectricText( intensity, text, font, x, y, color, xalign, yalign )
	draw_SimpleText( text, font, x, y, color, xalign, yalign )

	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )
	if w < 1 or h < 1 then return end

	zapAlpha = math_max( zapAlpha - 1000 * FrameTime(), 0 )
	if zapAlpha > 0 then
		surface_SetDrawColor( 102, 255, 255, zapAlpha )

		for _ = 1, math_random( 5 ) do
			surface_DrawLine( left + math_random( w ), top + math_random( h ), left + math_random( w ), top + math_random( h ) )
		end
	end

	local now = RealTime()
	if nextZap <= now then
		nextZap = now + math_Rand( 0.5 + ( 1 - intensity ), 1.5 + ( 1 - intensity ) )
		zapAlpha = 255
	end
end

function TextFX.DrawFireText( intensity, text, font, x, y, color, xalign, yalign, glow, shadow )
	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )

	for i = 0, w - 1 do
		surface_SetDrawColor( 255, math_random( 255 ), 0, 150 )
		surface_DrawLine( left + i, top + h, left + i + math_random( -4, 4 ), top + math_random( h * intensity, h ) )
	end

	if shadow then TextFX.DrawShadowedText( 1, text, font, x, y, color, xalign, yalign ) end
	if glow then TextFX.DrawGlowingText( true, text, font, x, y, color, xalign, yalign ) end
	if not shadow and not glow then draw_SimpleText( text, font, x, y, color, xalign, yalign ) end
end

function TextFX.DrawSnowingText( intensity, text, font, x, y, color, snow, xalign, yalign )
	draw_SimpleText( text, font, x, y, color, xalign, yalign )

	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )
	snow = snow or color_white
	surface_SetDrawColor( snow.r, snow.g, snow.b, snow.a or 255 )

	for _ = 1, intensity do
		local sx, sy = left + math_Rand( 0, w ), top + math_Rand( 0, h )
		surface_DrawLine( sx, sy, sx, sy + 1 )
	end
end

-- A bright band sweeps across the text every few seconds.
function TextFX.DrawShineText( speed, text, font, x, y, color, shine, xalign, yalign )
	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )
	draw_SimpleText( text, font, left, top, color )

	-- The sweep takes 1 of every 2.5 seconds (at speed 1); the rest is a pause.
	local p = ( RealTime() * speed ) % 2.5
	if p > 1 or w < 1 then return end

	shine = shine or color_white
	local band = math_max( w * 0.12, 8 )
	local center = left - band + ( w + band * 2 ) * p

	-- Three nested bands, brightest in the middle, fake a soft edge.
	shineColor.r, shineColor.g, shineColor.b = shine.r, shine.g, shine.b
	for i = 1, 3 do
		local half = band * ( 4 - i ) / 6
		shineColor.a = ( shine.a or 255 ) * i / 3

		render_SetScissorRect( math_floor( center - half ), math_floor( top ), math_ceil( center + half ), math_ceil( top + h ), true )
		draw_SimpleText( text, font, left, top, shineColor )
	end
	render_SetScissorRect( 0, 0, 0, 0, false )
end

-- The text gently grows and shrinks.
function TextFX.DrawPulsingText( speed, amount, text, font, x, y, color, xalign, yalign )
	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )
	local scale = 1 + amount * math_sin( RealTime() * speed * 3 )

	DrawScaled( scale, left + w / 2, top + h / 2, TextFX.DrawGlowingText, true, text, font, left, top, color )
end

-- The text slams onto the screen from large to normal size, then shakes briefly.
-- `elapsed` is the number of seconds since the text first appeared.
function TextFX.DrawSlamText( elapsed, text, font, x, y, color, xalign, yalign )
	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )
	local SLAM, SHAKE = 0.3, 0.3

	local p = math_min( elapsed / SLAM, 1 )
	local scale = 1 + 2 * ( 1 - p ) ^ 3

	local shake = elapsed > SLAM and math_max( 1 - ( elapsed - SLAM ) / SHAKE, 0 ) * 4 or 0
	if shake > 0 then
		left = left + math_Rand( -shake, shake )
		top = top + math_Rand( -shake, shake )
	end

	DrawScaled( scale, left + w / 2, top + h / 2, TextFX.DrawGlowingText, true, text, font, left, top, color )
end

-- Types the text out one character at a time, with a blinking cursor.
-- `elapsed` is the number of seconds since the text first appeared.
function TextFX.DrawTypewriterText( elapsed, cps, text, font, x, y, color, xalign, yalign )
	-- Aligned on the full text so it doesn't slide around while typing.
	local left, top = TopLeft( text, font, x, y, xalign, yalign )
	local chars = Chars( text )
	local shown = math_min( math_floor( elapsed * cps ), #chars )

	for i = 1, shown do
		draw_SimpleText( chars[ i ], font, left, top, color )
		left = left + surface_GetTextSize( chars[ i ] )
	end

	-- Solid while typing, then blinks.
	if shown < #chars or elapsed % 1 < 0.5 then
		draw_SimpleText( "_", font, left, top, color )
	end
end

-- Red/cyan split with the occasional burst of sliced, jittering text.
local glitchUntil, nextGlitch = 0, 0
function TextFX.DrawGlitchText( intensity, text, font, x, y, color, xalign, yalign )
	local left, top, w, h = TopLeft( text, font, x, y, xalign, yalign )

	local now = RealTime()
	if now >= nextGlitch then
		glitchUntil = now + math_Rand( 0.05, 0.2 )
		nextGlitch = now + math_Rand( 0.4, 2 ) / intensity
	end

	local glitching = now < glitchUntil
	local split = ( glitching and math_random( 3, 6 ) or 1.5 ) * intensity
	local alpha = ( color.a or 255 ) / 255

	splitRed.a = 140 * alpha
	splitCyan.a = 140 * alpha
	draw_SimpleText( text, font, left - split, top, splitRed )
	draw_SimpleText( text, font, left + split, top, splitCyan )

	if not glitching or h < 1 then
		draw_SimpleText( text, font, left, top, color )
		return
	end

	-- Draw the text in horizontal slices, each shoved sideways a little.
	local slices = 5
	local sliceH = math_ceil( h / slices )
	local reach = math_ceil( 8 * intensity )

	for i = 0, slices - 1 do
		local sy = math_floor( top ) + i * sliceH
		render_SetScissorRect( 0, sy, ScrW(), sy + sliceH, true )
		draw_SimpleText( text, font, left + math_random( -reach, reach ), top, color )
	end
	render_SetScissorRect( 0, 0, 0, 0, false )
end

-- Each character gets its own hue, and the gradient scrolls across the text.
function TextFX.DrawPrismText( speed, text, font, x, y, xalign, yalign )
	x, y = TopLeft( text, font, x, y, xalign, yalign )

	local hue = RealTime() * 90 * speed
	for i, char in ipairs( Chars( text ) ) do
		draw_SimpleText( char, font, x, y, HSVToColor( ( hue - i * 18 ) % 360, 0.75, 1 ) )
		x = x + surface_GetTextSize( char )
	end
end

return TextFX
