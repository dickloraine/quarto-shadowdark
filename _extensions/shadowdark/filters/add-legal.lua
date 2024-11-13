local Inlines = pandoc.Inlines
local Header = pandoc.Header
local Div = pandoc.Div
local Image = pandoc.Image
local Para = pandoc.Para
local stringify = pandoc.utils.stringify

local legal
local author
local logo

function Meta(meta)
    legal = meta["legal"]
    author = meta["author"]
    logo = stringify(meta["title-logo"])
end

function addSection(header, value, content)
    if not value then
        return
    end

    if header then
        local el = Div(header)
        el.classes:insert("legal-header")
        content:insert(el)
    end
    content:extend(value)
end

function Header(hd)
    if not hd.classes:includes("legal") or not legal then
        return
    end

    local content = Inlines({})
    content:insert(hd)
    addSection("Writing, Design, Layout", author, content)
    el = Div("Art")
    addSection("Art", legal.art, content)
    addSection("Fonts", legal.fonts, content)
    addSection("Legal Information and Attribution Statement", legal["shadowdark-license"], content)
    addSection(nil, legal.license, content)
    local img = Image('', logo)
    img.attributes.style = "max-width: 400px; margin-top: 3em;"
    content:insert(Para(img))
    return content
end

return {
    {Meta = Meta},
    {Header = Header},
}

