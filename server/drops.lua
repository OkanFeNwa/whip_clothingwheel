-- Capi caduti a terra. Ogni drop e' un prop nel mondo con un solo prompt "Indossa":
-- nessun ground item WHIP, nessuna raccolta come item, nessun inventario.
-- Il tracciamento vive nei metadata del personaggio, quindi sopravvive a un restart.

Drops = {}

local tracked = {}

local function notify(source, text, kind)
    if Config.Notify then Whip.core:NotifyPlayer(source, text, kind or 'info') end
end

local function readMeta(source)
    local value = Whip.core:GetPlayerMetadata(source, Config.DropsKey)
    return (type(value) == 'table') and value or {}
end

local function saveMeta(source, value)
    Whip.core:SetPlayerMetadata(source, Config.DropsKey, next(value) and value or nil)
end

function Drops.load(source)
    tracked[source] = readMeta(source)
    for id, d in pairs(tracked[source]) do
        local s = ClothingWheel.get(id)
        if s and type(d) == 'table' and tonumber(d.x) then
            -- I drop vecchi non hanno `model`: lo ricaviamo dal drawable salvato,
            -- così la mappa configurata vale anche dopo un aggiornamento.
            -- texture e ped servono a scegliere la variante generata corretta.
            local model = d.model
            -- I drop salvati prima del registro generato hanno il prop generico:
            -- in quel caso ricalcoliamo il modello, così il nuovo mapping vale
            -- anche sui capi già a terra.
            if not model or model == s.model then
                model = ClothingWheel.dropModel(s, {
                    drawable = d.drawable, texture = d.texture, ped = d.ped,
                })
            end
            TriggerClientEvent('whip_clothingwheel:drop:spawn', source, id, model,
                vector3(d.x, d.y, d.z), d, s.model)
        end
    end
end

function Drops.forget(source)
    tracked[source] = nil
end

function Drops.Has(source, id)
    local t = tracked[source]
    return t and t[id] or nil
end

--- Rimuove il drop dai metadata e dice al client di eliminare prop e prompt.
function Drops.Clear(source, id)
    local t = tracked[source]
    if not t or not t[id] then return end

    t[id] = nil
    TriggerClientEvent('whip_clothingwheel:drop:remove', source, id)
    saveMeta(source, t)
end

function Drops.ClearAll(source)
    local t = tracked[source]
    if not t then return end

    TriggerClientEvent('whip_clothingwheel:drop:removeAll', source)
    saveMeta(source, {})
    tracked[source] = {}
end

local function coordsOf(value)
    if type(value) == 'vector3' or type(value) == 'vector4' then
        return value.x, value.y, value.z, value.w
    end
    if type(value) == 'table' and tonumber(value.x) and tonumber(value.y) and tonumber(value.z) then
        return value.x, value.y, value.z, value.heading or value.w
    end
    return nil
end

--- Perde un capo: crea il prop con il modello GIUSTO per quel capo e lo toglie dal ped.
---@param source number
---@param id string
---@param coords vector3|vector4|table|nil  dove lasciarlo; nil = dove sta il giocatore
---@return boolean ok
---@return string|nil why
function Drops.Lose(source, id, coords)
    local s = ClothingWheel.get(id)
    if not s then return false, ClothingWheel.locale('error.unknownSlot') end

    local look = Whip.core:GetPlayerMetadata(source, 'appearance')
    if type(look) ~= 'table' or not look.model then
        return false, ClothingWheel.locale('error.notLoaded')
    end

    local entry = ClothingWheel.entry(look, s)
    local name = ClothingWheel.label(s)
    if ClothingWheel.isOff(s, entry) then
        return false, ClothingWheel.locale('error.notWearing', name:lower())
    end

    if Drops.Has(source, id) then
        return false, ClothingWheel.locale('error.alreadyGround', name)
    end

    local base, baseWhy = Appearance.baseline(source)
    if not base then return false, baseWhy end

    local x, y, z, heading = coordsOf(coords or Whip.core:GetPlayerCoords(source))
    if not x then return false, ClothingWheel.locale('error.noPosition') end

    -- Il modello del prop a terra NON si puo' leggere dal ped con una native:
    -- lo risolviamo dal drawable indossato tramite Config.DropModels, con fallback
    -- al modello generico dello slot. Viene salvato perche' sopravviva al restart.
    local model = ClothingWheel.dropModel(s, entry)

    tracked[source] = tracked[source] or readMeta(source)
    tracked[source][id] = {
        x = x, y = y, z = z,
        heading = tonumber(heading) or 0.0,
        drawable = entry.drawable,
        texture = entry.texture,
        ped = look.model,
        model = model,
    }
    saveMeta(source, tracked[source])

    local newLook = ClothingWheel.copy(look)
    ClothingWheel.set(newLook, s, { drawable = s.off, texture = 0 })
    local ok, err = Whip.core:SetPlayerAppearance(source, newLook, { only = { 'apparel', 'props' } })
    if not ok then
        tracked[source][id] = nil
        saveMeta(source, tracked[source])
        return false, err
    end

    -- Il capo e' caduto: teniamone comunque una copia nel prestito, così se il
    -- drop viene perso (restart, cleanup) la ruota può ancora rimetterlo addosso.
    Appearance.stashEntry(source, id, entry)

    TriggerClientEvent('whip_clothingwheel:drop:spawn', source, id, model,
        vector3(x, y, z), tracked[source][id], s.model)

    Appearance.push(source)
    notify(source, ClothingWheel.locale('notify.dropped', name), 'warning')
    return true
end

--- Indossa un capo caduto. Il giocatore NON lo mette in inventario:
--- il server riapplica direttamente il capo e rimuove prop + prompt.
function Drops.Wear(source, id)
    local s = ClothingWheel.get(id)
    if not s then return false, ClothingWheel.locale('error.unknownSlot') end

    local d = Drops.Has(source, id)
    local name = ClothingWheel.label(s)
    if not d then return false, ClothingWheel.locale('error.notOnGround', name) end

    local here = Whip.core:GetPlayerCoords(source)
    if here then
        local dx, dy = here.x - d.x, here.y - d.y
        if (dx * dx + dy * dy) > (Config.WearReach or 5.0) ^ 2 then
            return false, ClothingWheel.locale('error.tooFar', name:lower())
        end
    end

    local ok, why = Appearance.wear(source, id, d, true)
    if not ok then return false, why end

    -- Non usare Drops.Clear qui: manderebbe drop:remove subito e il prop
    -- sparirebbe prima che la mano si chiuda. Puliamo i metadata e lasciamo che
    -- sia il client a rimuovere il prop al momento giusto, dentro l'animazione.
    local t = tracked[source]
    if t then
        t[id] = nil
        saveMeta(source, t)
    end
    -- Appearance.wear ha già fatto un push mentre il drop era ancora tracciato:
    -- aggiorniamo lo stato ora che non lo è, così la slice non resta "a terra".
    Appearance.push(source)
    TriggerClientEvent('whip_clothingwheel:pickup', source, vector3(d.x, d.y, d.z), id)

    -- Il grab finisce con la mano chiusa; solo dopo parte il gesto specifico del
    -- capo che viene indossato, così non si sovrappongono due animazioni.
    if Config.Animate then
        local pickup = Config.PickupAnim or {}
        local delay = (tonumber(pickup.removeAt) or 1000) + (tonumber(pickup.wearAfterGrab) or 150)
        SetTimeout(delay, function()
            TriggerClientEvent('whip_clothingwheel:anim', source, 'wear', id)
        end)
    end

    notify(source, ClothingWheel.locale('notify.wornGround', name), 'success')
    return true
end
