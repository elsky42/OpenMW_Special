local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self') as core.GameObject
local storage = require('openmw.storage')
local time = require('openmw_aux.time')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local _conf = require('scripts.special.conf')
local _widgets = require('scripts.special.widgets')
local _ = require('scripts.special.settings')

local rgb = util.color.rgb
local v2 = util.vector2
local V2 = util.Vector2

local specials: AdvantagesDisadvantages = AdvantagesDisadvantages:new()
local specialsSkillMultiplier: number = 1
local phobias: {Special} = {}
local phobiaCheckEvery: number = 2
local phobiaTimeSinceCheck: number = 0
local phobiaTimeSinceLastTriggerred: number = 0
local nightlys: {Special} = {}
local nightlysCheckEvery: number = 5
local nightlysTimeSinceCheck: number = 10000000
local insidesOutsides: {Special} = {}
local insidesCheckEvery: number = 5
local insidesTimeSinceCheck: number = 100000
local mainElement: ui.Element = nil 
local createMainElement: function() = nil
local editElement: ui.Element = nil
local editElementChangeSelection: function(integer) = nil
local applyElement: ui.Element = nil
local reputationElement: ui.Element = nil

local settings = storage.playerSection('special_settings')

local function destroyMainElement()
    if not mainElement then return end
    mainElement:destroy()
    mainElement = nil
    I.UI.setMode()
end

local function destroyEditElement()
    if not editElement then return end
    editElement:destroy()
    editElement = nil
    editElementChangeSelection = nil
    I.UI.setMode()
end

local function destroyApplyElement()
    if not applyElement then return end
    applyElement:destroy()
    applyElement = nil
    I.UI.setMode()
end

local function destroyReputationElement()
    if not reputationElement then return end
    reputationElement:destroy()
    reputationElement = nil
    I.UI.setMode()
end

-- returns the difficulty in progressing skills as fraction where
-- 0 is easy and 1 is difficult.
local function skillAdvancementDifficultyFraction(): number
    local difficulty = math.max(-maxDifficultyPoints, math.min(maxDifficultyPoints, specials:cost()))
    return (difficulty + maxDifficultyPoints) / (maxDifficultyPoints * 2)
end

local function updateDifficultyLine()
    local lineRelativePosition = 0.2 + 0.75 * (1 - skillAdvancementDifficultyFraction())
    local line = lookupLayout(mainElement.layout, {'second_column', 'difficulty_line'})
    local linePosition = line.props.relativePosition as V2
    line.props.relativePosition = v2(linePosition.x, lineRelativePosition)
end

local function firstColumn(): ui.Layout
    local content = ui.content {}
    content:add(background {})
    content:add(borders(true))
    content:add(textLines {
        lines = {'ADVANTAGES/DISADVANTAGES'},
        relativeSize = v2(1, 0.08),
    })
    content:add {
        template = I.MWUI.templates.horizontalLineThick,
        props = {
            anchor = v2(0, 0.5),
            relativePosition = v2(0, 0.08)
        },
    }
    local lines: {string} = {}
    for _, advantage in ipairs(specials.advantages) do
        table.insert(lines, advantage.name .. ' [' .. tostring(advantage.cost) .. ' points]')
    end
    for _, disadvantage in ipairs(specials.disadvantages) do
        table.insert(lines, disadvantage.name .. ' [' .. tostring(disadvantage.cost) .. ' points]')
    end
    local scrollableTextLine: ScrollableTextLines
    scrollableTextLine = ScrollableTextLines:new {
        lines = lines,
        events = {
            mouseDoubleClick = function(i: number)
                    if i <= #specials.advantages then
                        table.remove(specials.advantages, i)
                    else
                        table.remove(specials.disadvantages, i - #specials.advantages)
                    end
                    scrollableTextLine:remove(i)
                    updateDifficultyLine()
                    mainElement:update()
                end,
            onChange = function(_: number) mainElement:update() end,
        },
        props = {
            relativePosition = v2(0.05, 0.1),
            relativeSize = v2(0.9, 0.85),
            scrollbarRelativeSizeWidth = 0.05,
        }
    }
    content:add(scrollableTextLine:layout())
    return {
        content = content,
        props = {
            relativeSize = v2(0.48, 1),
        },
    }
end

local function secondColumn(): ui.Layout
    local content = ui.content {}
    content:add(background {})
    content:add(borders(true))
    content:add(textLines {
        lines = {'SKILL', 'ADVANCEMENT', 'FOR CLASS'},
        relativeSize = v2(1, 0.15),
    })
    content:add {
        template = I.MWUI.templates.horizontalLineThick,
        props = { relativePosition = v2(0, 0.15) },
    }
    content:add {
        template = templates.textNormal,
        props = {
            anchor = v2(1, 0),
            relativePosition = v2(0.65, 0.2),
            text = 'DIFFICULT',
        },
    }
    content:add {
        template = templates.textNormal,
        props = {
            anchor = v2(1, 0.5),
            relativePosition = v2(0.65, 0.575),
            text = 'AVERAGE',
        },
    }
    content:add {
        template = templates.textNormal,
        props = {
            anchor = v2(1, 1),
            relativePosition = v2(0.65, 0.95),
            text = 'EASY',
        },
    }
    content:add {
        type = ui.TYPE.Image,
        props = {
            alpha = 0.5,
            color = util.color.hex('910601'),
            relativePosition = v2(0.7, 0.2),
            relativeSize = v2(0.2, 0.15),
            resource = ui.texture { path = 'white' },
        },
    }
    content:add {
        type = ui.TYPE.Image,
        props = {
            alpha = 0.5,
            color = util.color.hex('910601'),
            relativePosition = v2(0.7, 0.8),
            relativeSize = v2(0.2, 0.15),
            resource = ui.texture { path = 'white' },
        },
    }
    content:add {
        template = templates.textNormal,
        props = {
            anchor = v2(1, 0.5),
            relativePosition = v2(0.65, 0.35),
            text = 'x3.0',
        },
    }
    content:add {
        template = templates.textNormal,
        props = {
            anchor = v2(1, 0.5),
            relativePosition = v2(0.65, 0.8),
            text = 'x0.3',
        },
    }
    content:add {
        content = ui.content { borders(true) },
        props = {
            relativePosition = v2(0.7, 0.2),
            relativeSize = v2(0.2, 0.75),
        },
    }
    local lineRelativePosition = 0.2 + 0.75 * (1 - skillAdvancementDifficultyFraction())
    content:add {
        name = 'difficulty_line',
        type = ui.TYPE.Image,
        props = {
            color = rgb(0.5, 0.5, 0.5),
            anchor = v2(0, 0.5),
            relativePosition = v2(0.68, lineRelativePosition),
            relativeSize = v2(0.24, 0.01),
            resource = ui.texture { path = 'white' },
        },
    }
    return {
        name = 'second_column',
        content = content,
        props = {
            relativePosition = v2(0.49, 0),
            relativeSize = v2(0.25, 1),
        },
    }
end

-- local function updateHitPointsText()
--     local text = lookupLayout(mainElement.layout, {'hitPoints', 'boxedHitPoints', 'flex', '1'})
--     text.props.text = tostring(specials.maxHp)
-- end

local function changeHitPoints(_: number)
    ui.showMessage('Changing hit points is not supported yet')

    -- if specials.maxHp == math.max(-30, math.min(30, specials.maxHp + diff)) then return end
    -- specials.maxHp = specials.maxHp + diff
    -- updateHitPointsText()
    -- updateDifficultyLine()
    -- mainElement:update()
end

local function hitPoint(): ui.Layout
    local content = ui.content {}

    content:add(background {})
    content:add(borders(true))
    content:add(textLines {
        lines = {'MAX', 'HIT POINTS', 'PER LEVEL'},
        relativePosition = v2(0.1, 0.01),
        relativeSize = v2(0.8, 0.49),
    })
    content:add(TextButton:new {
        lines = {'+'},
        events = {
            focusChange = function() mainElement:update() end,
            mouseClick = function() changeHitPoints(1) end,
        },
        props = {
            relativePosition = v2(0.1, 0.5),
            relativeSize = v2(0.1, 0.2),
        }
    }:layout())
    content:add(TextButton:new {
        lines = {'-'},
        events = {
            focusChange = function() mainElement:update() end,
            mouseClick = function() changeHitPoints(-1) end,
        },
        props = {
            relativePosition = v2(0.1, 0.7),
            relativeSize = v2(0.1, 0.2),
        }
    }:layout())
    content:add {
        name = 'boxedHitPoints',
        content = ui.content {
            borders(false),
            textLines { lines = { tostring(specials.maxHp) } },
        },
        props = {
            relativePosition = v2(0.3, 0.5),
            relativeSize = v2(0.6, 0.4),
        },
    }
    return {
        name = 'hitPoints',
        content = content,
        props = {
            relativePosition = v2(0.75, 0),
            relativeSize = v2(0.25, 0.32),
        },
    }
end

local function createEditElement(availableSpecials: {Special}, add: function(Special))
    destroyMainElement()
    local names = {}
    for _, special in ipairs(availableSpecials) do
        table.insert(names, special.name .. ' [' .. tostring(special.cost) .. ' points]')
    end
    local scrollable: ScrollableTextLines
    scrollable = ScrollableTextLines:new {
        lines = names,
        events = {
            mouseDoubleClick = function(i: number)
                    add(availableSpecials[i as integer])
                    destroyEditElement()
                    createMainElement()
                end,
            onChange = function(_: number) editElement:update() end,
        },
        props = {
            relativePosition = v2(0.05, 0.05),
            relativeSize = v2(0.9, 0.7),
        },
    }
    editElementChangeSelection = function(offset: integer)
        -- TODO: this should be a method of ScrollableTextLines
        local newCurrent = scrollable.scrollbar.current + offset
        scrollable.scrollbar:setCurrent(newCurrent)
        scrollable:update()
        scrollable.options.events.onChange(newCurrent)
    end
    local content = ui.content {}
    content:add(background {})
    content:add(borders(true))
    content:add(scrollable:layout())
    content:add(TextButton:new {
        lines = {'EXIT'},
        backgroundOptions = {
            color = rgb(0.1, 0, 0),
        },
        events = {
            focusChange = function() editElement:update() end,
            mouseClick = function()
                destroyEditElement()
                createMainElement()
            end,
        },
        props = {
            relativePosition = v2(0.8, 0.8),
            relativeSize = v2(0.15, 0.15),
        }
    }:layout())
    editElement = ui.create {
        layer = 'Windows',
        content = content,
        props = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
            relativeSize = v2(0.5, 0.5),
        },
    }
    I.UI.setMode('Interface', {windows = {}})
end

local function openAddAdvantagesWindow()
    createEditElement(specials:availableAdvantages(), function(a: Special) table.insert(specials.advantages, a) end)
end

local function openAddDisadvantagesWindow()
    createEditElement(specials:availableDisadvantages(), function(a: Special) table.insert(specials.disadvantages, a) end)
end

local function editSpecialAdvantagesButton(): ui.Layout
    return TextButton:new {
        lines = {'ADD', 'SPECIAL', 'ADVANTAGES'},
        backgroundOptions = {},
        events = {
            focusChange = function() mainElement:update() end,
            mouseClick = openAddAdvantagesWindow,
        },
        props = {
            relativePosition = v2(0.75, 0.33),
            relativeSize = v2(0.25, 0.16),
        },
    }:layout()
end

local function editSpecialDisadvantagesButton(): ui.Layout
    return TextButton:new {
        lines = {'ADD', 'SPECIAL', 'DISADVANTAGES'},
        backgroundOptions = {},
        events = {
            focusChange = function() mainElement:update() end,
            mouseClick = openAddDisadvantagesWindow,
        },
        props = {
            relativePosition = v2(0.75, 0.50),
            relativeSize = v2(0.25, 0.16),
        },
    }:layout()
end

local function createReputationElement()
    ui.showMessage('Changing reputation is not yet implemented!')
    return
    -- destroyMainElement()
    -- local content = ui.content {}
    -- content:add(background {})
    -- content:add(borders(true))
    -- local flexContent = ui.content {}
    -- local badColor = util.color.hex('a80000')
    -- local goodColor = util.color.hex('6da33b')
    -- local costLabel = {
    --     template = templates.textNormal,
    --     props = {
    --         relativePosition = v2(0.3, 0.9),
    --         text = 'cost: 0',
    --     },
    -- }
    -- local cost: number = 0
    -- local function modCost(offset: number)
    --     cost = cost + offset
    --     costLabel.props.text = 'cost: ' .. tostring(cost)
    -- end
    -- for _, factionId in ipairs({
    --     'redoran',
    --     'hlaalu',
    --     'telvanni',
    --     'thieves guild',
    --     'fighters guild',
    --     'mages guild',
    --     'temple',
    --     'imperial cult',
    --     'camonna tong',
    --     'morag tong',
    --     'ashlanders',
    --     'blades',
    --     'imperial legion',
    --     'east empire company',
    -- }) do
    --     local faction = (core.factions.records as {string:core.FactionRecord})[factionId]
    --     assert(faction)
    --     specials.reputation[faction.id] = specials.reputation[faction.id] or 0
    --     local badButton: TextButton
    --     local neutralButton: TextButton
    --     local goodButton: TextButton
    --     badButton = TextButton:new {
    --         lines = {'BAD'},
    --         normalTextColor = specials.reputation[faction.id] < 0 and badColor or sandColor,
    --         events = {
    --             focusGain = function() end,
    --             focusLoss = function() end,
    --             focusChange = function() reputationElement:update() end,
    --             mouseClick = function()
    --                 if specials.reputation[faction.id] < 0 then return end
    --                 local other = specials.reputation[faction.id] > 0 and goodButton or neutralButton
    --                 modCost(specials.reputation[faction.id] > 0 and -reputationCost*2 or -reputationCost)
    --                 specials.reputation[faction.id] = -20
    --                 other:changeTextColor(sandColor)
    --                 badButton:changeTextColor(badColor)
    --                 reputationElement:update()
    --             end,
    --         },
    --         props = {
    --             relativeSize = v2(0.19, 0),
    --             size = v2(0, templates.textNormal.props.textSize as number + 4),
    --         },
    --     }
    --     neutralButton = TextButton:new {
    --         lines = {'NEUTRAL'},
    --         normalTextColor = specials.reputation[faction.id] == 0 and lightSandColor or sandColor,
    --         events = {
    --             focusGain = function() end,
    --             focusLoss = function() end,
    --             focusChange = function() reputationElement:update() end,
    --             mouseClick = function()
    --                 if specials.reputation[faction.id] == 0 then return end
    --                 local other = specials.reputation[faction.id] < 0 and badButton or goodButton
    --                 modCost(specials.reputation[faction.id] < 0 and reputationCost or -reputationCost)
    --                 specials.reputation[faction.id] = 0
    --                 other:changeTextColor(sandColor)
    --                 neutralButton:changeTextColor(lightSandColor)
    --                 reputationElement:update()
    --             end,
    --         },
    --         props = {
    --             relativeSize = v2(0.19, 0),
    --             size = v2(0, templates.textNormal.props.textSize as number + 4),
    --         },
    --     }
    --     goodButton = TextButton:new {
    --         lines = {'GOOD'},
    --         normalTextColor = specials.reputation[faction.id] > 0 and goodColor or sandColor,
    --         events = {
    --             focusGain = function() end,
    --             focusLoss = function() end,
    --             focusChange = function() reputationElement:update() end,
    --             mouseClick = function()
    --                 if specials.reputation[faction.id] > 0 then return end
    --                 local other = specials.reputation[faction.id] < 0 and badButton or neutralButton
    --                 modCost(specials.reputation[faction.id] < 0 and reputationCost*2 or reputationCost)
    --                 specials.reputation[faction.id] = 20
    --                 other:changeTextColor(sandColor)
    --                 goodButton:changeTextColor(goodColor)
    --                 reputationElement:update()
    --             end,
    --         },
    --         props = {
    --             relativeSize = v2(0.19, 0),
    --             size = v2(0, templates.textNormal.props.textSize as number + 4),
    --         },
    --     }
    --     flexContent:add {
    --         type = ui.TYPE.Flex,
    --         content = ui.content {
    --             {
    --                 template = templates.textNormal,
    --                 props = {
    --                     autoSize = false,
    --                     text = faction.name,
    --                     relativeSize = v2(0.4, 0),
    --                     size = v2(0, templates.textNormal.props.textSize as number),
    --                 },
    --             },
    --             badButton:layout(),
    --             neutralButton:layout(),
    --             goodButton:layout(),
    --         },
    --         props = {
    --             -- align = ui.ALIGNMENT.Center,
    --             -- arrange = ui.ALIGNMENT.Center,
    --             autoSize = false,
    --             horizontal = true,
    --             relativeSize = v2(1, 0),
    --             size = v2(0, templates.textNormal.props.textSize as number + 6),
    --         }
    --     }
    -- end

    -- content:add {
    --     type = ui.TYPE.Flex,
    --     content = flexContent,
    --     props = {
    --         autoSize = false,
    --         relativePosition = v2(0.05, 0.05),
    --         relativeSize = v2(0.9, 0.8),
    --     },
    -- }

    -- content:add(costLabel)

    -- content:add(TextButton:new {
    --     lines = {'EXIT'},
    --     events = {
    --         focusChange = function() reputationElement:update() end,
    --         mouseClick = function()
    --             destroyReputationElement()
    --             createMainElement()
    --         end,
    --     },
    --     props = {
    --         relativePosition = v2(0.78, 0.88),
    --         relativeSize = v2(0.2, 0.1),
    --     },
    -- }:layout())
    -- reputationElement = ui.create {
    --     layer = 'Windows',
    --     content = content,
    --     props = {
    --         anchor = v2(0.5, 0.5),
    --         relativePosition = v2(0.5, 0.5),
    --         relativeSize = v2(0.6, 0.8),
    --     },
    -- }
    -- I.UI.setMode('Interface', {windows = {}})
end

local function editReputationButton(): ui.Layout
    return TextButton:new {
        lines = {'EDIT', 'REPUTATION'},
        backgroundOptions = {},
        events = {
            focusChange = function() mainElement:update() end,
            mouseClick = createReputationElement,
        },
        props = {
            relativePosition = v2(0.75, 0.67),
            relativeSize = v2(0.25, 0.16),
        },
    }:layout()
end

local function calculateSpecialsSkillMultiplier(cost: number): number
    if cost >= 0 then
        return 1 + (0.3-1)/30 * cost
    else
        return 3 + (1-3)/30 * (cost+30)
    end
end

local function isSkillGainMultiplierEnabled(): boolean
    return settings:get('enable_special_skill_progression_modifier') as boolean
end

I.SkillProgression.addSkillUsedHandler(function(_, params: table): boolean
    local multiplier = isSkillGainMultiplierEnabled() and 1 or specialsSkillMultiplier
    params.skillGain = params.skillGain as number * multiplier
    return true
end)

-- TODO: cannot do this yet
-- local maxHpPerLevel: number = 0
-- local hpPerLevel: {number:number} = {}
-- local previousLevel: number = 0

-- local function onUpdate(dt: number)
--     if maxHpPerLevel == 0 then return end
--     local level = types.Actor.stats.level(self).current
--     if Actor.activeSpells(self):isSpellActive('special_healthy') and previousLevel >= level then return end
--     local diff = level - previousLevel
--     previousLevel = level
--     local totalHpBonus: number = 0
--     for currLevel = 1, diff do
--         if hpPerLevel[currLevel] == nil then
--             -- use dt as random number
--             local rnd = dt % 1.0
--             hpPerLevel[currLevel] = maxHpPerLevel / 2 + (maxHpPerLevel / 2) * rnd
--         end
--         totalHpBonus = totalHpBonus + hpPerLevel[currLevel]
--     end
--     if Actor.activeSpells(self):isSpellActive('special_healthy') then
--         Actor.activeSpells(self):remove('special_healthy')
--     end
--     print('Setting the special health bonus to ' .. tostring(totalHpBonus))
--     Actor.activeSpells(self):add {
--     }
-- end

local function removeExistingSpecials()
    for _, spell in ipairs(types.Actor.spells(self) as {core.Spell}) do
        if advantagesByAbilityId[spell.id] or disadvantagesByAbilityId[spell.id] then
            print('Removing spell ' .. spell.id)
            types.Actor.spells(self):remove(spell)
        end
    end
end

local function applySpecials()
    removeExistingSpecials()

    print('Applying specials abilities')
    nightlys = {}
    for _, advantage in ipairs(specials.advantages) do
        if advantage.abilityId then
            types.Actor.spells(self):add(advantage.abilityId)
        end
        if advantage.abilityIdAtNight then
            table.insert(nightlys, advantage)
        end
        if advantage.abilityIdWhenInside or advantage.abilityIdWhenOutside then
            table.insert(insidesOutsides, advantage)
        end
    end
    phobias = {}
    for _, disadvantage in ipairs(specials.disadvantages) do
        if disadvantage.abilityId then
            types.Actor.spells(self):add(disadvantage.abilityId)
        end
        if disadvantage.abilityIdAtNight then
            table.insert(nightlys, disadvantage)
        end
        if disadvantage.abilityIdWhenInside or disadvantage.abilityIdWhenOutside then
            table.insert(insidesOutsides, disadvantage)
        end

        local phobiaOf = disadvantage.phobiaOf
        if phobiaOf is {string} then
            table.insert(phobias, disadvantage)
        end
    end

    specialsSkillMultiplier = calculateSpecialsSkillMultiplier(specials:cost())
    print('Applying specials skill multiplier ' .. tostring(specialsSkillMultiplier))


end

local function createApplyElement()
    local content = ui.content {}
    content:add(background {})
    content:add(borders(true))
    content:add {
        content = ui.content { borders(false) },
        props = {
            relativePosition = v2(0.05, 0.05),
            relativeSize = v2(0.9, 0.5),
        }
    }
    local specialsCost = specials:cost()
    local text: string
    local enableApplyButton: boolean
    if specialsCost > maxValidDifficultyPoints or specialsCost < -maxValidDifficultyPoints then
        text = 'The total cost of the special advantages and disadvantages is ' .. tostring(specialsCost) ..
               ' which is outside the valid range [-' .. tostring(maxValidDifficultyPoints) .. ','..
               tostring(maxValidDifficultyPoints) .. ']. Do you want to exit or go back to editing?'
        enableApplyButton = false
    else
        text = 'Do you want to apply the special advantages and disadvantages, exit without applying them or go back to editing?'
        enableApplyButton = true
    end
    content:add {
        template = templates.textNormal,
        props = {
            autoSize = false,
            text = text,
            multiline = true,
            wordWrap = true,
            relativePosition = v2(0.1, 0.1),
            relativeSize = v2(0.8, 0.4),
        }
    }
    if enableApplyButton then
        content:add(TextButton:new {
            lines = {'APPLY'},
            backgroundOptions = {
                color = rgb(0.1, 0, 0),
            },
            events = {
                focusChange = function() applyElement:update() end,
                mouseClick = function()
                        applySpecials()
                        destroyApplyElement()
                    end,
            },
            props = {
                relativePosition = v2(0.1, 0.6),
                relativeSize = v2(0.2, 0.3),
            },
        }:layout())
    end
    content:add(TextButton:new {
        lines = {'EXIT'},
        backgroundOptions = {
            color = rgb(0.1, 0, 0),
        },
        events = {
            focusChange = function() applyElement:update() end,
            mouseClick = destroyApplyElement,
        },
        props = {
            relativePosition = v2(0.4, 0.6),
            relativeSize = v2(0.2, 0.3),
        },
    }:layout())
    content:add(TextButton:new {
        lines = {'GO BACK'},
        events = {
            focusChange = function() applyElement:update() end,
            mouseClick = function()
                    destroyApplyElement()
                    createMainElement()
                end,
        },
        props = {
            relativePosition = v2(0.7, 0.6),
            relativeSize = v2(0.2, 0.3),
        },
    }:layout())
    applyElement = ui.create {
        layer = 'Windows',
        content = content,
        props = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
            relativeSize = v2(0.4, 0.3),
        }
    }
    I.UI.setMode('Interface', {windows = {}})
end

local function exitButton(): ui.Layout
    return TextButton:new {
        lines = {'EXIT'},
        backgroundOptions = {
            color = rgb(0.1, 0, 0),
        },
        events = {
            focusChange = function() mainElement:update() end,
            mouseClick = function()
                destroyMainElement()
                createApplyElement()
            end,
        },
        props = {
            relativePosition = v2(0.825, 0.86),
            relativeSize = v2(0.10, 0.12),
        },
    }:layout()
end

createMainElement = function()
    mainElement = ui.create {
        layer = 'Windows',
        name = 'outer',
        type = ui.TYPE.Widget,
        props = {
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, 0.5),
            relativeSize = v2(0.7, 0.8),
        },
        content = ui.content {
            firstColumn(),
            secondColumn(),
            hitPoint(),
            editSpecialAdvantagesButton(),
            editSpecialDisadvantagesButton(),
            editReputationButton(),
            exitButton(),
        },
    }
    I.UI.setMode('Interface', {windows = {}})
end

local function getOpenSpecialMainElementKey(): string
    return settings:get('open_special_main_element_key') as string
end

local function loadPlayerSpecials()
    specials = AdvantagesDisadvantages:new()
    for _, spell in ipairs(types.Actor.spells(self) as {core.Spell}) do
        local advantage = advantagesByAbilityId[spell.id]
        if advantage then
            table.insert(specials.advantages, advantage)
        else
            local disadvantage = disadvantagesByAbilityId[spell.id]
            if disadvantage then
                table.insert(specials.disadvantages, disadvantage)
            end
        end
    end
    for _, phobia in ipairs(phobias) do
        table.insert(specials.disadvantages, phobia)
    end
end

local function onKeyPress(key: input.KeyboardEvent)
    if not mainElement and input.getKeyName(key.code):lower() == getOpenSpecialMainElementKey():lower() then
        loadPlayerSpecials()
        createMainElement()
    elseif key.code == input.KEY.Escape then
        destroyMainElement()
        destroyEditElement()
        destroyApplyElement()
        destroyReputationElement()
    elseif editElement and key.code == input.KEY.UpArrow then
        editElementChangeSelection(-1)
    elseif editElement and key.code == input.KEY.DownArrow then
        editElementChangeSelection(1)
    elseif editElement and key.code == input.KEY.Enter then
        -- TODO
    elseif key.code == input.KEY.Y then

    end
end

local function onMouseWheel(vertical: integer, _)
    if not editElement or not onMouseWheel then return end
    editElementChangeSelection(-vertical)
end

local applyReputationChangesLastRun: number = 100000000
local applyReputationChangesEvery: number = 5
local function applyReputationChanges(dt: number)
    applyReputationChangesLastRun = applyReputationChangesLastRun + dt
    if applyReputationChangesLastRun < applyReputationChangesEvery then return end
    applyReputationChangesLastRun = 0
    for _, actor in ipairs(nearby.actors) do
        if not types.NPC.objectIsInstance(actor) then return end
        for _, factionId in ipairs(types.NPC.getFactions(actor)) do
            if specials.reputation[factionId] then
                actor:sendEvent('SpecialModifyDisposition', {toward=self.id, modifier=specials.reputation[factionId]})
                break
            end
        end
    end
end

local function applyNightlys(dt: number)
    nightlysTimeSinceCheck = nightlysTimeSinceCheck + dt
    if nightlysTimeSinceCheck < nightlysCheckEvery then return end
    nightlysTimeSinceCheck = 0
    local hour = core.getGameTime() % time.day as number
    local isNight = hour < 21600 or hour >= 64800
    for _, special in ipairs(nightlys) do
        if isNight and not (types.Actor.spells(self) as {string:core.Spell})[special.abilityIdAtNight] then
            types.Actor.spells(self):add(special.abilityIdAtNight)
        elseif not isNight and (types.Actor.spells(self) as {string:core.Spell})[special.abilityIdAtNight] then
            types.Actor.spells(self):remove(special.abilityIdAtNight)
        end
    end
end

local function applyInsidesOutsides(dt: number)
    insidesTimeSinceCheck = insidesTimeSinceCheck + dt
    if insidesTimeSinceCheck < insidesCheckEvery then return end
    insidesTimeSinceCheck = 0
    for _, special in ipairs(insidesOutsides) do
        if self.cell.isExterior then
            if special.abilityIdWhenInside and (types.Actor.spells(self) as {string:core.Spell})[special.abilityIdWhenInside] then
                types.Actor.spells(self):remove(special.abilityIdWhenInside)
            end
            if special.abilityIdWhenOutside and not (types.Actor.spells(self) as {string:core.Spell})[special.abilityIdWhenOutside] then
                types.Actor.spells(self):add(special.abilityIdWhenOutside)
            end
        else
            if special.abilityIdWhenInside and not (types.Actor.spells(self) as {string:core.Spell})[special.abilityIdWhenInside] then
                types.Actor.spells(self):add(special.abilityIdWhenInside)
            end
            if special.abilityIdWhenOutside and (types.Actor.spells(self) as {string:core.Spell})[special.abilityIdWhenOutside] then
                types.Actor.spells(self):remove(special.abilityIdWhenOutside)
            end
        end
    end
end

local function onUpdate(dt: number)
    applyReputationChanges(dt)
    applyNightlys(dt)
    applyInsidesOutsides(dt)

    if not phobias then return end

    if types.Actor.activeSpells(self):isSpellActive('special_phobia') then
        phobiaTimeSinceLastTriggerred = phobiaTimeSinceLastTriggerred + dt
        -- phobia last between 10s and 60s depending on the wisdom
        local willpower = types.Actor.stats.attributes.willpower(self).modified
        local duration = math.max(10, 60 - 0.5 * willpower)
        -- print('phobiaTimeSinceLastTriggerred:' .. tostring(phobiaTimeSinceLastTriggerred) .. ' duration:' .. tostring(duration))
        if phobiaTimeSinceLastTriggerred >= duration then
            -- print('Removing special_phobia')
            types.Actor.activeSpells(self):remove('special_phobia')
        end
    else
        -- limit how many times the checks are done
        phobiaTimeSinceCheck = phobiaTimeSinceCheck + dt
        if phobiaTimeSinceCheck < phobiaCheckEvery then return end
        phobiaTimeSinceCheck = 0

        local res = nearby.castRay(camera.getPosition(), camera.getPosition() + camera.viewportToWorldVector(v2(0.5, 0.5)) * 2048, {ignore=self})
        if res and res.hitObject and types.Creature.objectIsInstance(res.hitObject) then
            local creature = res.hitObject as types.Creature
            for _, special in ipairs(phobias) do
                for _, phobia in ipairs(special.phobiaOf or {}) do
                    if string.find(types.Creature.record(creature).id:lower(), phobia) then
                        phobiaTimeSinceLastTriggerred = 0
                        print('is spell active:' .. tostring(types.Actor.activeSpells(self):isSpellActive('special_phobia')))
                        if not types.Actor.activeSpells(self):isSpellActive('special_phobia') then
                            ui.showMessage(special.name .. ' triggered by ' .. types.Creature.record(creature).name)
                            types.Actor.activeSpells(self):add {
                                id = 'special_phobia',
                                name = 'Phobia',
                                effects = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26 },
                                ignoreResistances = true,
                                ignoreSpellAbsorption = true,
                                ignoreReflect = true,
                                stackable = false,
                                temporary = true,
                            }
                        end
                    end
                end
            end
        end
    end
end

local function onSave(): table
    return {
        insidesOutsides = insidesOutsides,
        nightlys = nightlys,
        phobias = phobias,
        reputation = specials.reputation,
        specialsSkillMultiplier = specialsSkillMultiplier,
    }
end

local function onLoad(data: table)
    if data.insidesOutsides then
        insidesOutsides = insidesOutsides as {Special}
    end
    if data.nightlys then
        nightlys = data.nightlys as {Special}
    end
    if data.specialsSkillMultiplier and data.specialsSkillMultiplier ~= 1 then
        specialsSkillMultiplier = data.specialsSkillMultiplier as number
        print('Applying specials skill multiplier ' .. tostring(specialsSkillMultiplier))
    end
    if data.phobias then
        phobias = data.phobias as {Special}
    end
    if data.reputation then
        specials.reputation = data.reputation as {string:number}
    end
    
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress,
        onUpdate = onUpdate,
        onMouseWheel = onMouseWheel,
        onSave = onSave,
        onLoad = onLoad,
    },
}