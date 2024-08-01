local _ = require('scripts/special/conf')

global record GrouppedSpecial
    name: string
    special: Special
    items: {GrouppedSpecial}
    numParents: number
end

local specials: {Special} = {}
for _, advantage in ipairs(advantages) do
    table.insert(specials, advantage)
end
for _, disadvantage in ipairs(disadvantages) do
    table.insert(specials, disadvantage)
end

local grouppedSpecials: {GrouppedSpecial} = {}
local grouppedSpecialsByGroup: {string:GrouppedSpecial} = {}
for _, special in ipairs(specials) do
    local pgroup = ''
    local numParents = 0
    local last: GrouppedSpecial = nil

    for i, part in ipairs(special.group) do
        if pgroup ~= '' then
            numParents = numParents + 1
        end
        pgroup = pgroup .. '.' .. part
        if not grouppedSpecialsByGroup[pgroup] then
            local grouppedSpecial = {
                name = part,
                items = {},
                numParents = numParents,
            }
            if last then
                table.insert(last.items, grouppedSpecial)
            end
            grouppedSpecialsByGroup[pgroup] = grouppedSpecial
            if i == 1 then
                table.insert(grouppedSpecials, grouppedSpecial)
            end
        end
        last = grouppedSpecialsByGroup[pgroup]
    end

    if last then
        numParents = numParents + 1
        last.items = last.items or {}
        table.insert(last.items, {
            name = special.name,
            special = special,
            items = {},
            numParents = numParents,
        })
    else
        table.insert(grouppedSpecials, {
            name = special.name,
            special = special,
            items = {},
            numParents = numParents,
        })
    end
end

local toPrint: {GrouppedSpecial} = {}
local function push(specials_: {GrouppedSpecial})
    table.sort(specials_, function(s1: GrouppedSpecial, s2: GrouppedSpecial): boolean
        return s1.name < s2.name
    end)
    for i = 0, #specials_ - 1 do
        table.insert(toPrint, specials_[#specials_ - i])
    end
end
push(grouppedSpecials)
while #toPrint > 0 do
    local curr = table.remove(toPrint)
    local str = string.rep(' ', curr.numParents) .. curr.name
    if #curr.items > 0 then
        print(str)
        push(curr.items)
    else
        print(str .. ' [cost:' .. tostring(curr.special.cost) .. ']: ' .. curr.special.description)
    end
end