# TTT EndRoundFX

Animated **"EndRound Deathmatch"** text for Garry's Mod's Trouble in Terrorist Town. When a round ends and post-round deathmatch starts, every player sees the same animated banner at the top of the screen. It goes away when the next round starts preparing.

Works with **TTT** and **TTT2**. The addon doesn't load in other gamemodes.

## Effects

| Name         | Description                                                  |
|--------------|--------------------------------------------------------------|
| `glow`       | Soft pulsing glow                                            |
| `fade`       | Fades between two colours                                    |
| `rainbow`    | Cycles through the colour wheel                              |
| `enchant`    | Colour ripple that moves across the letters                  |
| `bounce`     | Letters move up and down in a wave                           |
| `electric`   | Occasional sparks across the text                            |
| `fire`       | Flickering flames behind the text                            |
| `snow`       | Sparkles on the text                                         |
| `shine`      | A bright band sweeps across the text                         |
| `pulse`      | The text gently grows and shrinks                            |
| `slam`       | The text slams onto the screen and shakes briefly            |
| `typewriter` | Typed out letter by letter, with a blinking cursor           |
| `glitch`     | Red/cyan split with bursts of sliced, jittering text         |
| `prism`      | Scrolling rainbow gradient across the letters                |

By default, a random effect is picked each round (never the same one twice in a row). To see any effect without waiting for a round to end, run `endroundfx_preview <name>` in your console. Only you will see it.

## Installation

Put the folder in `garrysmod/addons/` on your server, so you end up with `garrysmod/addons/ttt-endroundfx/lua/...`.

The Bebas Neue font gets to clients through `resource.AddFile`, so you'll need FastDL or `sv_allowdownload 1` for it. Clients without the font see a default one instead.

> **Upgrading from v1?** Delete the old folder before copying the new one in. v2 moved `lua/autorun/client/moat_texteffects.lua` into the addon's own folder.

## Configuration

### Server convars

| Convar                    | Default               | Description                                                                         |
|---------------------------|-----------------------|-------------------------------------------------------------------------------------|
| `endroundfx_enabled`      | `1`                   | Turns the effect on or off                                                          |
| `endroundfx_effect`       | `random`              | `random`, one effect name, or a comma-separated list to pick from (for example `glow,shine,slam`) |
| `endroundfx_text`         | `EndRound Deathmatch` | Text to show                                                                        |
| `endroundfx_y`            | `0.1`                 | Vertical position, as a fraction of screen height (`0` = top, `1` = bottom)         |
| `endroundfx_winner_color` | `0`                   | Colour the text by the team that won: red for traitors, green for innocents, and team colours in TTT2 |
| `endroundfx_sound`        | *(empty)*             | Sound to play when the text appears, relative to `sound/` (for example `buttons/bell1.wav`). Custom sounds need to be downloaded by clients, just like the font |
| `endroundfx_force_dm`     | `1`                   | Turns on `ttt_postround_dm` when the server starts. Set to `0` to use your own setting |

`endroundfx_text`, `endroundfx_y` and `endroundfx_sound` are sent to clients automatically.

The text only appears when `ttt_postround_dm` is on, because there's no deathmatch to announce otherwise.

### End-round respawn

Brings everyone back to life for the post-round deathmatch. It's off by default. Like the text, it only runs when `ttt_postround_dm` is on.

| Convar                              | Default              | Description                                                                 |
|-------------------------------------|----------------------|-----------------------------------------------------------------------------|
| `endroundfx_respawn`                | `0`                  | Respawns dead players when the round ends. Players still alive are healed to full health. Players who chose spectator mode are left alone |
| `endroundfx_respawn_clear_ragdolls` | `1`                  | Removes player corpses before respawning, to cut down on entities during the deathmatch. Map ragdolls are left alone |
| `endroundfx_respawn_give_weapon`    | `1`                  | Gives a weapon to anyone who has no pistol or heavy weapon, one second after respawning so pointshop/loadout guns go first |
| `endroundfx_respawn_weapon`         | `weapon_zm_revolver` | Weapon class to give out (the Deagle by default)                            |
| `endroundfx_respawn_ammo`           | `36`                 | Reserve ammo given with the weapon. `0` for none                            |
| `endroundfx_respawn_ammo_type`      | *(empty)*            | Ammo type to give, for example `AlyxGun`. Leave empty to use the weapon's own ammo type |
| `endroundfx_respawn_exclude_maps`   | `ttt_space_station,ttt_lost_temple_v2` | Comma-separated maps where none of the above happens      |

When `endroundfx_respawn` is `0`, the other respawn settings do nothing.

**[TTT Spectator Deathmatch](https://github.com/Lil-Isma/TTT_Spectator_Deathmatch) support.** Before respawning, anyone still playing as a ghost is taken out of ghost mode without an announcement to other players, and any leftover `weapon_ghost_*` weapons are removed. This way ghosts come back as normal players and still get the weapon.

### Client convars

| Convar                      | Default | Description                                                   |
|-----------------------------|---------|---------------------------------------------------------------|
| `endroundfx_draw`           | `1`     | Set to `0` to hide the text completely                        |
| `endroundfx_reduced_motion` | `0`     | Set to `1` to show the text without animation, flashing or shaking |

### Colours

Colours are set at the top of [`lua/endroundfx/cl_endroundfx.lua`](lua/endroundfx/cl_endroundfx.lua).

## For developers

**Skip the banner for a round.** Return `false` from the server-side `EndRoundFXShouldShow` hook. It receives the round result from `TTTEndRound`.

```lua
hook.Add( "EndRoundFXShouldShow", "MyAddon", function( result )
	if MyAddon.IsSpecialRound() then return false end
end )
```

**Use the effects yourself.** The effects library has no global names, so it won't clash with other copies of moat's text effects:

```lua
local TextFX = include( "endroundfx/cl_texteffects.lua" )
TextFX.DrawShineText( 1, "Hello", "DermaLarge", 100, 100, color_white, Color( 255, 200, 0 ) )
```

**How it works.** When `TTTEndRound` fires, the server picks an effect and stores its index in a networked global (`SetGlobal2Int`). It clears the value on `TTTPrepareRound`. Clients draw whatever effect that global points to. Because it's state rather than a one-time message, players who join during post-round still see the banner.

## License

EndRoundFX is released under the [MIT License](LICENSE).

[`lua/endroundfx/cl_texteffects.lua`](lua/endroundfx/cl_texteffects.lua) is a modified version of moat's text effects. The original was published without a license and is included here with credit.

Bebas Neue is © 2010 Dharma Type and licensed under the [SIL Open Font License 1.1](OFL.txt). You can find it at [dharmatype/Bebas-Neue](https://github.com/dharmatype/Bebas-Neue).

## Credits

- **pyro** / [DarkPyro's Servers](https://darkpyro.gg/): EndRoundFX
- **[moat](https://steamcommunity.com/id/moat_)**: the original text effects library
- **Ryoichi Tsunekawa / [Dharma Type](https://dharmatype.com/)**: Bebas Neue
