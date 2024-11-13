local RawInline = pandoc.RawInline
local Str = pandoc.Str

if FORMAT:match("latex") then
    function Code(cd)
        if not cd.classes:includes("drop-cap") then
            return
        end
        local options = "lines=3"
        if cd.attributes.options then
            options = options
        end
        local first_letter = string.sub(cd.text, 1, 1)
        local rest = string.sub(cd.text, 2)
        return RawInline("latex", string.format("\\lettrine[%s]{%s}{%s}", options, first_letter, rest))
    end
elseif FORMAT:match("html") then
    function Code(cd)
        if not cd.classes:includes("drop-cap") then
            return
        end
        local first_letter = string.sub(cd.text, 1, 1)
        local rest = string.sub(cd.text, 2)
        return RawInline("html", string.format('<span class="dropcap">%s</span>%s', first_letter, rest))
    end
else
    function Code(cd)
        if not cd.classes:includes("drop-cap") then
            return
        end
        return Str(cd.text)
    end
end
