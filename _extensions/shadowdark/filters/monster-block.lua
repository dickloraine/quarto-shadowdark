json = pandoc.json

local Inlines = pandoc.Inlines
local Header = pandoc.Header
local Image = pandoc.Image
local Strong = pandoc.Strong
local Para = pandoc.Para
local List = pandoc.List
local Emph = pandoc.Emph
local Str = pandoc.Str
local LineBreak = pandoc.LineBreak
local stringify = pandoc.utils.stringify

local monster_data = nil
local options = {}
local stat_names = List({"S", "D", "C", "I", "W", "Ch"})

function Meta(meta)
    local monster_options = meta["monsters"]
    if not pandoc.utils.type(monster_options) == "table" then
        return
    end
    assert(type(monster_options) == "table")

    for k, v in pairs(monster_options) do
        if pandoc.utils.type(v) == 'boolean' then
            if v then
                options[k] = true
            else
                options[k] = false
            end
        elseif pandoc.utils.type(v) == 'Inlines' then
            options[k] = stringify(v)
        else
            options[k] = v
        end
    end

    if not options['data-folder'] then
        return
    end

    local monster_file = io.open(options['data-folder'] .. "monsters.json", "r")
    if not monster_file then
        return
    end
    local monster_data_json = monster_file:read("*all")
    monster_file:close()
    monster_data = json.decode(monster_data_json)
end

function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
 end

function formatMonster(monster)
    monster.stats.str_mod = monster.stats.str_mod or monster.stats[1]
    monster.stats.dex_mod = monster.stats.dex_mod or monster.stats[2]
    monster.stats.con_mod = monster.stats.con_mod or monster.stats[3]
    monster.stats.int_mod = monster.stats.int_mod or monster.stats[4]
    monster.stats.wis_mod = monster.stats.wis_mod or monster.stats[5]
    monster.stats.cha_mod = monster.stats.cha_mod or monster.stats[6]
    monster.maxHitPoints = monster.maxHitPoints or monster.hp
    monster.armorClass = monster.armorClass or monster.ac
    monster.attackText = monster.attackText or monster.attack
    return monster
end

function getMonster(cb)
    local local_monster = json.decode(cb.text)

    if local_monster then
        return formatMonster(local_monster)
    end
    
    if not monster_data then
        return
    end
    
    local name = cb.text
    for _, monster in ipairs(monster_data) do
        if monster.name == name then
            return formatMonster(monster)
        end
    end
end

function hasPlusMinus(s)
    local t = string.sub(s, 1, 1)
    return t == "-" or t == "+"
end

function getStatBlockBuilders(monster, short)
    local stats = Inlines({})
    local armor = monster.armorClass
    if monster.armor and monster.armor ~= "" and not short then
        armor = armor .. "(" .. monster.armor .. ")"
    end

    function add_stat(name, value, sep)
        stats:insert(Strong(name))
        if type(value) == "number" then
            value = tostring(math.floor(value))
        end
        if not short and stat_names:includes(name) and not hasPlusMinus(value) then
            value = "+" .. value
        end
        stats:insert(Str(" " .. value))
        if not sep then
            stats:insert(Str(", "))
        else
            stats:insert(sep)
        end
    end

    return stats, armor, add_stat
end

function getStatBlock(monster, short)
    local stats, armor, add_stat = getStatBlockBuilders(monster, short)

    add_stat("AC", armor)
    add_stat("HP", monster.maxHitPoints)
    add_stat("ATK", monster.attackText)
    add_stat("MV", monster.movement)
    add_stat("S", monster.stats.str_mod)
    add_stat("D", monster.stats.dex_mod)
    add_stat("C", monster.stats.con_mod)
    add_stat("I", monster.stats.int_mod)
    add_stat("W", monster.stats.wis_mod)
    add_stat("Ch", monster.stats.cha_mod)
    add_stat("AL", monster.alignment:sub(1, 1))
    add_stat("LV", monster.level, Str(""))

    return stats
end

function getAltStatBlock(monster, short)
    local stats, armor, add_stat = getStatBlockBuilders(monster, short)

    add_stat("AC", armor)
    add_stat("HP", monster.maxHitPoints)
    add_stat("MV", monster.movement, LineBreak())
    add_stat("ATK", monster.attackText, LineBreak())
    add_stat("S", monster.stats.str_mod)
    add_stat("D", monster.stats.dex_mod)
    add_stat("C", monster.stats.con_mod)
    add_stat("I", monster.stats.int_mod)
    add_stat("W", monster.stats.wis_mod)
    add_stat("Ch", monster.stats.cha_mod, LineBreak())
    add_stat("AL", monster.alignment:sub(1, 1))
    add_stat("LV", monster.level, Str(""))

    return stats
end

function getActions(monster)
    local actions = pandoc.Inlines({})

    for i, action in ipairs(monster.actions) do
        if i > 1 then
            actions:insert(LineBreak())
        end
        actions:insert(Strong(action.name .. ". "))
        actions:insert(Str(action.description))
    end
    return actions
end

function getImage(monster, cb)
    if options.images or cb.classes:includes("image") then
        local image = options['data-folder'] .. "images/"
        if (options['color-images'] or cb.classes:includes("color")) and monster.image_color then
            image = image .. monster.image_color
        elseif monster.image then
            image = image .. monster.image
        end
        if file_exists(image) then
            return Image('', image)
        end
    end
end

function getMonsterBlock(monster, cb)
    local content = Inlines({})

    content:insert(Header(3, monster.name))
    content:insert(Para(Emph(monster.description)))
    local image = getImage(monster, cb)
    if image then
        content:insert(Para(image))
    end
    if (options['alternative-layaout'] or cb.classes:includes("alt")) then
        content:insert(Para(getAltStatBlock(monster)))
    else
        content:insert(Para(getStatBlock(monster)))
    end
    content:insert(Para(getActions(monster)))

    return content
end

function getMonsterShortBlock(monster, cb)
    local content = Inlines({})

    content:insert(Strong(monster.name))
    local stats
    if (options['short-alternative-layaout'] or cb.classes:includes("alt")) then
        stats = getAltStatBlock(monster, true)
    else
        stats = getStatBlock(monster, true)
    end
    stats:insert(LineBreak())
    stats:extend(getActions(monster))
    content:insert(Para(stats))
    return content
end

function CodeBlock(cb)
    if not cb.classes:includes("monster") then
        return
    end

    local monster = getMonster(cb)
    if not monster then
        return
    end

    if cb.classes:includes("short") then
        return getMonsterShortBlock(monster, cb)
    end

    return getMonsterBlock(monster, cb)
end


return {
    {Meta = Meta},
    {CodeBlock = CodeBlock},
}

