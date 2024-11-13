json = pandoc.json

local Inlines = pandoc.Inlines
local Header = pandoc.Header
local Strong = pandoc.Strong
local Para = pandoc.Para
local Emph = pandoc.Emph
local Str = pandoc.Str
local stringify = pandoc.utils.stringify

local spell_data = nil

function Meta(meta)
    if not meta['spells-data'] then
        return
    end

    local spell_data_name = stringify(meta['spells-data'])

    local spell_file = io.open(spell_data_name, "r")
    if not spell_file then
        return
    end
    local spell_data_json = spell_file:read("*all")
    spell_file:close()
    spell_data = json.decode(spell_data_json)
end

function getSpell(hd)
    -- local local_spell = json.decode(hd.text)

    -- if local_spell then
    --     return local_spell
    -- end

    if not spell_data then
        return
    end

    local name = stringify(hd.content)
    for _, spell in ipairs(spell_data) do
        if spell.name == name then
            return spell
        end
    end
end

function getSpellBlock(spell, header)
    local container = Inlines({})
    local tier = spell.tier
    if type(tier) == "number" then
        tier = tostring(math.floor(spell.tier))
    end

    if header then
        container:insert(header)
    end
    container:insert(Para(Emph("Tier " .. tier .. ", " .. table.concat(spell.classes, ", "))))
    container:insert(Para(Inlines({Strong("Duration: "), Str(spell.duration)})))
    container:insert(Para(Inlines({Strong("Range: "), Str(spell.range)})))
    container:extend(pandoc.read(spell.description).blocks)

    return container
end

function Header(hd)
    if not hd.classes:includes("spell") then
        return
    end

    local spell = getSpell(hd)
    if not spell then
        return
    end

    return getSpellBlock(spell, hd)
end

function CodeBlock(cb)
    if not cb.classes:includes("spell") then
        return
    end

    local spell = json.decode(cb.text)
    if not spell then
        return
    end

    return getSpellBlock(spell)
end


return {
    {Meta = Meta},
    {Header = Header},
    {CodeBlock = CodeBlock},
}

