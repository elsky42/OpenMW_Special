local core = require('openmw.core')

global maxDifficultyPoints = 50
global maxPaddingPoints = 20
global maxValidDifficultyPoints = maxDifficultyPoints - maxPaddingPoints

global record Special
    -- unique identifier of the special advantage/disadvantage
    id: string

    -- name of the special advantage/disadvantage to show to the user
    name: string

    -- The id of the ability to activate
    -- if the special is selected
    abilityId: string | nil

    cost: number
end

global advantages: {Special} = {}
global advantagesById: {string:Special} = {}
global advantagesByAbilityId: {string:Special} = {}
global disadvantages: {Special} = {}
global disadvantagesById: {string:Special} = {}
global disadvantagesByAbilityId: {string:Special} = {}

local function checkAbilityExists(abilityId: string)
    if (core.magic.spells.records as {string:core.Spell})[abilityId] == nil then
        error('Ability ' .. abilityId .. ' not found in game! Please load the plugin special.omwaddon.')
    end
end

local function addSpecial(special: Special)
    if special.abilityId then
        checkAbilityExists(special.abilityId)
    end
    if special.cost >= 0 then
        table.insert(advantages, special)
        advantagesById[special.id] = special
        if special.abilityId then
            advantagesByAbilityId[special.abilityId] = special
        end
    else
        table.insert(disadvantages, special)
        disadvantagesById[special.id] = special
        if special.abilityId then
            disadvantagesByAbilityId[special.abilityId] = special
        end
    end
end

local function percentageToNoun(percentage: number): string
    if percentage == 100 then return 'immunity'
    elseif percentage == 75 then return 'high resistance'
    elseif percentage == 50 then return 'resistance'
    elseif percentage == 25 then return 'low resistance'
    elseif percentage == -25 then return 'small weakness'
    elseif percentage == -50 then return 'weakness'
    elseif percentage == -75 then return 'great weakness'
    elseif percentage == -100 then return 'critical weakness'
    else error('Unknown percentage ' .. tostring(percentage))
    end
end

local function firstToUpper(str: string): string
    return (str:gsub("^%l", string.upper))
end

local function spacesToUnderscores(str: string): string
    return (str:gsub(" +", "_"))
end

for _, element in ipairs({'fire', 'frost', 'shock', 'poison'}) do
    for absoluteCost, absolutePercentage in pairs({[40] = 100,
                                                   [30] = 75,
                                                   [20] = 50,
                                                   [10] = 25}) do
        for cost, percentage in pairs({[absoluteCost] = absolutePercentage,
                                       [-absoluteCost] = -absolutePercentage}) do
            local noun = percentageToNoun(percentage)
            local id = spacesToUnderscores(noun) .. '_to_' .. element
            local abilityId = 'special_' .. id
            checkAbilityExists(abilityId)
            local name = firstToUpper(noun) .. ' to ' .. firstToUpper(element) .. ' (' .. tostring(percentage) .. '%)'
            addSpecial { id = id, name = name, abilityId = abilityId, cost = cost }
        end
    end
end

for absoluteCost, absolutePercentage in pairs({[40] = 75,
                                               [30] = 50,
                                               [20] = 25}) do
    for cost, percentage in pairs({[absoluteCost] = absolutePercentage,
                                   [-absoluteCost] = -absolutePercentage}) do
        local noun = percentageToNoun(percentage)
        local id = spacesToUnderscores(noun) .. '_to_magicka'
        local abilityId = 'special_' .. id
        local name = firstToUpper(noun) .. ' to magicka (' .. tostring(percentage) .. '%)'
        addSpecial { id = id, name = name, abilityId = abilityId, cost = cost }
    end
end

addSpecial {
    id = 'robust',
    name = 'Robust (+10 End)',
    abilityId = 'special_robust',
    cost = 20,
}

addSpecial {
    id = 'fragile',
    name = 'Fragile (-10 End)',
    abilityId = 'special_fragile',
    cost = -20,
}

addSpecial {
    id = 'strong',
    name = 'Strong (+10 Str)',
    abilityId = 'special_strong',
    cost = 20,
}

addSpecial {
    id = 'weak',
    name = 'Weak (-10 Str)',
    abilityId = 'special_weak',
    cost = -20,
}

addSpecial {
    id = 'agile',
    name = 'Agile (+10 Agi)',
    abilityId = 'special_agile',
    cost = 20,
}

addSpecial {
    id = 'Clumsy',
    name = 'Clumsy (-10 Agi)',
    abilityId = 'special_clumsy',
    cost = -20,
}

addSpecial {
    id = 'fast',
    name = 'Fast (+10 Spe)',
    abilityId = 'special_fast',
    cost = 20,
}

addSpecial {
    id = 'slow',
    name = 'Slow (-10 Spe)',
    abilityId = 'special_slow',
    cost = -20,
}

addSpecial {
    id = 'charismatic',
    name = 'Charismatic (+10 Cha)',
    abilityId = 'special_charismatic',
    cost = 20,
}

addSpecial {
    id = 'uncharismatic',
    name = 'Uncharismatic (-10 Cha)',
    abilityId = 'special_uncharismatic',
    cost = -20,
}

addSpecial {
    id = 'intelligent',
    name = 'Intelligent (+10 Int)',
    abilityId = 'special_intelligent',
    cost = 20,
}

addSpecial {
    id = 'stupid',
    name = 'Stupid (-10 Int)',
    abilityId = 'special_stupid',
    cost = -20,
}

addSpecial {
    id = 'resolute',
    name = 'Resolute (+10 Wil)',
    abilityId = 'special_resolute',
    cost = 20,
}

addSpecial {
    id = 'irresolute',
    name = 'Irresolute (-10 Wil)',
    abilityId = 'special_irresolute',
    cost = -20,
}

addSpecial {
    id = 'lucky',
    name = 'Lucky (+10 Luc)',
    abilityId = 'special_lucky',
    cost = 20,
}

addSpecial {
    id = 'unlucky',
    name = 'Unlucky (-10 Luc)',
    abilityId = 'special_unlucky',
    cost = -20,
}

addSpecial {
    id = 'regenerative',
    name = 'Regenerative (1hp/s)',
    abilityId = 'special_regenerative',
    cost = 20,
}

addSpecial {
    id = 'relentless',
    name = 'Relentless (4fp/s)',
    abilityId = 'special_relentless',
    cost = 20,
}

addSpecial {
    id = 'recharging',
    name = 'Recharging (1mp/s)',
    abilityId = 'special_recharging',
    cost = 20,
}

for _, skill in ipairs {'Heavy Armor',
                        'Medium Armor',
                        'Spear',
                        'Acrobatics',
                        'Armorer',
                        'Axe',
                        'Blunt Weapon',
                        'Long Blade',
                        'Block',
                        'Light Armor',
                        'Marksman',
                        'Sneak',
                        'Athletic', 
                        'HandToHand',
                        'Short Blade',
                        'Unarmored', 
                        'Illusion',
                        'Mercantile',
                        'Speechcraft',
                        'Alchemy',
                        'Conjuration',
                        'Enchant',
                        'Security',
                        'Alteration',
                        'Destruction',
                        'Mysticism', 
                        'Restoration'} do
    local idPostfix = spacesToUnderscores(skill:lower())
    
    local id = 'proficient_in_' .. idPostfix
    addSpecial {
        id = id,
        name = 'Proficient in ' .. skill .. ' (+20)',
        abilityId = 'special_' .. id,
        cost = 20,
    }

    id = 'inept_at_' .. idPostfix
    addSpecial {
        id = id,
        name = 'Inept at ' .. skill .. ' (-100)',
        abilityId = 'special_' .. id,
        cost = -5,
    }
end

global record AdvantagesDisadvantages
    maxHp: number
    advantages: {Special}
    disadvantages: {Special}
end

function AdvantagesDisadvantages:new(): AdvantagesDisadvantages
    local self: AdvantagesDisadvantages = setmetatable({}, { __index = AdvantagesDisadvantages })
    self.maxHp = 0
    self.advantages = {}
    self.disadvantages = {}
    return self
end

function AdvantagesDisadvantages:isNotEmpty(): boolean
    return self.maxHp ~= 0 or #self.advantages ~= 0 or #self.disadvantages ~= 0
end

function AdvantagesDisadvantages:cost(): number
    local cost = self.maxHp
    for _, advantage in ipairs(self.advantages) do
        cost = cost + advantage.cost
    end
    for _, disadvantage in ipairs(self.disadvantages) do
        cost = cost + disadvantage.cost
    end
    return cost
end

function AdvantagesDisadvantages:availableAdvantages(): {Special}
    local notAvailableAdvantages: {string:boolean} = {}
    for _, advantage in ipairs(self.advantages) do
        notAvailableAdvantages[advantage.id] = true
    end
    local availableAdvantages = {}
    for _, advantage in ipairs(advantages) do
        if not notAvailableAdvantages[advantage.id] then
            table.insert(availableAdvantages, advantage)
        end
    end
    return availableAdvantages
end

function AdvantagesDisadvantages:availableDisadvantages(): {Special}
    local notAvailableDisadvantages: {string:boolean} = {}
    for _, disadvantage in ipairs(self.disadvantages) do
        notAvailableDisadvantages[disadvantage.id] = true
    end
    local availableDisadvantages = {}
    for _, advantage in ipairs(disadvantages) do
        if not notAvailableDisadvantages[advantage.id] then
            table.insert(availableDisadvantages, advantage)
        end
    end
    return availableDisadvantages
end