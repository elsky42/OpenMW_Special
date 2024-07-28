local core = require('openmw.core')
local self = require('openmw.self') as core.GameObject
local NPC = require('openmw.types').NPC

local dispositionModifier: number = 0

local function modifyDisposition(data: table)
    assert(data and data.modifier and data.toward)
    if data.modifier == dispositionModifier then return end
    local diffModifier = data.modifier as number  - dispositionModifier
    NPC.modifyBaseDisposition(self, data.toward as core.GameObject, diffModifier)
    dispositionModifier = data.modifier as number
end

local function onSave(): table
    return { dispositionModifier = dispositionModifier }
end

local function onLoad(data: table, _)
    dispositionModifier = data and data.dispositionModifier as number or 0
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
    },
    eventHandlers = {
        SpecialModifyDisposition = modifyDisposition
    }
}