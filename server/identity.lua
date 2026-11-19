-- Identità stabile dei prop indossati.
-- Il numero letto dai metadata (GetPedPropIndex) è un drawable GLOBALE: cambia
-- quando un pack addon aggiunge capi. Solo il client può chiedere a game le
-- natives di collection, quindi il server le richiede con un callback e attende
-- la risposta prima di creare il drop. La risposta è validata come parametro
-- SecureCallback e non può essere attribuita a un altro giocatore.

Identity = {}

local pending = {}
local nextId = 0
local TIMEOUT_MS = 1500

Whip.register(function()
    Whip.core:SecureCallback('whip_clothingwheel:identity:report', {
        rateLimit = Config.RateLimit,
        params = {
            { 'requestId', 'key', 48 },
            { 'collection', 'string', 96 },
            { 'localIndex', 'int', -1, 65535 },
        },
    }, function(source, player, requestId, collection, localIndex)
        local rec = pending[requestId]
        if not rec or rec.src ~= source then return false end
        pending[requestId] = nil
        rec.promise:resolve({ collection = collection, localIndex = localIndex })
        return true
    end)
end)

--- Chiede al client la coppia (collection, indice locale) del capo indossato.
--- Ritorna nil se il client non risponde in tempo o il capo non ha identità.
---@param source number
---@param slotId string
---@return table|nil { collection = string, localIndex = integer }
function Identity.of(source, slotId)
    local s = ClothingWheel.get(slotId)
    if not s or s.kind ~= 'prop' then return nil end

    nextId = nextId + 1
    local requestId = ('cw%d'):format(nextId)
    local promise = promise.new()
    pending[requestId] = { src = source, promise = promise }

    TriggerClientEvent('whip_clothingwheel:identity:request', source, requestId, slotId, s.slot)

    SetTimeout(TIMEOUT_MS, function()
        if pending[requestId] then
            pending[requestId] = nil
            promise:resolve(nil)
        end
    end)

    local answer = Citizen.Await(promise)
    if type(answer) ~= 'table' then return nil end

    local index = tonumber(answer.localIndex)
    if not index or index < 0 or index ~= math.floor(index) then return nil end

    return {
        collection = ClothingWheel.collectionToken(answer.collection),
        localIndex = math.floor(index),
    }
end
