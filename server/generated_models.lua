-- Registro dei modelli generati offline da tools/model_forge/.
-- I modelli stanno in stream/ e vengono caricati automaticamente da FiveM;
-- questo file dice al server quale modello usare per ogni (slot, sesso, drawable,
-- texture). È un file di solo server: mai inviato a NUI, mai usato dal client.

local RESOURCE = GetCurrentResourceName()
local REGISTRY = 'data/drop_models.json'

--- @class GeneratedDropModels
--- @field map table<string, table<string, table>>
GeneratedDropModels = {
    map = {},
}

local function readRegistry()
    local raw = LoadResourceFile(RESOURCE, REGISTRY)
    if type(raw) ~= 'string' or raw == '' then return {} end
    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then return {} end
    return decoded
end

local function validModel(value)
    return (type(value) == 'string' and value ~= '') and value or nil
end

local function isTextureKey(k)
    return tostring(k):match('^%-?%d+$') ~= nil
end

--- Estrae il sesso dal nome del ped (mp_m_freemode_01, a_f_m_..., ecc.).
--- @return string|nil 'male', 'female' o nil
local function sexOf(ped)
    if type(ped) ~= 'string' then return nil end
    local p = ped:lower()
    if p:find('female', 1, true) or p:find('mp_f', 1, true) or p:find('_f_', 1, true) then
        return 'female'
    end
    if p:find('male', 1, true) or p:find('mp_m', 1, true) or p:find('_m_', 1, true) then
        return 'male'
    end
    return nil
end

--- Normalizza un bucket di texture: { ['0'] = 'model', ... }.
local function textureBucket(value)
    local out = {}
    if type(value) ~= 'table' then return out end
    for key, model in pairs(value) do
        if isTextureKey(key) then
            local m = validModel(model)
            if m then out[tostring(key)] = m end
        end
    end
    return out
end

--- Converte una voce drawable nei due formati supportati:
---   "modello"                                  (vecchio registro piatto)
---   { male = {...}, female = {...}, any = {...} } (nuovo registro)
local function normalizeEntry(value)
    if type(value) == 'string' then return validModel(value) end
    if type(value) ~= 'table' then return nil end

    local out = {}
    for _, sex in ipairs({ 'male', 'female', 'any' }) do
        local bucket = textureBucket(value[sex])
        if next(bucket) then out[sex] = bucket end
    end
    if next(out) then return out end

    -- Vecchio formato annidato senza etichetta di sesso: { ['0'] = 'model' }.
    local bucket = textureBucket(value)
    if next(bucket) then out.any = bucket return out end
    return nil
end

--- Ricarica il registro da disco. Chiamata all'avvio e da /cwmodel reload.
--- @return integer numero di modelli indicizzati
function GeneratedDropModels.reload()
    local decoded = readRegistry()
    local map = {}

    for slot, draws in pairs(decoded) do
        if type(slot) == 'string' and type(draws) == 'table' then
            local slotMap = {}
            for key, value in pairs(draws) do
                if isTextureKey(key) then
                    local entry = normalizeEntry(value)
                    if entry then slotMap[tostring(key)] = entry end
                end
            end
            if next(slotMap) then map[slot] = slotMap end
        end
    end

    GeneratedDropModels.map = map

    local slots, models = 0, 0
    for _, draws in pairs(map) do
        slots = slots + 1
        for _, entry in pairs(draws) do
            if type(entry) == 'string' then
                models = models + 1
            else
                for _, bucket in pairs(entry) do
                    for _ in pairs(bucket) do models = models + 1 end
                end
            end
        end
    end
    print(('[whip_clothingwheel] drop_models.json: %d slot, %d modelli'):format(slots, models))
    return models
end

--- Restituisce il modello generato per (slot, drawable, texture, ped), o nil.
--- @param slot string
--- @param drawable integer|string
--- @param texture integer|string|nil
--- @param ped string|nil  nome del ped dell'appearance (determina il sesso)
--- @return string|nil
function GeneratedDropModels.get(slot, drawable, texture, ped)
    if type(slot) ~= 'string' or drawable == nil then return nil end
    local draws = GeneratedDropModels.map[slot]
    if type(draws) ~= 'table' then return nil end
    local entry = draws[tostring(drawable)]
    if not entry then return nil end

    if type(entry) == 'string' then return validModel(entry) end
    if type(entry) ~= 'table' then return nil end

    local sex = sexOf(ped)
    local order = {}
    if sex then order[#order + 1] = entry[sex] end
    order[#order + 1] = entry.any
    if sex == 'female' then
        order[#order + 1] = entry.male
    elseif sex == 'male' then
        order[#order + 1] = entry.female
    end
    for _, bucket in pairs(entry) do order[#order + 1] = bucket end

    local key = tostring(texture or 0)
    for _, bucket in ipairs(order) do
        if type(bucket) == 'table' then
            local model = validModel(bucket[key] or bucket['0'])
            if model then return model end
            -- Nessuna texture esatta: usa la prima disponibile per questo sesso.
            for _, fallback in pairs(bucket) do
                model = validModel(fallback)
                if model then return model end
            end
        else
            local model = validModel(bucket)
            if model then return model end
        end
    end
    return nil
end

GeneratedDropModels.reload()
