local RawBlock = pandoc.RawBlock

if FORMAT:match("latex") then
    function Div(div)
        local style

        if div.classes:includes("right") then
            style = 'flushright'
        elseif div.classes:includes("left") then
            style = 'flushleft'
        elseif div.classes:includes("center") then
            style = 'center'
        else
            return
        end
        
        div.content:insert(1, RawBlock('latex', string.format('\\begin{%s}', style)))
        div.content:insert(RawBlock('latex', string.format('\\end{%s}', style)))
        return div.content
    end
end
