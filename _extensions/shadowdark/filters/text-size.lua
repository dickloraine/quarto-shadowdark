local RawBlock = pandoc.RawBlock

if FORMAT:match("latex") then
    function Div(div)
        local size

        if div.classes:includes("smallsize") then
            size = 'small'
        elseif div.classes:includes("footnotesize") then
            size = 'footnotesize'
        elseif div.classes:includes("largesize") then
            size = 'large'
        elseif div.classes:includes("normalsize") then
            size = 'normalsize'
        else
            return
        end
        
        div.content:insert(1, RawBlock('latex', string.format('\\%s', size)))
        div.content:insert(RawBlock('latex', '\\normalsize'))
        return div.content
    end
end
