local RawInline = pandoc.RawInline
local Inlines = pandoc.Inlines
local Header = pandoc.Header
local Image = pandoc.Image
local Strong = pandoc.Strong
local Para = pandoc.Para
local BlockQuote = pandoc.BlockQuote
local stringify = pandoc.utils.stringify

local deco = nil
local line = nil
local spot = nil
local banner = nil

function Meta(meta)
    if meta['title-deco'] then
        deco = stringify(meta['title-deco'])
    end
    if meta['title-line'] then
        line = stringify(meta['title-line'])
    end
    if meta['header-spot'] then
        spot = stringify(meta['header-spot'])
    end
    if meta['header-bg'] then
        banner = stringify(meta['header-bg'])
    end
  end

function CodeBlockLatex(cb)
    if not cb.classes:includes("part") then
        return
    end
    local content = Inlines({})

    content:insert(RawInline('latex', string.format('\\part{%s}', cb.text)))
    content:insert(RawInline('latex', '\\begin{center}'))
    content:insert(RawInline('latex', '\\vspace{-5mm}'))
    
    if cb.attributes.subtitle then
        content:insert(RawInline('latex', '\\vspace{-3mm}'))
        content:insert(RawInline('latex', string.format('\\sffamily\\normalsize\\bfseries{%s}', cb.attributes.subtitle)))
    end
    content:insert(RawInline('latex', string.format('\\includegraphics{%s}', deco)))
    content:insert(RawInline('latex', '\\vfill'))
    if cb.attributes.spot then
        content:insert(RawInline('latex', string.format('\\includegraphics{%s}', cb.attributes.spot)))
    elseif cb.attributes.banner then
        content:insert(RawInline('latex', '\\begin{tikzpicture}[overlay,remember picture]'))
        content:insert(RawInline('latex', string.format('\\node[black] at ($(current page.south)+(0,4)$) {\\includegraphics{%s}};', banner)))
        content:insert(RawInline('latex', string.format('\\node[white] at ($(current page.south)+(0.2,4.1)$) {\\parbox{8.5cm}{\\centering\\large\\sffamily{%s}}};', cb.attributes.banner)))
        content:insert(RawInline('latex', '\\end{tikzpicture}'))
    elseif spot then
        content:insert(RawInline('latex', string.format('\\includegraphics{%s}', spot)))
    end
    content:insert(RawInline('latex', '\\end{center}'))

    return content
end

function CodeBlockOther(cb)
    if not cb.classes:includes("part") then
        return
    end
    local content = Inlines({})

    content:insert(Header(1, cb.text))

    if line then
        content:insert(Image("", line))
    end
    
    if cb.attributes.subtitle then
        content:insert(Para(Strong(cb.attributes.subtitle)))
    end

    if deco then
        content:insert(Image("", deco))
    end

    if cb.attributes.banner then
        content:insert(BlockQuote(cb.attributes.banner))
    end

    return content
end

if FORMAT:match("latex") then
    return {
      {Meta = Meta},
      {CodeBlock = CodeBlockLatex},
    }
else
    return {
        {Meta = Meta},
        {CodeBlock = CodeBlockOther},
      }
end
