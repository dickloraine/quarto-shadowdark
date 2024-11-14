local RawInline = pandoc.RawInline
local Inlines = pandoc.Inlines
local List = pandoc.List
local stringify = pandoc.utils.stringify

local bottom_margin = "1.5cm"
local left_margin = "1cm"
local image_source = nil

function Meta(meta)
    if meta["bottom-margin"] then
        bottom_margin = stringify(meta["bottom-margin"])
    end
    if meta["left-margin"] then
        left_margin = stringify(meta["left-margin"])
    end
    if meta["image-source-directory"] then
        image_source = stringify(meta["image-source-directory"])
    end
end

function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
end

function setImageSource(img)
    if not image_source then
        return
    end
    local filename = img.src:match("([^/]+)$")
    local new_src = image_source .. filename
    if file_exists(new_src) then
        img.src = new_src
    end
end

function ImageLatex(img)
    local options = img.attributes.options or ""
    setImageSource(img)
    if img.classes:includes("no-pdf") then
        return {}
    elseif img.classes:includes("fullpage") then
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
    elseif img.classes:includes("wrap-circle") then
        local content = Inlines({})
        local position = img.attributes.position or "l"
        local wx = img.attributes.wx or "0.47"
        local cshift = img.attributes.cshift or "0,0"
        content:insert(RawInline('latex', '\\vspace*{4pt}'))
        content:insert(RawInline('latex', string.format('\\begin{wrapfigure}{%s}{%s\\textwidth}', position, wx)))
        content:insert(RawInline('latex', '\\centering'))
        content:insert(RawInline('latex', '\\begin{tikzpicture}'))
        content:insert(RawInline('latex', string.format('\\clip (%s) circle (%s\\textwidth);', cshift, wx/2)))
        content:insert(RawInline('latex', string.format('\\path (0,0) node {\\includegraphics[%swidth=%s\\textwidth]{%s}};', options, wx, img.src)))
        content:insert(RawInline('latex', '\\end{tikzpicture}'))
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
    return img
end

function ImageHTML(img)
    local options = img.attributes.options or ""
    setImageSource(img)
    if img.attributes["html-class"] then
        img.classes = List{(img.attributes["html-class"])}
    end
    if img.classes:includes("no-html") then
        return {}
    elseif img.attributes["html-width"] then
        img.attributes.width = img.attributes["html-width"]
        return img
    elseif img.classes:includes("fullpage") then
        img.attributes.width = "100%"
        return img
    elseif img.classes:includes("fullpage-bg") then
        img.attributes.width = "100%"
        return img
    elseif img.classes:includes("wrap") then
        local position = img.attributes.position or "l"
        local wx = img.attributes.wx or 0.47

        local width = 100 * wx
        local margin = "margin-right: 1em"
        
        if position == "r" then
            position = "right"
            margin = "margin-left: 1em"
        else
            position = "left"
        end

        img.attributes.style = string.format('position: relative; z-index: 2; width: %s%%; float: %s; %s;', width, position, margin)
        return img
    elseif img.classes:includes("wrap-circle") then
        local content = Inlines({})
        local position = img.attributes.position or "l"
        local wx = img.attributes.wx or 0.47

        local width = 100 * wx
        local margin = "margin-right: 1em"
        
        if position == "r" then
            position = "right"
            margin = "margin-left: 1em"
        else
            position = "left"
        end

        content:insert(RawInline('html', string.format('<div style="position: relative; z-index: 2; aspect-ratio : 1 / 1; overflow: hidden; border-radius: 50%%; width: %s%%; float:%s; %s;">', width, position, margin)))

        content:insert(RawInline('html', string.format('<img src="%s" alt="" style="width: 100%%;">', img.src)))
        content:insert(RawInline('html', '</div>'))

        return content
    elseif img.classes:includes("wide") then
        img.attributes.width = "100%"
        return img
    elseif img.classes:includes("bottom-left") then
        img.attributes.style = 'width: 48%; float: left; margin-right: 1em; position: relative; z-index: 2;'
        return img
    elseif img.classes:includes("bottom-right") then
        img.attributes.style = 'width: 48%; float: right; margin-left: 1em; position: relative; z-index: 2;'
        return img
    end
    return img
end

if FORMAT:match("latex") then
    return {
        {Meta = Meta},
        {Image = ImageLatex},
    }
elseif FORMAT:match("html") then
    return {
        {Meta = Meta},
        {Image = ImageHTML},
    }
end
