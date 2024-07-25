local ui = require('openmw.ui')

global function lookupLayout(layout: ui.Layout, names: {string}): ui.Layout
    local current = layout
    for _, name in ipairs(names) do
        current = current.content[name] as ui.Layout | nil
        if current == nil then
            error('Unable to find layour with name ' .. name .. '(names: ' .. table.concat(names, ".") .. ')')
        end
    end
    return current
end