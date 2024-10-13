local RawInline = pandoc.RawInline
local Inlines = pandoc.Inlines
local stringify = pandoc.utils.stringify

local bottom_margin = "1.5cm"
local left_margin = "1cm"

function Meta(meta)
    if meta["bottom-margin"] then
        bottom_margin = stringify(meta["bottom-margin"])
    end
    if meta["left-margin"] then
        left_margin = stringify(meta["left-margin"])
    end
end

function Image(img)
    local options = img.attributes.options or ""
    if img.classes:includes("fullpage") then
        local content = Inlines({})
        local stretch = img.classes:includes("stretch") and "keepaspectratio=false," or ""
        content:insert(RawInline('latex', string.format('\\clearpage\\phantom{image}\\AddToShipoutPictureFG*{\\includegraphics[%s%swidth=\\paperwidth, height=\\paperheight]{%s}}', options, stretch, img.src)))
        return content
    elseif img.classes:includes("fullpage-bg") then
        local content = Inlines({})
        local stretch = img.classes:includes("stretch") and "keepaspectratio=false," or ""
        content:insert(RawInline('latex', string.format('\\phantom{image}\\AddToShipoutPictureBG*{\\includegraphics[%s%swidth=\\paperwidth, height=\\paperheight]{%s}}', options, stretch, img.src)))
        return content
    elseif img.classes:includes("wrap") then
        local content = Inlines({})
        local position = img.attributes.position or "l"
        local wx = img.attributes.wx or "0.47"
        content:insert(RawInline('latex', string.format('\\begin{wrapfigure}{%s}{%s\\textwidth}', position, wx)))
        content:insert(RawInline('latex', '\\centering'))
        content:insert(RawInline('latex', string.format('\\includegraphics[%swidth=%s\\textwidth]{%s}', options, wx, img.src)))
        content:insert(RawInline('latex', '\\end{wrapfigure}'))
        return content
    elseif img.classes:includes("fill") then
        local content = Inlines({})
        local position = img.attributes.placement or "htbp"
        content:insert(RawInline('latex', string.format('\\begin{figure*}[%s]\n\\centering\n', position)))
        content:insert(img)
        if img.attributes.caption then
            content:insert(RawInline('latex', string.format('\\caption{%s}', img.attributes.caption)))
        end
        content:insert(RawInline('latex', '\n\\end{figure*}'))
        return content
    elseif img.classes:includes("wide") then
        local content = Inlines({})
        local position = img.attributes.placement or "htbp"
        content:insert(RawInline('latex', string.format('\\begin{figure*}[%s]\n', position)))
        content:insert(RawInline('latex', string.format('\\includegraphics[%swidth=\\textwidth]{%s}', options, img.src)))
        if img.attributes.caption then
            content:insert(RawInline('latex', string.format('\\caption{%s}', img.attributes.caption)))
        end
        content:insert(RawInline('latex', '\n\\end{figure*}'))
        return content
    elseif img.classes:includes("bottom") then
        local content = Inlines({})
        local width = img.attributes.lwidth or "\\textwidth"
        content:insert(RawInline('latex', string.format('\\AddToShipoutPictureFG*{\\AtPageLowerLeft{\\put(%s,%s){\\includegraphics[%swidth=%s]{%s}}}}', left_margin, bottom_margin, options, width, img.src)))
        return content
    elseif img.classes:includes("bottom-left") then
        local content = Inlines({})
        local width = img.attributes.lwidth or "\\columnwidth"
        local xshift = (img.attributes.xshift or "0cm") .. "+" .. left_margin
        local yhift = (img.attributes.yshift or "0cm") .. "+" .. bottom_margin
        content:insert(RawInline('latex', string.format('\\AddToShipoutPictureFG*{\\AtPageLowerLeft{\\put(%s,%s){\\includegraphics[%swidth=%s]{%s}}}}', xshift, yhift, options, width, img.src)))
        return content
    elseif img.classes:includes("bottom-right") then
        local content = Inlines({})
        local width = img.attributes.lwidth or "\\columnwidth"
        local xshift = (img.attributes.xshift or "0cm") .. "+" .. "\\columnwidth + \\columnsep + " .. left_margin
        local yhift = (img.attributes.yshift or "0cm") .. " + " .. bottom_margin
        content:insert(RawInline('latex', string.format('\\AddToShipoutPictureFG*{\\AtPageLowerLeft{\\put(%s,%s){\\includegraphics[%swidth=%s]{%s}}}}', xshift, yhift, options, width, img.src)))
        return content
    elseif img.classes:includes("place") then
        local content = Inlines({})
        local anchor = img.attributes.anchor or "AtPageLowerLeft"
        local position = img.attributes.position or "0,0"
        local width = img.attributes.lwidth or "\\textwidth"
        content:insert(RawInline('latex', string.format('\\AddToShipoutPictureFG*{\\%s{\\put(%s){\\includegraphics[%swidth=%s]{%s}}}}', anchor, position, options, width, img.src)))
        return content
    end
end

if FORMAT:match("latex") then
    return {
        {Meta = Meta},
        {Image = Image},
    }
end
