-- Ruota F1: un solo pulsante "Vestiti" apre un overlay NUI che imita la ruota.
-- Il sotto-menu e' isolato: phone/inventory/emotes/devtools delle altre risorse non compaiono.
-- Niente emoji. Il server resta l'unica fonte di verita'.

local State = { slots = {}, drops = {}, canRestore = false }
local dropProps = {} -- [slotId] = { obj = entity, action = actionId }

local function apply(list)
    if type(list) ~= 'table' then return end
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end

    for _, e in ipairs(list) do
        if e and e.kind and e.slot then
            local drawable, texture = tonumber(e.drawable) or -1, tonumber(e.texture) or 0
            if e.kind == 'prop' then
                if drawable < 0 then
                    ClearPedProp(ped, e.slot)
                else
                    SetPedPropIndex(ped, e.slot, drawable, texture, true)
                end
            else
                SetPedComponentVariation(ped, e.slot, drawable, texture, 0)
            end
        end
    end
end

local function refresh()
    local state, list = Whip.core:Callback('whip_clothingwheel:state')
    if type(state) == 'table' then
        State = state
        apply(list)
        ClothingWheelNui.refresh(State)
    end
end

-- Animazioni: il server manda 'takeoff', 'wear' o 'restore' + lo slot, così la
-- clip cambia da capo a capo e tra "mettere" e "togliere".
local FEMALE_MODEL = GetHashKey('mp_f_freemode_01')
local activeReverse = {} -- [slotId] = token, per non sovrapporre due "rimetti"

local function loadDict(dict)
    if not dict then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    return HasAnimDictLoaded(dict)
end

local function stopAnim(ped, dict, name)
    if DoesEntityExist(ped) then StopAnimTask(ped, dict, name, -8.0) end
end

local function playAnim(spec)
    if Config.Animate == false or type(spec) ~= 'table' then return end
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsPedDeadOrDying(ped, true) then return end

    local dict, name = spec.dict, spec.anim
    if not dict or not name or not loadDict(dict) then return end

    -- Stesso schema delle emote WHIP: blend-in 8, blend-out -8, durata naturale.
    -- Nessun loop: a fine clip il ped torna da solo alla posa normale.
    local flag = spec.flag or 0
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, spec.duration or -1, flag,
        0.0, false, false, false)
    SetTimeout((tonumber(spec.stopAt) or 2000) + 300, function()
        if DoesEntityExist(ped) and IsEntityPlayingAnim(ped, dict, name, 3) then
            StopAnimTask(ped, dict, name, -8.0)
        end
    end)
    SetTimeout((tonumber(spec.stopAt) or 2000) + 600, function() RemoveAnimDict(dict) end)
end

-- GTA non ha un flag "reverse" per TASK_PLAY_ANIM e una velocità negativa non è
-- documentata. Per "rimettere" usiamo la stessa clip di "togliere" ma ne
-- scorriamo la fase da 1 a 0 con SET_ENTITY_ANIM_CURRENT_TIME: è deterministico
-- e non dipende da speed negativi non supportati.
local function playReverseAnim(spec, slotId)
    if Config.Animate == false or type(spec) ~= 'table' then return end
    local ped = PlayerPedId()
    if not ped or ped == 0 or IsPedDeadOrDying(ped, true) then return end

    local dict, name = spec.dict, spec.anim
    if not dict or not name or not loadDict(dict) then return end

    local duration = tonumber(GetAnimDuration(dict, name)) or 0
    local total = duration * 1000
    if total < 200 then total = tonumber(spec.stopAt) or 1500 end

    local token = {}
    if slotId then activeReverse[slotId] = token end

    -- L'oggetto indossato non fa parte della clip: la visibilità va gestita qui.
    -- Lo togliamo all'inizio e lo rimettiamo quando la mano torna al viso.
    local savedProp
    local slotCfg = slotId and ClothingWheel.get(slotId) or nil
    local info = slotId and State.slots and State.slots[slotId] or nil
    if slotCfg and slotCfg.kind == 'prop' and info and info.worn then
        local drawable = tonumber(info.drawable) or -1
        if drawable >= 0 then
            savedProp = {
                slot = slotCfg.slot,
                drawable = drawable,
                texture = math.max(tonumber(info.texture) or 0, 0),
            }
            ClearPedProp(ped, savedProp.slot)
        end
    end

    local flag = tonumber(spec.flag) or 0
    -- AF_HOLD_LAST_FRAME (2): senza questo la clip a phase 1.0 finisce subito.
    if (math.floor(flag / 2) % 2) == 0 then flag = flag + 2 end

    TaskPlayAnim(ped, dict, name, 8.0, -8.0, -1, flag, 1.0, false, false, false)
    Wait(30) -- il task deve registrare l'anim prima dello scrub
    SetEntityAnimSpeed(ped, dict, name, 0.0)
    SetEntityAnimCurrentTime(ped, dict, name, 1.0)

    local started = GetGameTimer()
    local revealAt = tonumber(spec.revealAt) or 0.62
    local revealed = false

    while GetGameTimer() - started < total do
        if slotId and activeReverse[slotId] ~= token then break end
        if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then break end

        local t = math.min((GetGameTimer() - started) / total, 1.0)
        SetEntityAnimCurrentTime(ped, dict, name, 1.0 - t)

        if savedProp and not revealed and t >= revealAt then
            SetPedPropIndex(ped, savedProp.slot, savedProp.drawable, savedProp.texture, true)
            revealed = true
        end
        Wait(0)
    end

    if savedProp and not revealed then
        SetPedPropIndex(ped, savedProp.slot, savedProp.drawable, savedProp.texture, true)
    end

    local current = (not slotId) or (activeReverse[slotId] == token)
    if current then
        SetEntityAnimSpeed(ped, dict, name, 0.0)
        stopAnim(ped, dict, name)
        if slotId then activeReverse[slotId] = nil end
    end
end

-- GetPedModel non esiste: il modello dell'entita' si legge con GetEntityModel.
local function isFemale()
    return GetEntityModel(PlayerPedId()) == FEMALE_MODEL
end

local function gendered(cfg)
    if type(cfg) ~= 'table' then return nil end
    if not cfg.male and not cfg.female then return cfg end
    return isFemale() and (cfg.female or cfg.male) or (cfg.male or cfg.female)
end

local function resolveSpec(value)
    if type(value) ~= 'table' then return nil end
    if value.male or value.female then return gendered(value) end
    if value.on or value.off then return nil end
    return value
end

local function animFor(kind, slotId)
    if kind == 'restore' then return gendered(Config.RestoreAnim) end

    local bySlot = (type(Config.WearAnim) == 'table') and Config.WearAnim[slotId] or nil
    if type(bySlot) == 'table' then
        local spec = resolveSpec(kind == 'wear' and bySlot.on or bySlot.off)
        if spec then return spec end
    end

    -- Vecchia configurazione: solo rimozione generica.
    if kind == 'takeoff' then return gendered(Config.TakeoffAnim) end
    return nil
end

RegisterNetEvent('whip_clothingwheel:anim', function(kind, slotId)
    local spec = animFor(kind, slotId)
    if spec and spec.reverse then
        playReverseAnim(spec, slotId)
    else
        playAnim(spec)
    end
end)

-- ============================================
-- Ruota F1: unica voce "Vestiti" -> overlay
-- ============================================

Whip.register(function()
    Whip.core:AddAction({
        id = 'clothing',
        at = { radial = true },
        label = ClothingWheel.locale('menu.label'),
        icon = Config.MenuIcon,
        description = ClothingWheel.locale('menu.description'),
        onSelect = function()
            -- WHIP chiude la ruota quando si seleziona un'azione: aspettiamo che
            -- rilasci il focus NUI prima di prendere il controllo con la nostra pagina.
            CreateThread(function()
                for _ = 1, 12 do
                    Wait(50)
                    if not Whip.core:IsRadialOpen() then break end
                end
                ClothingWheelNui.open(State)
            end)
        end,
    })
end)

-- ============================================
-- Capi caduti a terra: solo "Indossa", mai raccolta come item
-- ============================================

local function removeDrop(id)
    local d = dropProps[id]
    if not d then return end
    if d.action then Whip.core:RemoveAction(d.action) end
    if d.obj and DoesEntityExist(d.obj) then DeleteEntity(d.obj) end
    dropProps[id] = nil
end

-- ============================================
-- Raccolta da terra: il grab vero di WHIP/client/ground.lua
-- ============================================
-- Stessa scelta di clip del core: alto/medio/basso, mano destra o sinistra in
-- base a dove giace il capo, due mani per zaino e giubbotto. Il prop sparisce
-- 1 secondo dopo l'avvio, con la mano già chiusa.

local FEET_BELOW = 1.0
local LOW_BELOW, HIGH_ABOVE = 0.65, 1.6
local GRAB_LEFT = -math.rad(30)
local GRAB_STICK = 0.35

local function grabWantsToMove()
    return math.abs(GetControlNormal(0, 30)) > GRAB_STICK
        or math.abs(GetControlNormal(0, 31)) > GRAB_STICK
        or IsControlPressed(0, 22) or IsControlPressed(0, 24) or IsControlPressed(0, 25)
end

local function grabChoice(id, coords, ped)
    local spec = Config.PickupAnim or {}
    local dict = gendered(spec.dict)
    local bands = type(spec.clip) == 'table' and spec.clip or {}

    local band = 'low'
    if coords then
        local P = GetEntityCoords(ped)
        local up = (tonumber(coords.z) or P.z - FEET_BELOW) - (P.z - FEET_BELOW)
        band = up < LOW_BELOW and 'low' or (up > HIGH_ABOVE and 'high' or 'med')
    end
    local names = type(bands[band]) == 'table' and bands[band] or bands.low or {}

    local hand = 'right'
    local twoHanded = type(spec.twoHanded) == 'table' and spec.twoHanded[id]
    if twoHanded then
        hand = 'twoHands'
    elseif coords then
        local P = GetEntityCoords(ped)
        local r = math.rad(GetEntityHeading(ped))
        local dx, dy = coords.x - P.x, coords.y - P.y
        local lx, ly = dx * math.cos(r) + dy * math.sin(r), -dx * math.sin(r) + dy * math.cos(r)
        if math.atan(lx, ly) < GRAB_LEFT then hand = 'left' end
    end

    return dict, names[hand] or names.right, band
end

local function playGrab(id, coords)
    local spec = Config.PickupAnim or {}
    local function finish() removeDrop(id) end

    if Config.Animate == false then
        finish()
        return
    end

    local ped = PlayerPedId()
    if not ped or ped == 0 or IsEntityDead(ped) or IsPedInAnyVehicle(ped, true)
        or IsPedRagdoll(ped) or IsPedFalling(ped) or IsPedSwimming(ped) then
        finish()
        return
    end

    local dict, clip, band = grabChoice(id, coords, ped)
    if type(dict) ~= 'string' or type(clip) ~= 'string' then
        finish()
        return
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1200
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(0) end
    if not HasAnimDictLoaded(dict) then
        finish()
        return
    end

    -- Il ballo basso piega le ginocchia: full body (flag 0). Gli altri restano
    -- upper body con controllo (48), come nel core.
    local fullBody = band == 'low'
    TaskPlayAnim(ped, dict, clip, 8.0, 4.0, spec.duration or 2000,
        fullBody and 0 or 48, 0.0, false, false, false)

    local closeAt = (type(spec.closeAt) == 'table' and spec.closeAt[clip]) or 0
    local doneAt = (type(spec.doneAt) == 'table' and spec.doneAt[clip]) or (spec.duration or 2000)
    local t0 = GetGameTimer()

    CreateThread(function()
        Wait(0)
        while IsEntityPlayingAnim(ped, dict, clip, 3) and GetGameTimer() - t0 < doneAt do
            if fullBody and GetGameTimer() - t0 >= closeAt and grabWantsToMove() then
                StopAnimTask(ped, dict, clip, 4.0)
                break
            end
            Wait(0)
        end
        if doneAt < (spec.duration or 2000) and IsEntityPlayingAnim(ped, dict, clip, 3) then
            StopAnimTask(ped, dict, clip, 4.0)
        end
        SetTimeout(300, function() RemoveAnimDict(dict) end)
    end)

    -- Esattamente 1 s dopo l'avvio dell'azione, non quando il server riceve E.
    SetTimeout(tonumber(spec.removeAt) or 1000, finish)
end

-- Il server manda le coordinate del drop dopo aver confermato l'Indossa: qui
-- parte l'animazione e il prop locale viene rimosso a mano chiusa.
RegisterNetEvent('whip_clothingwheel:pickup', function(coords, id)
    playGrab(id, coords)
end)

-- I .ydr di model_forge vengono registrati come modelli world dal .ytyp
-- caricato via DLC_ITYP_REQUEST in fxmanifest.lua. IsModelInCdimage puo' dare
-- falsi negativi per i modelli streamati: la prova reale e' RequestModel.
local function spawnDrop(id, model, coords, entry, fallback)
    removeDrop(id)

    local s = ClothingWheel.get(id)
    if not s then return end

    -- I modelli generati da model_forge vivono in stream/. Non usare
    -- IsModelInCdimage: per i modelli streamati da una risorsa puo' dare false
    -- anche quando il file c'e'. La prova reale e' RequestModel + HasModelLoaded.
    local function tryLoad(name, timeoutMs)
        if type(name) ~= 'string' or name == '' then return nil end
        local h = GetHashKey(name)
        RequestModel(h)
        local deadline = GetGameTimer() + (timeoutMs or 3000)
        while not HasModelLoaded(h) and GetGameTimer() < deadline do Wait(0) end
        if HasModelLoaded(h) then return h end
        -- Non chiamare SetModelAsNoLongerNeeded su un modello mai caricato:
        -- puo' lasciare lo streamer in uno stato strano e far fallire il fallback.
        return nil
    end

    local hash = tryLoad(model, 4000)
    local obj

    if hash then
        obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(hash)
        if obj and obj ~= 0 then
            SetEntityHeading(obj, tonumber(coords.heading) or (entry and tonumber(entry.heading)) or 0.0)
            PlaceObjectOnGroundProperly(obj)

            -- Alcuni modelli (gli occhiali) hanno l'origine nel mezzo: senza questo
            -- sollevamento restano mezzi interrati. I valori sono in Config.DropLift.
            local lift = (type(Config.DropLift) == 'table') and tonumber(Config.DropLift[id]) or 0.0
            if lift and lift ~= 0.0 then
                local p = GetEntityCoords(obj)
                SetEntityCoords(obj, p.x, p.y, p.z + lift, false, false, false, true)
            end
        else
            obj = nil
        end
    end

    if not obj and type(fallback) == 'string' and fallback ~= '' then
        -- Ultima ratio: il prop generico dello slot, mai un ped invisibile.
        hash = tryLoad(fallback, 3000)
        if hash then
            obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
            SetModelAsNoLongerNeeded(hash)
            if obj and obj ~= 0 then
                PlaceObjectOnGroundProperly(obj)
                local p = GetEntityCoords(obj)
                SetEntityCoords(obj, p.x, p.y, p.z + 0.1, false, false, false, true)
            else
                obj = nil
            end
        end
    end

    if not obj or obj == 0 then
        print(('[whip_clothingwheel] nessun modello disponibile per %s (richiesto %s)')
            :format(tostring(id), tostring(model)))
        return
    end

    -- Prompt sul prop: unica azione e' "Indossa". Nessun pickup/inventario.
    -- `icon` e' un GLIFO WHIP, non una chiave SVG: s.icon (hat, glasses, ...) verrebbe
    -- disegnato come testo ("cap"). 'pickup' e' la freccia vera dell'atlas del core.
    -- `description` e' ignorata sui prompt world e genererebbe un warning.
    local actionId = Whip.core:AddAction({
        id = 'cw_drop_' .. id,
        at = { entity = obj },
        label = ClothingWheel.locale('prompt.wear', ClothingWheel.label(s)),
        icon = 'pickup',
        onSelect = function()
            TriggerServerEvent('whip_clothingwheel:wearGround', id)
        end,
    })

    dropProps[id] = { obj = obj, action = actionId }
end

RegisterNetEvent('whip_clothingwheel:drop:spawn', function(id, model, coords, entry, fallback)
    spawnDrop(id, model, coords, entry, fallback)
end)

RegisterNetEvent('whip_clothingwheel:drop:remove', function(id)
    removeDrop(id)
end)

RegisterNetEvent('whip_clothingwheel:drop:removeAll', function()
    for id in pairs(dropProps) do removeDrop(id) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(dropProps) do removeDrop(id) end
end)

-- ============================================
-- Stato
-- ============================================

RegisterNetEvent('whip_clothingwheel:state', function(state, list)
    if type(state) == 'table' then
        State = state
        ClothingWheelNui.refresh(State)
    end
    apply(list)
end)

RegisterNetEvent('whip_clothingwheel:apply', function(list)
    apply(list)
end)

AddEventHandler('whip_core:player:loaded', function()
    refresh()
end)

CreateThread(function()
    if Whip.ready(10000) then
        refresh()
        -- Dopo un restart della risorsa i prop a terra sono spariti: chiediamo
        -- al server di ricrearli dai metadata (con il modello risolto aggiornato).
        TriggerServerEvent('whip_clothingwheel:drops:sync')
    end
end)
