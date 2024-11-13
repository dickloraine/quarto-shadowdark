if FORMAT:match("html") then
    function Div(div)
        if (div.classes:includes("columns") or div.classes:includes("twocolumns")) and not div.classes:includes("html") then
            return div.content
        end
    end
end
