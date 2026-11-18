(() => {
    'use strict';

    // Real SVG icons from Iconify, embedded locally so the NUI never fetches
    // anything at runtime:
    //   Material Design Icons (Apache-2.0) — pictogrammers.com
    //   UIX Icons Solid (MIT) — github.com/mdrakibshekh/uix-icons
    //   IconOven (MIT) — bulletproof vest
    //   Huge Icons (MIT) — long-sleeve shirt
    // Keys are Config.Slots[].icon in config.lua.
    const ICONS = {
        restore: '<path fill="currentColor" d="M12 3a9 9 0 0 0-9 9H0l4 4l4-4H5a7 7 0 0 1 7-7a7 7 0 0 1 7 7a7 7 0 0 1-7 7c-1.5 0-2.91-.5-4.06-1.3L6.5 19.14A9.1 9.1 0 0 0 12 21a9 9 0 0 0 9-9a9 9 0 0 0-9-9m2 9a2 2 0 0 0-2-2a2 2 0 0 0-2 2a2 2 0 0 0 2 2a2 2 0 0 0 2-2"/>',
        hat: '<path fill="currentColor" d="M19.11 11.92q.03-.315.03-.63c0-3.43-1.43-7.15-2.86-7.15S13.42 5.57 12 5.57c-1.43 0-2.86-1.43-4.29-1.43s-2.85 3.65-2.85 7.15c0 .21 0 .42.02.63c2.34.53 4.72.8 7.12.79c2.45 0 4.83-.27 7.11-.79M3.45 18.18a29.7 29.7 0 0 0 17.09 0A2.14 2.14 0 0 0 22 16.17c0-.45-.14-.88-.39-1.25c-.26-.36-.61-.63-1.05-.78c-2.7.86-5.56 1.31-8.56 1.31S6.13 15 3.43 14.14c-.43.15-.78.43-1.04.79c-.25.36-.39.79-.39 1.24c0 .94.61 1.73 1.45 2.01"/>',
        glasses: '<path fill="currentColor" d="M3 10c-.24 0-.45.09-.59.25c-.14.15-.2.37-.17.61l.5 2.99C2.82 14.5 3.4 15 4 15h3c.64 0 1.36-.56 1.5-1.18l1.06-3.19c.04-.13.01-.32-.06-.44c-.11-.12-.28-.19-.5-.19zm4 7H4C2.38 17 .96 15.74.76 14.14l-.5-2.99C.15 10.3.39 9.5.91 8.92S2.19 8 3 8h6c.83 0 1.58.35 2.06.96c.11.15.21.31.29.49c.43-.09.87-.09 1.29 0c.08-.18.18-.34.3-.49C13.41 8.35 14.16 8 15 8h6c.81 0 1.57.34 2.09.92c.51.58.75 1.38.65 2.19l-.51 3.07C23.04 15.74 21.61 17 20 17h-3c-1.56 0-3.08-1.19-3.46-2.7l-.9-2.71c-.38-.28-.91-.28-1.29 0l-.92 2.78C10.07 15.82 8.56 17 7 17m8-7c-.22 0-.39.07-.5.19c-.08.12-.1.31-.05.51l1.01 3.05c.18.69.9 1.25 1.54 1.25h3c.59 0 1.18-.5 1.25-1.11l.51-3.07c.03-.2-.03-.42-.17-.57A.77.77 0 0 0 21 10z"/>',
        ear: '<path fill="currentColor" d="M17 20c-.29 0-.56-.06-.76-.15c-.71-.35-1.21-.88-1.71-2.38c-.53-1.56-1.47-2.29-2.39-3c-.79-.61-1.61-1.24-2.32-2.53C9.29 11 9 9.93 9 9c0-2.8 2.2-5 5-5s5 2.2 5 5h2c0-3.93-3.07-7-7-7S7 5.07 7 9c0 1.26.38 2.65 1.07 3.9c.93 1.65 1.98 2.48 2.85 3.15c.81.62 1.39 1.07 1.71 2.05c.6 1.82 1.37 2.84 2.73 3.55c.51.23 1.07.35 1.64.35a4 4 0 0 0 4-4h-2a2 2 0 0 1-2 2M7.64 2.64L6.22 1.22A10.97 10.97 0 0 0 3 9c0 3.04 1.23 5.79 3.22 7.78l1.41-1.41A8.95 8.95 0 0 1 5 9c0-2.5 1-4.74 2.64-6.36M11.5 9a2.5 2.5 0 0 0 2.5 2.5A2.5 2.5 0 0 0 16.5 9A2.5 2.5 0 0 0 14 6.5A2.5 2.5 0 0 0 11.5 9"/>',
        watch: '<path fill="currentColor" d="M6 12a6 6 0 0 1 6-6a6 6 0 0 1 6 6a6 6 0 0 1-6 6a6 6 0 0 1-6-6m14 0a7.94 7.94 0 0 0-3.05-6.27L16 0H8l-.95 5.73A7.94 7.94 0 0 0 4 12c0 2.54 1.19 4.81 3.05 6.27L8 24h8l.95-5.73A7.96 7.96 0 0 0 20 12"/>',
        bracelet: '<path fill="currentColor" fill-rule="evenodd" d="M6.31 17.226q-4.373-1.143-4.558-3.415l-.002-.061v-4q0-1.973 3.273-3.179Q7.931 5.5 12 5.5t6.977 1.071Q22.25 7.777 22.25 9.75v4l-.002.061q-.185 2.272-4.558 3.415q-.069.018-.139.022q-.837 1.002-2.676 1.002h-5.75q-1.839 0-2.676-1.002q-.07-.004-.139-.022M20.749 9.72q-.036-.91-2.291-1.741Q15.801 7 12 7t-6.458.979Q3.287 8.81 3.251 9.72q.125 1.076 2.825 1.883Q6.799 10 9.125 10h5.75q2.326 0 3.049 1.603q2.7-.807 2.825-1.883M3.25 11.986v1.729q.112 1.019 2.533 1.797q-.033-.302-.033-.637v-1.5q0-.155.007-.303q-1.555-.462-2.507-1.086m17.5 1.729v-1.729q-.952.624-2.507 1.086q.007.148.007.303v1.5q0 .335-.033.637q2.421-.778 2.533-1.797"/>',
        mask: '<path fill="currentColor" fill-rule="evenodd" d="M5.25 9v5.25q0 1.71.929 2.822l-2.014 1.007Q2.25 19.036 2.25 21.5q0 .074.014.146q.015.073.043.141t.069.13q.041.061.094.113q.052.053.113.094t.13.069t.141.043t.146.014h18q.074 0 .146-.014q.073-.015.141-.043t.13-.069q.061-.041.113-.094q.053-.052.094-.113t.069-.13t.043-.141t.014-.146q0-2.464-1.915-3.421l-2.014-1.007q.929-1.112.929-2.822V9q0-2.796-1.977-4.773T12 2.25T7.227 4.227T5.25 9m3 1.625q0-2.375 2.375-2.375h2.75q2.375 0 2.375 2.375T13.375 13h-2.75Q8.25 13 8.25 10.625"/>',
        tops: '<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"><path d="M5.5 7c.329.986.719 1.984.86 3.02c.1.743.06 1.497-.019 3.005L6 19.527c0 .705.12 1.082.755 1.423c2.613 1.4 7.877 1.4 10.49 0c.635-.34.755-.718.755-1.423l-.341-6.502c-.08-1.508-.119-2.262-.018-3.006c.14-1.035.53-2.033.859-3.019"/><path d="M5.971 18.513c-.466.233-.932.537-1.474.479c-.917-.098-1.13-.54-1.317-1.649L2.1 10.921c-.145-.858-.145-.865.083-1.706l.538-1.983c.364-1.342.546-2.013.982-2.525c.437-.512 1.072-.8 2.343-1.375L8.59 2.179c.395-.178.398-.179.832-.179h5.156c.434 0 .437 0 .832.18l2.544 1.152c1.271.575 1.906.863 2.343 1.375c.436.512.618 1.183.982 2.525l.538 1.983c.228.84.228.848.083 1.706l-1.08 6.422c-.187 1.11-.401 1.552-1.32 1.65c-.567.06-.981-.234-1.474-.48"/><path d="M9 2.5s.908 1.915 1.66 2.314c.387.204.87.186 1.34.186s.953.018 1.34-.186C14.091 4.414 15 2.5 15 2.5"/></g>',
        undershirt: '<path fill="currentColor" d="M16 21H8a1 1 0 0 1-1-1v-7.93l-1.3 1a.996.996 0 0 1-1.41 0l-2.83-2.78a.996.996 0 0 1 0-1.41L7.34 3H9c.29 1.8 1.4 3.37 3 4.25c1.6-.88 2.71-2.45 3-4.25h1.66l5.88 5.88c.39.39.39 1.02 0 1.41l-2.83 2.83c-.39.38-1.02.38-1.41 0l-1.3-1V20a1 1 0 0 1-1 1"/>',
        arms: '<path fill="currentColor" d="M12 4a3.5 3.5 0 0 0-3.5 3.5h2A1.5 1.5 0 0 1 12 6a1.5 1.5 0 0 1 1.5 1.5A1.5 1.5 0 0 1 12 9c-.55 0-1 .45-1 1v1.75L2.4 18.2A1 1 0 0 0 3 20h18a1 1 0 0 0 .6-1.8L13 11.75v-.9a3.5 3.5 0 0 0 2.5-3.35A3.5 3.5 0 0 0 12 4m0 9.5l6 4.5H6Z"/>',
        legs: '<path fill="currentColor" d="M12 2a2 2 0 0 1 2 2a2 2 0 0 1-2 2a2 2 0 0 1-2-2a2 2 0 0 1 2-2m-1.5 5h3a2 2 0 0 1 2 2v5.5H14V22h-4v-7.5H8.5V9a2 2 0 0 1 2-2"/>',
        shoes: '<path fill="currentColor" d="M10.74 11.72c.47 1.23.42 2.51-.99 3.02c-2.9 1.07-3.55-1.74-3.59-1.88zm-5.03-.81l4.32-1.07c-.19-1.05.1-2.1.1-3.34c0-1.68-1.33-4.97-3.45-4.44c-2.42.6-2.77 3.29-2.68 4.59c.12 1.3 1.64 4.08 1.71 4.26m12.14 8.94c-.03.15-.69 2.95-3.59 1.89c-1.4-.52-1.46-1.8-.99-3.03zm2.15-6.2c.1-1.3-.24-4-2.67-4.6c-2.11-.55-3.44 2.76-3.44 4.45c0 1.23.28 2.28.11 3.33l4.3 1.07c.08-.18 1.59-2.96 1.7-4.25"/>',
        accessory: '<path fill="currentColor" d="M21.5 5h-2c0 4.14-3.36 7.5-7.5 7.5S4.5 9.14 4.5 5h-2c.05 5.11 4.09 9.29 9.2 9.5c-.6.9-1.7 2.7-1.7 3.5c0 2.67 4 2.67 4 0c0-.8-1.1-2.6-1.7-3.5c5.11-.21 9.15-4.39 9.2-9.5"/>',
        jacket: '<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"><path d="M8 2.75h.75q1 0 1.54.84l1.17 1.82q.54.84 1.08 0l1.17-1.82q.54-.84 1.54-.84H16q1 0 1.12.99l.26 2.27q.12.99.93 1.58l1.13.82q.81.59.81 1.59v8.25q0 1-.71 1.71l-.58.58q-.71.71-1.71.71H6.75q-1 0-1.71-.71l-.58-.58q-.71-.71-.71-1.71V10q0-1 .81-1.59l1.13-.82q.81-.59.93-1.58l.26-2.27Q7 2.75 8 2.75"/><rect width="7.5" height="7" x="8.25" y="10" rx="1.5"/><path d="M3.75 13.5h1.5m13.5 0h1.5"/></g>',
        decal: '<path fill="currentColor" d="M18.5 2h-13C3.6 2 2 3.6 2 5.5v13C2 20.4 3.6 22 5.5 22H16l6-6V5.5C22 3.6 20.4 2 18.5 2M15 20v-1.5c0-1.9 1.6-3.5 3.5-3.5H20z"/>',
        bag: '<path fill="currentColor" d="M16 5V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v1a4 4 0 0 0-4 4v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9a4 4 0 0 0-4-4m-6-1h4v1h-4zm2 5l2 2l-2 2l-2-2zm6 7H9v2H8v-2H6v-1h12z"/>',
    };

    // Exact numbers from whip_core/html/js/ui.js §5.
    const RAD = {
        C: 280, rIn: 126, rOut: 258, rMid: 194, gap: 1.4, lift: 14, beamIn: 92,
        dead: 70, big: 1.25,
    };
    const ICON_PX = 28; // n = 16 => ui.js's `n > 12 ? 28px` branch
    const ICON_S = ICON_PX / 24;
    const LABEL_PX = 11; // n = 16 => ui.js's `n > 12 ? 11px` branch
    const RADIAL_FADE_MS = 180;

    const RAD_MOUSE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1"'
        + ' stroke-linecap="round" stroke-linejoin="round">'
        + '<rect x="6.2" y="2.6" width="11.6" height="18.8" rx="5.8"/>'
        + '<path d="M6.2 9.6h11.6"/><path d="M12 2.6v7"/>'
        + '<path d="M12 5.2v1.8" stroke-width="2.6"/></svg>';

    const root = document.getElementById('root');
    const radial = document.getElementById('radial');
    const svg = document.getElementById('svg');
    const beam = document.getElementById('beamPath');
    const fill = document.getElementById('discFill');
    const hero = document.getElementById('discHero');
    const mouseHint = document.getElementById('mouseHint');
    const pillDesc = document.getElementById('pillDesc');
    const pillName = document.getElementById('pillName');
    const backBtn = document.getElementById('back');

    const RES = (typeof GetParentResourceName === 'function')
        ? GetParentResourceName() : 'whip_clothingwheel';

    let items = [];
    let current = -1;
    let filledIndex = -1;
    const latchedIds = new Set(); // capi appena tolti: restano "accesi"
    let pendingSelect = null;     // id inviato al server, in attesa dello stato
    let visible = false;
    let hideTimer = null;

    function post(name, data) {
        return fetch('https://' + RES + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).catch(() => {});
    }

    function paths(name) { return ICONS[name] || ICONS.tops; }

    function esc(s) {
        return String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({
            '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
        }[c]));
    }

    function iconSvg(name, sizePx) {
        return '<svg viewBox="0 0 24 24" width="' + sizePx + '" height="' + sizePx
            + '" fill="currentColor" aria-hidden="true">' + paths(name) + '</svg>';
    }

    function polar(r, deg) {
        const t = deg * Math.PI / 180;
        return { x: RAD.C + r * Math.cos(t), y: RAD.C + r * Math.sin(t) };
    }

    function sector(r0, r1, a0, a1) {
        const f = (v) => v.toFixed(1);
        const p0 = polar(r1, a0), p1 = polar(r1, a1);
        const p2 = polar(r0, a1), p3 = polar(r0, a0);
        return 'M' + f(p0.x) + ' ' + f(p0.y)
            + ' A' + r1 + ' ' + r1 + ' 0 0 1 ' + f(p1.x) + ' ' + f(p1.y)
            + ' L' + f(p2.x) + ' ' + f(p2.y)
            + ' A' + r0 + ' ' + r0 + ' 0 0 0 ' + f(p3.x) + ' ' + f(p3.y) + ' Z';
    }

    function ring(r0, r1) {
        const c = RAD.C;
        return 'M' + (c + r1) + ' ' + c + ' A' + r1 + ' ' + r1 + ' 0 1 1 ' + (c - r1) + ' ' + c
            + ' A' + r1 + ' ' + r1 + ' 0 1 1 ' + (c + r1) + ' ' + c + ' Z'
            + ' M' + (c + r0) + ' ' + c + ' A' + r0 + ' ' + r0 + ' 0 1 0 ' + (c - r0) + ' ' + c
            + ' A' + r0 + ' ' + r0 + ' 0 1 0 ' + (c + r0) + ' ' + c + ' Z';
    }

    function slabPath(i, n, r0, r1) {
        if (n === 1) return ring(r0, r1);
        const step = 360 / n;
        const th = -90 + i * step; // first slice (Ripristina) is centred at the top
        return sector(r0, r1, th - step / 2 + RAD.gap / 2, th + step / 2 - RAD.gap / 2);
    }

    function iconAt(name, cx, cy) {
        const tx = (cx - ICON_PX / 2).toFixed(1);
        const ty = (cy - ICON_PX / 2).toFixed(1);
        return '<g class="rad-icon" transform="translate(' + tx + ' ' + ty + ') scale('
            + ICON_S.toFixed(4) + ')">' + paths(name) + '</g>';
    }

    function render() {
        const n = items.length;
        if (!n) { svg.innerHTML = ''; beam.setAttribute('d', ''); return; }
        const step = 360 / n;
        let out = '';

        for (let i = 0; i < n; i++) {
            const it = items[i];
            const th = -90 + i * step;
            const t = th * Math.PI / 180;
            const lx = (RAD.lift * Math.cos(t)).toFixed(1);
            const ly = (RAD.lift * Math.sin(t)).toFixed(1);
            const face = polar(RAD.rMid, th);
            const iconY = face.y - 11;
            const labelY = face.y + 20;

            const cls = ['rad-slab'];
            if (it.disabled) cls.push('disabled');
            if (it.dropped) cls.push('dropped');
            if (latchedIds.has(it.id)) cls.push('latched');
            if (i === current) cls.push('on');

            out += '<g class="' + cls.join(' ') + '" style="--lx:' + lx + 'px;--ly:' + ly + 'px">'
                + '<path class="rad-shape" d="' + slabPath(i, n, RAD.rIn, RAD.rOut) + '"></path>'
                + iconAt(it.icon, face.x, iconY)
                + '<text class="rad-label" x="' + face.x.toFixed(1) + '" y="'
                + labelY.toFixed(1) + '" style="font-size:' + LABEL_PX + 'px">'
                + esc(it.label) + '</text>'
                + '</g>';
        }
        svg.innerHTML = out;
    }

    /** WHIP's radRefill: empty without a transition, then rise. Called only when
     *  the AIMED SLICE CHANGES — moving inside the same slice must not restart it. */
    function refill() {
        fill.style.transition = 'none';
        fill.classList.remove('full');
        void fill.offsetHeight;
        fill.style.transition = '';
        fill.classList.add('full');
    }

    function syncSelection() {
        const it = items[current];
        const slabs = svg.querySelectorAll('.rad-slab');
        slabs.forEach((el, i) => {
            el.classList.toggle('on', i === current);
            el.classList.toggle('latched', !!items[i] && latchedIds.has(items[i].id));
        });

        const aiming = !!it;
        const empty = !it || it.disabled === true;
        radial.classList.toggle('chosen', aiming);
        radial.classList.toggle('aim-empty', empty);

        if (aiming) {
            beam.setAttribute('d', slabPath(current, items.length, RAD.beamIn, RAD.rIn - 3));
            pillDesc.textContent = it.state || '';
            hero.innerHTML = empty ? '' : iconSvg(it.icon, 60);
            if (empty) {
                fill.classList.remove('full');
                filledIndex = -1;
            } else if (current !== filledIndex) {
                refill();
                filledIndex = current;
            }
        } else {
            beam.setAttribute('d', '');
            pillDesc.textContent = '';
            hero.innerHTML = '';
            fill.classList.remove('full');
            filledIndex = -1;
        }
    }

    function setCurrent(idx) {
        if (idx === current) return; // the WHIP guard: no refill on the same slice
        current = idx;
        syncSelection();
    }

    function choose(idx) {
        const it = items[idx];
        if (!it || it.disabled) return;

        if (it.id === '__restore__') {
            latchedIds.clear();
        } else {
            // Selected again: the persistent highlight ends here, whether or not
            // the server can put the garment back on.
            latchedIds.delete(it.id);
        }
        pendingSelect = it.id;
        post('select', { id: it.id });
        syncSelection();
    }

    function applyStrings(strings) {
        if (!strings || typeof strings !== 'object') return;
        if (strings.title) document.title = strings.title;
        if (strings.lang) document.documentElement.lang = strings.lang;
        if (strings.back && pillName) pillName.textContent = strings.back;
    }

    function adoptState(newItems, strings) {
        applyStrings(strings);

        const previous = {};
        for (const it of items) previous[it.id] = it;
        items = Array.isArray(newItems) ? newItems : [];

        if (pendingSelect) {
            const before = previous[pendingSelect];
            const after = items.find((x) => x.id === pendingSelect);
            if (before && after) {
                // Appena tolto: resta acceso finché non lo si riseleziona.
                if (before.worn === true && after.worn === false) latchedIds.add(pendingSelect);
                if (after.worn === true) latchedIds.delete(pendingSelect);
            }
            pendingSelect = null;
        }

        // Uno slot puo' essere andato a terra o essere stato rimesso da un'altra
        // azione (per esempio il prompt sul prop): in entrambi i casi il riflesso
        // persistente non ha piu' senso.
        for (const id of Array.from(latchedIds)) {
            const latched = items.find((x) => x.id === id);
            if (!latched || latched.worn === true || latched.dropped === true) {
                latchedIds.delete(id);
            }
        }
        if (current >= items.length) current = -1;

        render();
        syncSelection(); // no refill here: the aim did not move
    }

    function scale() {
        return parseFloat(getComputedStyle(root).getPropertyValue('--cw-scale')) || 1;
    }

    function updateScale() {
        const s = Math.min(window.innerHeight / 1440, window.innerWidth / 2560) || 1;
        root.style.setProperty('--cw-scale', String(s * RAD.big));
    }

    // Same angle-to-slice test as ui.js.
    function indexAt(deg, n) {
        const step = 360 / n;
        const rel = (((deg + 90 + step / 2) % 360) + 360) % 360;
        return Math.floor(rel / step) % n;
    }

    function onMove(e) {
        if (!visible || !items.length) return;
        const dx = e.clientX - window.innerWidth / 2;
        const dy = e.clientY - window.innerHeight / 2;
        if (Math.hypot(dx, dy) < RAD.dead * scale()) {
            setCurrent(-1);
            return;
        }
        setCurrent(indexAt(Math.atan2(dy, dx) * 180 / Math.PI, items.length));
    }

    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.action === 'open') {
            if (hideTimer) { clearTimeout(hideTimer); hideTimer = null; }
            updateScale();
            items = Array.isArray(d.items) ? d.items : [];
            latchedIds.clear();
            pendingSelect = null;
            current = -1;
            filledIndex = -1;
            visible = true;
            root.classList.remove('hidden');
            void root.offsetWidth;
            root.classList.add('visible');
            applyStrings(d.strings);
            render();
            syncSelection();
        } else if (d.action === 'update') {
            adoptState(d.items, d.strings);
        } else if (d.action === 'close') {
            visible = false;
            root.classList.remove('visible');
            if (hideTimer) clearTimeout(hideTimer);
            hideTimer = setTimeout(() => {
                root.classList.add('hidden');
                hideTimer = null;
            }, RADIAL_FADE_MS + 40);
        }
    });

    mouseHint.innerHTML = RAD_MOUSE;
    updateScale();
    window.addEventListener('resize', updateScale);
    window.addEventListener('mousemove', onMove);

    root.addEventListener('click', (e) => {
        if (!visible || (e.target && e.target.closest && e.target.closest('#back'))) return;
        if (current >= 0) choose(current);
    });

    root.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        if (visible) post('back');
    });

    backBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        post('back');
    });

    let escDown = false;
    function onEscape(e) {
        if (e.key !== 'Escape' || !visible) return;
        if (e.type === 'keydown') {
            if (escDown || e.repeat) return;
            escDown = true;
            post('back');
        } else {
            escDown = false;
        }
    }
    window.addEventListener('keydown', onEscape);
    window.addEventListener('keyup', onEscape);
})();
