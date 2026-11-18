-- Stato dell'aspetto: baseline, toggle, restore e push verso il client.
-- Tutta la logica e' server-side: il client riceve solo i valori da applicare ai natives.

Appearance = {}

local ONLY = { 'apparel', 'props' }

local function notify(source, key, ...)
    if Config.Notify then Whip.core:NotifyPlayer(source, ClothingWheel.locale(key, ...), 'info') end
end

local function notifyKind(source, kind, key, ...)
    if Config.Notify then Whip.core:NotifyPlayer(source, ClothingWheel.locale(key, ...), kind) end
end

local function fail(key, ...)
    return false, ClothingWheel.locale(key, ...)
end

local function hasDrop(source, id)
    return (Drops ~= nil) and Drops.Has(source, id) or nil
end

local function lookOf(source)
    local look = Whip.core:GetPlayerMetadata(source, 'appearance')
    if type(look) == 'table' and look.model then return look end
    return nil
end

local function lower(text)
    return tostring(text):lower()
end

--- Copia dell'aspetto originario: creata al primo utilizzo, se non esiste gia'.
function Appearance.baseline(source)
    local saved = Whip.core:GetPlayerMetadata(source, Config.BaselineKey)
    if type(saved) == 'table' and saved.model then return saved end

    local look = lookOf(source)
    if not look then return nil, ClothingWheel.locale('error.notLoaded') end

    local base = ClothingWheel.copy(look)
    local ok, why = Whip.core:SetPlayerMetadata(source, Config.BaselineKey, base)
    if not ok then print(('[whip_clothingwheel] baseline non salvata: %s'):format(tostring(why))) end
    return base
end

--- Stato per la ruota + elenco completo dei valori da applicare sul ped.
function Appearance.snapshot(source)
    local look = lookOf(source)
    if not look then return nil, nil end

    -- Sola lettura: non creare la baseline qui, cosi' push/load non hanno effetti collaterali.
    local base = Whip.core:GetPlayerMetadata(source, Config.BaselineKey)
    if type(base) ~= 'table' or not base.model then base = look end

    local slots, drops = {}, {}
    local changed = false

    for _, s in ipairs(ClothingWheel.slots) do
        local entry = ClothingWheel.entry(look, s)
        local born  = ClothingWheel.entry(base, s)
        local drop  = hasDrop(source, s.id)

        slots[s.id] = {
            worn      = not ClothingWheel.isOff(s, entry),
            available = not ClothingWheel.isOff(s, born),
            dropped   = drop and true or false,
            drawable  = entry.drawable,
            texture   = entry.texture,
        }
        if drop then drops[s.id] = true end
        if not ClothingWheel.same(entry, born) then changed = true end
    end

    -- Confronta TUTTI i capi, compresi maniche e pantaloni che non sono nella
    -- ruota: altrimenti "Ripristina" resterebbe disabilitato con capi cambiati.
    if not ClothingWheel.sameClothes(look, base) then changed = true end

    -- Applica l'intero gruppo apparel/props, non solo gli slot visibili.
    local apply = ClothingWheel.clothesOf(look)

    return { slots = slots, drops = drops, canRestore = changed or next(drops) ~= nil }, apply
end

function Appearance.push(source)
    local state, apply = Appearance.snapshot(source)
    if state then TriggerClientEvent('whip_clothingwheel:state', source, state, apply) end
end

local function commit(source, newLook)
    local ok, why = Whip.core:SetPlayerAppearance(source, newLook, { only = ONLY })
    if not ok then return false, why end
    Appearance.push(source)
    return true
end

--- Metti/togli un solo capo. Il "rimetti" usa sempre il valore originario.
function Appearance.toggle(source, id)
    local s = ClothingWheel.get(id)
    if not s then return fail('error.unknownSlot') end

    local look = lookOf(source)
    if not look then return fail('error.notLoaded') end

    local base, why = Appearance.baseline(source)
    if not base then return false, why end

    local name = ClothingWheel.label(s)

    if hasDrop(source, id) then
        return fail('error.onGround', lower(name))
    end

    local entry = ClothingWheel.entry(look, s)
    local born  = ClothingWheel.entry(base, s)
    local nextEntry

    if ClothingWheel.isOff(s, entry) then
        if ClothingWheel.isOff(s, born) then
            return fail('error.noOriginal', lower(name))
        end
        nextEntry = born
    else
        nextEntry = { drawable = s.off, texture = 0 }
    end

    local newLook = ClothingWheel.copy(look)
    ClothingWheel.set(newLook, s, nextEntry)

    local ok, err = commit(source, newLook)
    if not ok then return false, err end

    if ClothingWheel.isOff(s, nextEntry) then
        notifyKind(source, 'info', 'notify.takenOff', name)
        if Config.Animate then TriggerClientEvent('whip_clothingwheel:anim', source, 'takeoff', s.id) end
    else
        notifyKind(source, 'success', 'notify.putOn', name)
        if Config.Animate then TriggerClientEvent('whip_clothingwheel:anim', source, 'wear', s.id) end
    end
    return true
end

--- Rimette un capo caduto a terra. Nessun passaggio dall'inventario.
function Appearance.wear(source, id, itemEntry, fromGround)
    local s = ClothingWheel.get(id)
    if not s then return fail('error.unknownSlot') end

    local look = lookOf(source)
    if not look then return fail('error.notLoaded') end

    local base, why = Appearance.baseline(source)
    if not base then return false, why end

    if not fromGround and hasDrop(source, id) then
        return fail('error.onGround', lower(ClothingWheel.label(s)))
    end
    -- Il drop non va pulito qui: Drops.Wear lo rimuove DOPO il grab, così il
    -- prop resta visibile finché la mano non si chiude. Il controllo qui sopra
    -- vieta solo di "rimettere" a distanza quando il capo è ancora a terra.

    local entry = ClothingWheel.validEntry(s, itemEntry) or ClothingWheel.entry(base, s)
    if ClothingWheel.isOff(s, entry) then
        return fail('error.invalidData', ClothingWheel.label(s))
    end

    local newLook = ClothingWheel.copy(look)
    ClothingWheel.set(newLook, s, entry)

    local ok, err = commit(source, newLook)
    if not ok then return false, err end

    return true
end

--- Torna all'aspetto originario su TUTTI i capi (anche maniche/pantaloni) e
--- pulisce i drop tracciati. Non ricostruisce lo slot per slot: passa l'intera
--- baseline a whip_core, che e' l'unico modo per non perdere capi non visibili.
function Appearance.restore(source)
    local look = lookOf(source)
    if not look then return fail('error.notLoaded') end

    local base, why = Appearance.baseline(source)
    if not base then return false, why end

    local ok, err = Whip.core:SetPlayerAppearance(source, base, { only = ONLY })
    if not ok then return false, err end

    if Config.ClearDropsOnRestore and Drops then Drops.ClearAll(source) end
    Whip.core:SetPlayerMetadata(source, Config.BaselineKey, nil)

    Appearance.push(source)
    notifyKind(source, 'success', 'notify.restored')
    if Config.Animate then TriggerClientEvent('whip_clothingwheel:anim', source, 'restore') end
    return true
end
