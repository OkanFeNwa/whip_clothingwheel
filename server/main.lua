-- Registrazioni WHIP, eventi protetti, export e comando di sviluppo.
-- Nessun item: i capi a terra sono prop del mondo con un solo prompt "Indossa".

local function notify(source, text, kind)
    if Config.Notify then Whip.core:NotifyPlayer(source, text, kind or 'info') end
end

local slotParam = { { 'slot', 'enum', ClothingWheel.ids } }

Whip.register(function()
    Whip.core:SecureCallback('whip_clothingwheel:state', {
        rateLimit = Config.RateLimit,
    }, function(source)
        local state, apply = Appearance.snapshot(source)
        if not state then return false, ClothingWheel.locale('error.notLoaded') end
        return state, apply
    end)

    Whip.core:SecureEvent('whip_clothingwheel:toggle', {
        rateLimit = Config.RateLimit,
        params = slotParam,
    }, function(source, player, slotId)
        return Appearance.toggle(source, slotId)
    end)

    Whip.core:SecureEvent('whip_clothingwheel:restore', {
        rateLimit = 1000,
    }, function(source)
        return Appearance.restore(source)
    end)

    -- Di solito chiamato da un altro script: crea il prop a terra, non tocca la ruota.
    Whip.core:SecureEvent('whip_clothingwheel:lose', {
        rateLimit = Config.RateLimit,
        params = slotParam,
    }, function(source, player, slotId)
        return Drops.Lose(source, slotId)
    end)

    -- Richiesto dal client all'avvio: dopo un `restart` della risorsa i prop sono
    -- stati cancellati, così li ricreiamo dai metadata senza bisogno di rilogare.
    Whip.core:SecureEvent('whip_clothingwheel:drops:sync', {
        rateLimit = 1000,
    }, function(source)
        TriggerClientEvent('whip_clothingwheel:drop:removeAll', source)
        Drops.load(source)
    end)

    -- Unico modo per recuperare un capo caduto: il prompt "Indossa" sul prop.
    -- Il server valida lo slot e la distanza; non esiste raccolta come item.
    Whip.core:SecureEvent('whip_clothingwheel:wearGround', {
        rateLimit = Config.RateLimit,
        params = slotParam,
    }, function(source, player, slotId)
        return Drops.Wear(source, slotId)
    end)
end)

-- API per altri script server-side.
exports('LoseItem', function(source, slotId, coords)
    return Drops.Lose(source, slotId, coords)
end)

exports('Restore', function(source)
    return Appearance.restore(source)
end)

exports('GetState', function(source)
    return Appearance.snapshot(source)
end)

AddEventHandler('whip_core:player:loaded', function(e)
    Drops.load(e.source)
    Appearance.push(e.source)
end)

AddEventHandler('whip_core:player:logout', function(e)
    if e.source then Drops.forget(e.source) end
end)

-- Comando di sviluppo: /cwlose <slot> (richiede whip.devtools).
RegisterCommand('cwlose', function(source, args)
    if source == 0 then
        print('[whip_clothingwheel] ' .. ClothingWheel.locale('error.devOnly'))
        return
    end
    if not IsPlayerAceAllowed(source, 'whip.devtools') then
        notify(source, ClothingWheel.locale('notify.noPermission'), 'error')
        return
    end

    local id = args[1]
    if not ClothingWheel.get(id) then
        notify(source, ClothingWheel.locale('error.unknownSlotDev'), 'error')
        return
    end

    local ok, why = Drops.Lose(source, id)
    if not ok then notify(source, why, 'error') end
end, false)

-- Scopre i drawable indossati: serve a riempire Config.DropModels per avere il
-- modello del capo a terra identico a quello che il personaggio sta portando.
-- /cwmodel         -> stampa tutti i capi indossati
-- /cwmodel hat     -> stampa solo quello slot
-- /cwmodel reload  -> rilegge data/drop_models.json (modelli generati)
RegisterCommand('cwmodel', function(source, args)
    if source == 0 then
        print('[whip_clothingwheel] ' .. ClothingWheel.locale('error.devOnly'))
        return
    end
    if not IsPlayerAceAllowed(source, 'whip.devtools') then
        notify(source, ClothingWheel.locale('notify.noPermission'), 'error')
        return
    end

    local only = args[1]

    -- /cwmodel reload rilegge data/drop_models.json senza riavviare la resource.
    -- Va prima del controllo di `appearance`: il registro si può ricaricare anche
    -- quando il personaggio non è ancora completamente caricato.
    if only == 'reload' then
        if type(GeneratedDropModels) == 'table' and type(GeneratedDropModels.reload) == 'function' then
            local count = GeneratedDropModels.reload()
            notify(source, ClothingWheel.locale('command.reload', count), 'success')
        else
            notify(source, ClothingWheel.locale('command.reloadFailed'), 'error')
        end
        return
    end

    local look = Whip.core:GetPlayerMetadata(source, 'appearance')
    if type(look) ~= 'table' then
        notify(source, ClothingWheel.locale('error.notLoaded'), 'error')
        return
    end

    if only and not ClothingWheel.get(only) then
        notify(source, ClothingWheel.locale('error.unknownSlot'), 'error')
        return
    end

    local found = 0
    for _, s in ipairs(ClothingWheel.slots) do
        if not only or only == s.id then
            local entry = ClothingWheel.entry(look, s)
            if not ClothingWheel.isOff(s, entry) then
                found = found + 1
                local model = ClothingWheel.dropModel(s, entry)
                local hint = ''
                if model == s.model then
                    hint = ClothingWheel.locale('command.generic')
                elseif ClothingWheel.hasGeneratedModel(s, entry) then
                    hint = ' [generated]'
                end
                local msg = ClothingWheel.locale('command.modelLine',
                    s.id, entry.drawable, entry.texture, model, hint)
                print('[whip_clothingwheel] ' .. msg)
                notify(source, msg, 'info')
            end
        end
    end
    if found == 0 then notify(source, ClothingWheel.locale('error.noItems'), 'info') end
end, false)
