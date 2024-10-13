local RawInline = pandoc.RawInline
local Inlines = pandoc.Inlines
local stringify = pandoc.utils.stringify

function getRow(row, header)
    local out = ""
    for i, cell in ipairs(row.cells) do
        if i > 1 then
            out = out .. " &"
        end
        if header then 
            out = out .. "\\textbf{" .. stringify(cell.contents) .. "}"
        else
            out = out .. stringify(cell.contents)
        end
    end
    out = out .. " \\\\"
    return out
end

function getColspec(tbl)
    local colspec = ""
    for _, spec in ipairs(tbl.colspecs) do
        local align = stringify(spec)
        if align == "AlignDefault" or align == "AlignLeft" then
            colspec = colspec .. "l"
        elseif align == "AlignCenter" then
            colspec = colspec .. "c"
        else
            colspec = colspec .. "r"
        end
    end
    return colspec
end

if FORMAT:match("latex") then
    function Table(tbl)
        if stringify(tbl.caption.long) ~= "twocolumn" then
            return
        end
       
        local content = Inlines({})

        content:insert(RawInline('latex', '\\begin{center}'))
        content:insert(RawInline('latex', string.format('\\begin{tblr}{%s}', getColspec(tbl))))

        content:insert(RawInline('latex', getRow(tbl.head.rows[1], true)))

        content:insert(RawInline('latex', '\\hline'))
        
        for _, row in ipairs(tbl.bodies[1].body) do
            content:insert(RawInline('latex', getRow(row)))
        end

        content:insert(RawInline('latex', '\\end{tblr}'))
        content:insert(RawInline('latex', '\\end{center}'))

        return content
    end
end
