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

function getMonster(el)
    local text = el.text
    if not text then
        text = stringify(el.content)
    end
    local local_monster = json.decode(text)

    if local_monster then
        return formatMonster(local_monster)
    end
    
    if not monster_data then
        return
    end
    
    for _, monster in ipairs(monster_data) do
        if monster.name == text then
            return formatMonster(monster)
        end
    end
end

function hasPlusMinus(s)
    local t = string.sub(s, 1, 1)
    return t == "-" or t == "+"
end

function getArmorText(monster, short)
    local armor = tostring(math.floor(monster.armorClass))
    if monster.armor and monster.armor ~= "" and not short then
        return armor .. " (" .. monster.armor .. ")"
    end
    return armor
end

function getStatBlockLayout(cb)
    local order = {"AC", "HP", "ATK", "MV", "S", "D", "C", "I", "W", "Ch", "AL", "LV"}
    local breaks = {LV=Str("")}
    local short = false

    if cb.classes:includes("short") then
        short = true
    end

    if ((options['alternative-layout'] and not short) or (options['short-alternative-layout'] and short) or cb.classes:includes("alt")) then
        order = {"AC", "HP", "MV", "ATK", "S", "D", "C", "I", "W", "Ch", "AL", "LV"}
        breaks = {MV=LineBreak(), ATK=LineBreak(), Ch=LineBreak(), LV=Str("")}
    end

    return order, breaks, short

end

function getStats(monster, short)
    return {
        AC=getArmorText(monster, short),
        HP=monster.maxHitPoints,
        ATK=monster.attackText,
        MV=monster.movement,
        S=monster.stats.str_mod,
        D=monster.stats.dex_mod,
        C=monster.stats.con_mod,
        I=monster.stats.int_mod,
        W=monster.stats.wis_mod,
        Ch=monster.stats.cha_mod,
        AL=monster.alignment:sub(1, 1),
        LV=monster.level,
    }
end

function getStatBlock(monster, cb)
    local stats = Inlines({})
    order, breaks, short = getStatBlockLayout(cb)

    local statMap = getStats(monster, short)

    for _, stat in ipairs(order) do
        local value = statMap[stat]
        stats:insert(Strong(stat))
        if type(value) == "number" then
            value = tostring(math.floor(value))
        end
        if not short and stat_names:includes(stat) and not hasPlusMinus(value) then
            value = "+" .. value
        end
        stats:insert(Str(" " .. value))
        if breaks[stat] then
            stats:insert(breaks[stat])
        else
            stats:insert(Str(", "))
        end
    end

    return stats
end

function getActions(monster)
    local actions = Inlines({})

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

    content:insert(Para(Emph(monster.description)))
    local image = getImage(monster, cb)
    if image then
        content:insert(Para(image))
    end
    content:insert(Para(getStatBlock(monster, cb)))
    content:insert(Para(getActions(monster)))

    return content
end

function getMonsterShortBlock(monster, cb)
    local content = Inlines({})

    content:insert(Strong(monster.name))
    local stats = getStatBlock(monster, cb)
    stats:insert(LineBreak())
    stats:extend(getActions(monster))
    content:insert(Para(stats))
    return content
end

function Header(hd)
    if not hd.classes:includes("monster") then
        return
    end

    local monster = getMonster(hd)
    if not monster then
        return
    end

    local block =  getMonsterBlock(monster, hd)
    block:insert(1, hd)
    return block
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
    {Header = Header},
    {CodeBlock = CodeBlock},
}
