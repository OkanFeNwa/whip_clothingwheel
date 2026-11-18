# whip_clothingwheel

A WHIP satellite that puts a single **Clothes** button on the quick **F1** wheel. Pressing it opens
an **NUI overlay** that mimics the wheel but is isolated: it only contains garments, with
**Restore** at the top center and **Back** at the bottom. No phone, inventory, emotes or dev tools
from other WHIP resources appear.

No emoji. The submenu icons are **real Iconify SVGs**, embedded in `html/app.js`: no runtime fetch,
no CDN dependency. Logic stays server-side: the client only applies the values it receives.

## Installation

The resource can live in **any folder under `resources/`**: `resources/[custom]/whip_clothingwheel`,
`resources/[local]/whip_clothingwheel`, `resources/whip_clothingwheel`, etc. The folder name is not
hardcoded anywhere: the manifest only declares `dependency 'whip_core'` and loads
`@whip_core/lib/satellite.lua`.

Make sure `server.cfg` loads it **after `whip_core`**, either by `ensure`-ing the folder that contains
it (for example `ensure [custom]`) or by adding an explicit `ensure whip_clothingwheel`. If your
config already has `ensure [custom]` after `whip_core`, dropping it into `[custom]` needs no change;
if you pick another folder, add the matching `ensure` line.

- `dependency 'whip_core'` and `@whip_core/lib/satellite.lua` are already in the manifest.
- No changes to `whip_core` are required.

Repository: https://github.com/OkanFeNwa/whip_clothingwheel

```bash
cd resources
git clone https://github.com/OkanFeNwa/whip_clothingwheel.git
```

Then place the cloned folder wherever you prefer under `resources/` and make sure it is ensured in
`server.cfg` after `whip_core`.

## Languages

All visible text is translated. In `config.lua` change a single line:

```lua
Config.Locale = 'it' -- it, en, es, fr, de
```

Complete `it`, `en`, `es`, `fr`, `de` blocks are included in `Config.Locales`. Copy a block to add
another language. Italian, English, Spanish, French and German cover:

- the title and label of the **Clothes** button on the F1 wheel, plus its description;
- **Restore**, **Back**, slice states and the pill text;
- the world prompt for dropped garments (`Wear <garment>`);
- WHIP notifications and the `/cwlose` and `/cwmodel` dev command messages;
- garment names in languages other than Italian.

Italian has no `slots` block: it uses the `label` values you write directly in `Config.Slots`, so
customizations like `label = 'Orecchie'` are never overwritten by a translation. Other languages
have `Config.Locales[lang].slots` with all names translated. Fallback is `en`, then `it`.

## How to use

Open the F1 wheel:

1. Select **Clothes**. The core atlas has no shirt glyph and a satellite cannot add one, so the
   button uses the character `T` (`Config.MenuIcon = 'T'`) as a T-shirt cue: it is no longer the
   old bag. The real SVG shirt icon lives in the submenu.
2. The wheel closes and our submenu opens with the **same geometry as the WHIP wheel**: thick slabs
   of dark glass, a glow, a stat disc in the center and a pill below. The values (radii 126/258,
   lift 14, gap 1.4°, disc 176) are identical to `whip_core/html/css/ui.css` §5.
3. Each slice shows **only the garment icon** and its name: no "Take off hat" text or similar.
   Hovering a slice shows the large icon in the center disc and the state in the bottom pill
   (worn / not worn / on the ground).
4. Click a slice to put on or take off that garment. The menu stays open and updates itself. The
   center disc fills **only when you change slice**, like the core's `radSelect()`: moving within
   the same slice does not restart the animation.
5. A just-removed garment stays **highlighted in white** until you select it again or put it back
   on (even from the ground prop). Several garments removed in a row all stay lit. **Restore**
   turns them all off.
6. **Restore** is the first slice, at the top center: it brings **all** garments back to their
   original appearance, including hidden slots such as sleeves (`arms`) and trousers (`legs`), and
   removes drops. It is disabled when there is nothing to restore.
7. **Back**, the pill at the bottom, closes the submenu and **reopens the WHIP quick wheel**. Esc and
   right-click do the same.

If a garment has fallen to the ground, its slice is highlighted in orange and is not clickable: it
must be worn from the object in the world.

The wheel **does not create objects**: "take off" only removes the component/prop from the ped.
Ground props are created only by the lose event or export below.

### Icons

No emoji and no hand-drawn icons. The submenu uses real SVGs from Iconify, saved in the code:

- **Material Design Icons** (Apache-2.0, Pictogrammers) for hat, glasses, ears, watch, shirt,
  tank top, necklace, mask, decal and restore;
- **UIX Icons Solid** (MIT) for bracelet and jacket.

They are all 24×24, use `currentColor` and the core's box, so they stay sharp both at 28 px on the
slices and at 60 px in the disc. The key is `Config.Slots[].icon`; `restore` is the circular arrow.

### Animations

Every garment has its own clip, and **putting on** and **taking off** use two different gestures.
All clips were verified against WHIP's GTA V dump:

- hat: `missheistdockssetup1hardhat@ / put_on_hat` and
  `veh@common@fp_helmet@ / take_off_helmet_stand`;
- glasses: `clothingspecs / put_on` and `clothingspecs / take_off` (real shop clips);
- ears: `veh@common@fp_helmet@ / put_on_helmet` and
  `mini@ears_defenders / takeoff_earsdefenders_idle`;
- watch: `anim@random@shop_clothes@watches / intro` and `/ outro`;
- bracelet: `anim@random@shop_clothes@watches / idle_b` and `/ idle_d`;
- mask: `mp_masks@on_foot / put_on_mask` and `misscommon@std_take_off_masks / take_off_mask_ps`;
- shirt, tank top and decal: variants `a`, `b`, `c` of `clothingshirt`
  (`try_shirt_positive/negative_*`);
- shoes: `clothingshoes / try_shoes_positive_c` and `try_shoes_negative_c`;
- **jacket** (historical id `armor`, previously labelled "Corazza"): a real jacket change
  `anim@scripted@avi4@ig1_outfit@male@ / change_a` (female `@heeled@ / change_a`), and `change_c` to
  take it off; no longer the full undress `change_highroller*`;
- bag: `anim@heists@money_grab@duffel / enter_strap` and `exit_strap` (strap-on / strap-off);
- restore: `switch@franklin@getting_ready / 002334_02_fras_v2_11_getting_dressed_exit` (male) and
  `change_highroller` (female).

Clips play once: `duration = -1` with flag 48 (upper body + control) and no loop; the client cleans
up the dict at `stopAt` and only stops a clip if one is still active. The server sends
`whip_clothingwheel:anim` with `takeoff`, `wear` or `restore` and the slot only after the change has
succeeded. Disable them all with `Config.Animate = false`, or edit `Config.WearAnim`,
`Config.RestoreAnim` and `Config.PickupAnim`.

### Included slots

props: hat, glasses, ears, watch, bracelet.
components: mask, shirt, tank top, shoes, accessory, jacket (`armor`), decal, bag.

`arms` (sleeves) and `legs` (trousers) remain in `config.lua` but are commented out: they do not
appear in the wheel. **Restore** still keeps an eye on them, because WHIP treats them as apparel.
Hair is excluded: WHIP handles it through `look.hair`, not as a normal garment.

## Losing a garment (wear only, no item)

### Server-side export

```lua
exports.whip_clothingwheel:LoseItem(source, slotId, coords)
-- source:  the player's source
-- slotId:  'hat', 'glasses', 'ear', 'watch', 'bracelet',
--          'mask', 'tops', 'undershirt', 'arms', 'legs', 'shoes',
--          'accessory', 'armor', 'decal', 'bag'
-- coords:  optional; vector3/vector4. Defaults to the player's position.
-- returns: true | false, reason
```

Example:

```lua
exports.whip_clothingwheel:LoseItem(source, 'hat')
```

### Client → server event

```lua
TriggerServerEvent('whip_clothingwheel:lose', 'hat')
```

It is protected by `SecureEvent` (rate limit + slot enum): arbitrary values are rejected.

### Dev commands

Require the ACE permission `whip.devtools`:

- `/cwlose <slot>` — drops a garment.
- `/cwmodel [slot]` — prints, for worn garments, `drawable`, `texture` and the model that would be
  used on the ground. Used to fill in `Config.DropModels`.

### What happens

Every lost garment becomes a **world prop**. The prop shows **a single prompt: "Wear <garment>"**
with **WHIP's real pickup arrow** (`icon = 'pickup'`): no more "cap" text, because `icon` accepts a
core glyph, not an SVG key from our submenu.

- There is no "Pick up" action, no WHIP ground item and no inventory item. The icon only says the
  garment can be collected; the action is "Wear".
- Selecting "Wear" makes the server check that the drop exists and the player is within
  `Config.WearReach` meters, then re-applies the garment to the ped and clears the drop.
- WHIP's **real grab** plays (`anim@scripted@player@freemode@gen_grab@male@` or `@heeled@`), the same
  one used by `whip_core/client/ground.lua`. The clip is chosen by the garment's height and side
  relative to the ped (`low_rh`, `low_lh`, `low_2h`; two hands for bag and jacket). The prop
  disappears **1 second after the action starts** (`Config.PickupAnim.removeAt = 1000`), when the
  hand is already closed. There are guards for dead, in vehicle, ragdoll, falling and swimming.
- Right after (`Config.PickupAnim.wearAfterGrab = 150` ms) the **garment-specific animation** plays:
  the grab and the "put on" do not overlap.
- While the garment is on the ground, its slice in the submenu stays disabled and its white glow is
  turned off.

### Ground model = worn garment

GTA V **does not expose a native** to get the world model of the drawable a ped wears:
`GET_PED_PROP_MODEL` does not exist and `GetPedPropCollectionName` returns only the collection name
(for example `female_freemode_beach`), not an object model. The exact mapping is therefore
configured:

```lua
-- config.lua
Config.DropModels = {
    hat = {
        ['7'] = 'prop_cap_01',        -- drawable 7 = that hat
        ['12'] = 'prop_busker_hat_01',
    },
}
```

The key is the **drawable worn at the moment of the loss**. The resolved model is saved in the
metadata with the drop, so it survives a restart. If there is no entry, the generic
`Config.Slots[].model` is used: for the hat that is `prop_cap_01`, a **cap**, not a cowboy hat. To get
the exact model of the hat you are wearing, add an entry with the drawable shown by `/cwmodel hat`.

### Base models

The generic `Config.Slots[].model` values were chosen from real WHIP catalog models:
`prop_cap_01` (cap), `prop_aviators_01`, `prop_ear_defenders_01`, `sf_prop_sf_watch_01a`,
`h4_prop_h4_bracelet_01a`, `prop_mask_fireman`, `prop_ld_tshirt_01`, `prop_folded_polo_shirt`,
`prop_ld_shoe_02`, `h4_prop_h4_necklace_01a`, `prop_bodyarmour_02`, `prop_cs_tshirt_ball_01` and
`bkr_prop_duffel_bag_01a`. The `DropModels` table always takes precedence when you know the exact
drawable.

## State and persistence

- The baseline (original appearance) is saved in the character metadata under
  `clothingwheel_baseline` and is a full copy of `appearance`, not just the visible slots.
- **Restore** passes the entire baseline to `SetPlayerAppearance(..., { only = { 'apparel', 'props' } })`:
  this restores `arms`, `legs` and every other apparel/props slot, not only the garments in the wheel.
- Tracked drops (slot + coordinates + drawable/texture + model) are saved under `clothingwheel_drops`,
  so they survive a resource restart: the props are recreated at login.
- After **Restore** the baseline is removed and drops are cleared.

## NUI

| File | Role |
| --- | --- |
| `html/index.html` | Submenu structure (glow, SVG slices, disc, Back pill) |
| `html/style.css` | Copy of WHIP quick wheel styles: slabs, beam, disc, pill, Barlow font, removed-garment glow |
| `html/app.js` | Local Iconify SVGs, exact WHIP geometry, angular aiming, refill only on slice change, latch, click, right-click, Esc |
| `client/nui.lua` | `SendNUIMessage` with translated strings, `SetNuiFocus`, `SetCursorLocation`, `select` / `back` / `close` callbacks |

The **Clothes** button on the F1 wheel opens the page; `whip_clothingwheel:state` updates the open
submenu after every change confirmed by the server.

## Events

| Name | Direction | Use |
| --- | --- | --- |
| `whip_clothingwheel:state` | server → client | Updated state + values to apply |
| `whip_clothingwheel:apply` | server → client | Only values to apply to natives |
| `whip_clothingwheel:anim` | server → client | `takeoff` / `wear` / `restore` animation + slot after a confirmed change |
| `whip_clothingwheel:drop:spawn` | server → client | Creates prop + "Wear" prompt (`pickup` glyph) for a dropped garment |
| `whip_clothingwheel:pickup` | server → client | Drop coordinates + slot: starts the animation and removes the prop when the hand closes |
| `whip_clothingwheel:drop:remove` | server → client | Removes prop + prompt for one slot |
| `whip_clothingwheel:drop:removeAll` | server → client | Removes all props + prompts |
| `whip_clothingwheel:state` | SecureCallback | Client requests state and current values |
| `whip_clothingwheel:toggle` | SecureEvent | Put on / take off a slot |
| `whip_clothingwheel:restore` | SecureEvent | Full restore of apparel + props |
| `whip_clothingwheel:lose` | SecureEvent | Drop a slot |
| `whip_clothingwheel:wearGround` | SecureEvent | Wear a dropped garment (distance checked) |
| `whip_clothingwheel:drops:sync` | SecureEvent | Client asks to recreate drops from metadata (after a restart) |

## Configuration

`config.lua` contains `Locale` and `Locales` (5 languages), metadata keys, rate limit,
notifications/animations, `WearReach`, `ClearDropsOnRestore`, `MenuIcon`, the `DropModels` map
(drawable → ground garment model), `WearAnim` (a different clip per garment and for put on/take off),
`RestoreAnim`, `PickupAnim` (WHIP grab, `removeAt = 1000`) and the visible slots with their prop
model and SVG icon key. `arms` and `legs` are commented out and do not appear in the wheel, but
restore still includes them.
