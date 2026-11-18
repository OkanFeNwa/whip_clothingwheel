# F1 shirt glyph for whip_core

The F1 wheel renders action icons only from `window.WhipGlyphs.glyphs`, a fixed table of SVG strings
in `whip_core/html/js/glyphs.js`. A satellite cannot add a glyph at runtime: raw SVG, data URLs and
`image` fields are all ignored by the wheel's `radIcon()`. So the **Clothes** button uses
`Config.MenuIcon = 'shirt'`, and the `shirt` glyph has to be added to that table.

This is a small, purely additive patch. Re-apply it after updating `whip_core` if the update
replaces these files.

## 1. `whip_core/html/js/glyphs.js`

Add this entry inside `var GLYPHS = { ... }`, right after the existing `bag` entry:

```js
        // A SHIRT: the clothing wheel's own glyph. The silhouette is the same path as the
        // Material Design Icons `tshirt-crew` shape, drawn as an outline at the atlas's 2.1
        // weight so it sits alongside `bag` and `phone` on the F1 wheel. A satellite names
        // `shirt` through Config.MenuIcon; the atlas has to carry the drawing.
        shirt: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1"'
            + ' stroke-linecap="round" stroke-linejoin="round">'
            + '<path d="M16 21H8a1 1 0 0 1-1-1v-7.93l-1.3 1a.996.996 0 0 1-1.41 0'
            +     'l-2.83-2.78a.996.996 0 0 1 0-1.41L7.34 3H9c0 1.1 1.34 2 3 2s3-.9 3-2'
            +     'h1.66l5.88 5.88c.39.39.39 1.02 0 1.41l-2.83 2.83'
            +     'c-.39.38-1.02.38-1.41 0l-1.3-1V20a1 1 0 0 1-1 1"/></svg>',
```

## 2. `whip_core/html/js/glyphs.js` loading-screen copy

The loading screen runs before `whip_core` is downloaded, so it carries its own copy. Add the same
entry after `bag` in `whip_loadingscreen/html/js/icons.js`:

```js
        // Copy of the F1 clothing wheel's glyph in whip_core/html/js/glyphs.js.
        shirt: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1"'
            + ' stroke-linecap="round" stroke-linejoin="round">'
            + '<path d="M16 21H8a1 1 0 0 1-1-1v-7.93l-1.3 1a.996.996 0 0 1-1.41 0'
            +     'l-2.83-2.78a.996.996 0 0 1 0-1.41L7.34 3H9c0 1.1 1.34 2 3 2s3-.9 3-2'
            +     'h1.66l5.88 5.88c.39.39.39 1.02 0 1.41l-2.83 2.83'
            +     'c-.39.38-1.02.38-1.41 0l-1.3-1V20a1 1 0 0 1-1 1"/></svg>',
```

## 3. Editor type hint (optional)

In `whip_core/types/client.lua`, add `'shirt'` to the `WhipGlyph` alias so editors know the key:

```lua
---| 'info' | 'warning' | 'object' | 'ped' | 'camera' | 'shirt'
```

## Verify

```bash
node --check whip_core/html/js/glyphs.js
node --check whip_loadingscreen/html/js/icons.js
```

Then `restart whip_core` and `restart whip_clothingwheel`. The **Clothes** slice on F1 now draws
the shirt outline; without the patch it would draw `C` (the label's first letter).
