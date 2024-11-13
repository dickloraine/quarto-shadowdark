local function readMeta(meta)
    if meta['self-host-fonts'] then
        quarto.doc.add_html_dependency({
            name = "shadowdark_fonts_self",
            version = "0.0",
            stylesheets = { "../fonts.css" }
        })
    else
        quarto.doc.add_html_dependency({
            name = "shadowdark_fonts_hosted",
            version = "0.0",
            stylesheets = { "../fonts-import.css" }
        })
    end
end

return {
    { Meta = readMeta }
}
