-- Ponte Lua <-> NUI per il sotto-menu "Vestiti".
-- La pagina e' nostra: nessuna azione delle altre risorse WHIP (phone, inventory,
-- emotes, dev tools) puo' comparire qui. Il server resta l'unica fonte di verita'.

ClothingWheelNui = ClothingWheelNui or {}

local isOpen = false

local function uiStrings()
    return {
        title = ClothingWheel.locale('menu.title'),
        back  = ClothingWheel.locale('menu.back'),
        choose = ClothingWheel.locale('menu.choose'),
        lang  = tostring(Config.Locale or 'it'):lower(),
    }
end

--- Costruisce i dati delle slice: Ripristina per prima (in alto), poi i capi.
--- Sulle slice non c'e' scritto "Togli/Metti <capo>": c'e' solo l'icona del capo.
--- `worn` viene usato dalla pagina per tenere "acceso" un capo appena tolto.
local function buildItems(state)
    state = type(state) == 'table' and state or {}
    local slots = (type(state.slots) == 'table') and state.slots or {}
    local items = {}

    items[#items + 1] = {
        id = '__restore__',
        label = ClothingWheel.locale('menu.restore'),
        icon = 'restore',
        state = state.canRestore and ClothingWheel.locale('state.restoreReady')
            or ClothingWheel.locale('state.restoreEmpty'),
        disabled = state.canRestore ~= true,
        dropped = false,
        worn = false,
    }

    for _, s in ipairs(ClothingWheel.slots) do
        local st = slots[s.id] or {}
        local detail, dropped

        if st.dropped then
            detail, dropped = ClothingWheel.locale('state.dropped'), true
        elseif st.worn then
            detail = ClothingWheel.locale('state.worn')
        elseif st.available then
            detail = ClothingWheel.locale('state.off')
        else
            detail = ClothingWheel.locale('state.none')
        end

        items[#items + 1] = {
            id = s.id,
            label = ClothingWheel.label(s),
            icon = s.icon or 'bag',
            state = detail,
            worn = st.worn == true,
            dropped = dropped == true,
            -- Un capo a terra non si rimette da qui: va indossato sul prop.
            disabled = st.dropped == true,
        }
    end

    return items
end

function ClothingWheelNui.open(state)
    isOpen = true
    -- Same neutral start as whip_core's radial: the cursor at the wheel's centre.
    SetCursorLocation(0.5, 0.5)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        items = buildItems(state),
        strings = uiStrings(),
    })
end

function ClothingWheelNui.refresh(state)
    if not isOpen then return end
    SendNUIMessage({
        action = 'update',
        items = buildItems(state),
        strings = uiStrings(),
    })
end

function ClothingWheelNui.close()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

--- Indietro: torna alla ruota rapida WHIP invece di chiudere tutto.
--- Il comando `whip_radial` è registrato da whip_core/client/radial.lua e fa
--- da toggle; la nostra pagina non è un focus WHIP, quindi prima rilasciamo
--- il NUI e aspettiamo un tick prima di aprire la ruota.
function ClothingWheelNui.back()
    ClothingWheelNui.close()
    CreateThread(function()
        Wait(150)
        -- whip_radial toggles; only fire it when WHIP's wheel really is closed.
        if not Whip.core:IsRadialOpen() then
            ExecuteCommand('whip_radial')
        end
    end)
end

function ClothingWheelNui.isOpen()
    return isOpen
end

RegisterNUICallback('select', function(data, cb)
    cb({})
    local id = type(data) == 'table' and data.id or nil
    if type(id) ~= 'string' then return end

    if id == '__restore__' then
        TriggerServerEvent('whip_clothingwheel:restore')
    elseif ClothingWheel.get(id) then
        TriggerServerEvent('whip_clothingwheel:toggle', id)
    end
end)

RegisterNUICallback('back', function(data, cb)
    cb({})
    ClothingWheelNui.back()
end)

RegisterNUICallback('close', function(data, cb)
    cb({})
    ClothingWheelNui.close()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)
