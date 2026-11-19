-- Mappe e helper condivisi per gli slot d'abbigliamento.
-- La shape di `look` e' quella di whip_core: components/props con chiavi STRINGA e valori
-- { drawable = number, texture = number }. I props con drawable = -1 sono "togli".

ClothingWheel = ClothingWheel or {}

-- ============================================
-- Lingue
-- ============================================
-- Config.Locale sceglie il blocco in Config.Locales. L'italiano usa le label
-- scritte dall'utente in Config.Slots[].label, così una traduzione non cancella
-- mai una personalizzazione. Le altre lingue hanno un blocco `slots` completo.

local function localeTable(lang)
    if type(Config.Locales) ~= 'table' then return nil end
    local key = tostring(lang or Config.Locale or 'en'):lower()
    return Config.Locales[key]
end

local function localePath(tbl, key)
    if type(tbl) ~= 'table' then return nil end
    for part in tostring(key):gmatch('[^%.]+') do
        tbl = tbl[part]
        if type(tbl) ~= 'table' and type(tbl) ~= 'string' then return nil end
    end
    return tbl
end

--- Testo localizzato. `key` usa la notazione con punti, per esempio 'notify.putOn'.
--- I segnaposto sono quelli di string.format (%s, %d, ...).
function ClothingWheel.locale(key, ...)
    local current = localeTable(Config.Locale)
    local value = localePath(current, key)
    if value == nil then
        local fallback = localeTable('en') or localeTable('it')
        value = localePath(fallback, key)
    end
    if type(value) ~= 'string' then return tostring(key) end
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, value, ...)
        if ok then return formatted end
    end
    return value
end

--- Nome di uno slot: dalle traduzioni, oppure la label del config (italiano).
function ClothingWheel.label(s)
    if type(s) ~= 'table' then return '' end
    local lang = localeTable(Config.Locale)
    if type(lang) == 'table' and type(lang.slots) == 'table' then
        local translated = lang.slots[s.id]
        if type(translated) == 'string' and translated ~= '' then return translated end
    end
    return tostring(s.label or s.id)
end

-- ============================================
-- Slot visibili nella ruota
-- ============================================

ClothingWheel.slots = Config.Slots
ClothingWheel.byId = {}
ClothingWheel.ids = {}

local function deep(v)
    if type(v) ~= 'table' then return v end
    local out = {}
    for k, val in pairs(v) do out[k] = deep(val) end
    return out
end

ClothingWheel.copy = deep

for _, s in ipairs(ClothingWheel.slots) do
    ClothingWheel.byId[s.id] = s
    ClothingWheel.ids[#ClothingWheel.ids + 1] = s.id
end

function ClothingWheel.get(id)
    return ClothingWheel.byId[id]
end

--- Voce corrente di uno slot in un look.
--- `ped` è il modello del personaggio (appearance.model): serve a scegliere la
--- variante maschile/femminile dei modelli generati.
---@return table { drawable = number, texture = number, ped = string|nil }
function ClothingWheel.entry(look, s)
    if type(look) ~= 'table' then return { drawable = s.off, texture = 0, ped = nil } end
    local bag = (s.kind == 'prop') and look.props or look.components
    local raw = (type(bag) == 'table') and bag[tostring(s.slot)] or nil
    if type(raw) ~= 'table' then return { drawable = s.off, texture = 0, ped = look.model } end
    return {
        drawable = tonumber(raw.drawable) or s.off,
        texture  = tonumber(raw.texture) or 0,
        ped      = look.model,
    }
end

function ClothingWheel.isOff(s, e)
    if type(e) ~= 'table' or type(e.drawable) ~= 'number' then return true end
    return e.drawable < 0 or e.drawable == s.off
end

--- Scrive una voce in un look (crea le tabelle mancanti).
function ClothingWheel.set(look, s, e)
    look.components = type(look.components) == 'table' and look.components or {}
    look.props = type(look.props) == 'table' and look.props or {}
    local bag = (s.kind == 'prop') and look.props or look.components
    bag[tostring(s.slot)] = { drawable = e.drawable, texture = e.texture }
end

function ClothingWheel.same(a, b)
    a, b = a or {}, b or {}
    return a.drawable == b.drawable and a.texture == b.texture
end

-- ============================================
-- Tutti i capi del look (anche quelli nascosti dalla ruota)
-- ============================================
-- Whipt_core gestisce apparel/props anche per maniche (3) e pantaloni (4), che
-- in config.lua sono commentati. Ripristinare solo gli slot visibili lasciava
-- quei capi come stavano: per questo qui leggiamo l'intero gruppo.

local COMPONENT_SLOTS = {
    [1] = true, [3] = true, [4] = true, [5] = true, [6] = true,
    [7] = true, [8] = true, [9] = true, [10] = true, [11] = true,
}
local PROP_SLOTS = { [0] = true, [1] = true, [2] = true, [6] = true, [7] = true }

local function addBag(out, bag, kind)
    if type(bag) ~= 'table' then return end
    local keys = {}
    for k in pairs(bag) do
        local n = tonumber(k)
        local known = (kind == 'prop' and PROP_SLOTS[n]) or (kind == 'component' and COMPONENT_SLOTS[n])
        if n and known and n == math.floor(n) then keys[#keys + 1] = n end
    end
    table.sort(keys)
    for _, n in ipairs(keys) do
        local raw = bag[tostring(n)]
        if type(raw) == 'table' then
            local off = (kind == 'prop') and -1 or 0
            out[#out + 1] = {
                kind = kind, slot = n,
                drawable = tonumber(raw.drawable) or off,
                texture = tonumber(raw.texture) or 0,
            }
        end
    end
end

--- Elenco completo dei capi indossati, nell'ordine usato da WHIP.
---@return table[] list
function ClothingWheel.clothesOf(look)
    local out = {}
    if type(look) ~= 'table' then return out end
    addBag(out, look.components, 'component')
    addBag(out, look.props, 'prop')
    return out
end

local function numSame(a, b)
    a, b = tonumber(a), tonumber(b)
    if not a or not b then return a == b end
    return math.abs(a - b) < 0.001
end

--- Confronta TUTTI i capi di due look, non solo gli slot visibili.
function ClothingWheel.sameClothes(a, b)
    local A, B = ClothingWheel.clothesOf(a), ClothingWheel.clothesOf(b)
    if #A ~= #B then return false end

    local byKey = {}
    for _, e in ipairs(B) do byKey[e.kind .. ':' .. e.slot] = e end

    for _, e in ipairs(A) do
        local other = byKey[e.kind .. ':' .. e.slot]
        if not other
            or not numSame(e.drawable, other.drawable)
            or not numSame(e.texture, other.texture) then
            return false
        end
    end
    return true
end

-- ============================================
-- Modello del capo a terra
-- ============================================

--- Normalizza il nome di collection restituito dalle native in un token stabile,
--- identico a quello usato dall'exporter offline per i nomi dei .ydr.
--- La collection base dei freemode resta `np` per compatibilità col registro vecchio.
function ClothingWheel.collectionToken(name)
    local value = tostring(name or ''):lower()
    if value == '' or value:find('freemode_01', 1, true) then return 'np' end
    value = value:gsub('^mp_[mf]_', '')
    value = value:gsub('^freemode_01_p_?', '')
    value = value:gsub('^mp_[mf]_', '')
    value = value:gsub('^p_', '')
    value = value:gsub('[^a-z0-9]', '')
    return value ~= '' and value or 'np'
end

--- Identità stabile di un capo indossato: collection + indice LOCALE.
--- Il drawable dei metadata è un numero GLOBALE che si sposta quando un pack
--- aggiunge capi; la coppia restituita qui identifica il modello vero.
function ClothingWheel.identityOf(e)
    if type(e) ~= 'table' then return nil, nil end
    local collection = ClothingWheel.collectionToken(e.collection)
    local index = tonumber(e.localIndex)
    if not index or index < 0 or index ~= math.floor(index) then return nil, nil end
    return collection, math.floor(index)
end

--- Modello del prop che rappresenta il capo a terra.
--- Non esiste una native che restituisca il modello world di un drawable indossato
--- (GET_PED_PROP_MODEL non esiste). Il client risolve l'identità con
--- GetPedCollectionNameFromProp + GetPedCollectionLocalIndexFromProp.
--- Ordine di risoluzione:
---   1. Config.DropModels[slot][drawable]          - override esplicito dell'admin
---   2. data/drop_models.json[slot].byIdentity     - collection + indice locale
---   3. data/drop_models.json[slot][drawable]      - registro legacy (solo `np`)
---   4. s.model                                    - prop generico dello slot
---@return string model
function ClothingWheel.dropModel(s, entry)
    entry = type(entry) == 'table' and entry or {}
    local drawable = tonumber(entry.drawable)
    if not drawable or drawable < 0 then return s.model end
    local key = math.floor(drawable)
    local texture = tonumber(entry.texture) or 0

    local map = (type(Config.DropModels) == 'table') and Config.DropModels[s.id] or nil
    if type(map) == 'table' then
        local model = map[tostring(key)] or map[key]
        if type(model) == 'string' and model ~= '' then return model end
    end

    -- Il registro generato è caricato solo lato server (server/generated_models.lua).
    if type(GeneratedDropModels) == 'table' then
        local collection, index = ClothingWheel.identityOf(entry)
        if collection then
            -- L'identità è autorevole: il drawable globale dei metadata si sposta
            -- con i pack addon, quindi NON possiamo usare il ramo legacy quando
            -- conosciamo collection + indice locale. Un miss qui significa solo
            -- che non abbiamo esportato quel capo: meglio il modello generico.
            if type(GeneratedDropModels.resolveIdentity) == 'function' then
                local generated = GeneratedDropModels.resolveIdentity(
                    s.id, collection, index, texture, entry.ped)
                if type(generated) == 'string' and generated ~= '' then return generated end
            end
        elseif type(GeneratedDropModels.get) == 'function' then
            -- Nessuna identità (save vecchio o client che non ha risposto):
            -- qui il drawable globale è l'unica chiave disponibile.
            local generated = GeneratedDropModels.get(s.id, key, texture, entry.ped)
            if type(generated) == 'string' and generated ~= '' then return generated end
        end
    end

    return s.model
end

--- Indica se il modello risolto è quello generato (utile per /cwmodel e i log).
---@return boolean
function ClothingWheel.hasGeneratedModel(s, entry)
    if type(GeneratedDropModels) ~= 'table' then return false end
    entry = type(entry) == 'table' and entry or {}
    local drawable = tonumber(entry.drawable)
    if not drawable or drawable < 0 then return false end
    local collection, index = ClothingWheel.identityOf(entry)
    if collection then
        return type(GeneratedDropModels.resolveIdentity) == 'function'
            and GeneratedDropModels.resolveIdentity(s.id, collection, index,
                tonumber(entry.texture) or 0, entry.ped) ~= nil
    end
    return type(GeneratedDropModels.get) == 'function'
        and GeneratedDropModels.get(s.id, math.floor(drawable),
            tonumber(entry.texture) or 0, entry.ped) ~= nil
end

--- Dati validi per poter indossare un capo caduto a terra.
--- L'identità viaggia con la voce: serve al prossimo drop per ritrovare lo
--- stesso modello anche se il numero globale è cambiato nel frattempo.
function ClothingWheel.validEntry(s, e)
    if type(e) ~= 'table' then return nil end
    local d, t = tonumber(e.drawable), tonumber(e.texture)
    if not d or not t then return nil end
    if s.kind == 'prop' then
        if d < -1 then return nil end
    elseif d < 0 then
        return nil
    end
    local out = { drawable = math.floor(d), texture = math.floor(t) }
    local collection, index = ClothingWheel.identityOf(e)
    if collection and s.kind == 'prop' then
        out.collection = collection
        out.localIndex = index
    end
    return out
end
