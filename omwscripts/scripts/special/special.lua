local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local utilAux = require('openmw_aux.util')
local _conf = require('scripts.special.conf')
local _widgets = require('scripts.special.widgets')
local _ = require('scripts.special.settings')

local rgb = util.color.rgb
local v2 = util.vector2
local V2 = util.Vector2

local specials = nil
local mainElement = nil
local createMainElement = nil
local editElement = nil
local editElementChangeSelection = nil
local applyElement = nil

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



local function skillAdvancementDifficultyFraction()
   local difficulty = math.max(-maxDifficultyPoints, math.min(maxDifficultyPoints, specials:cost()))
   return (difficulty + maxDifficultyPoints) / (maxDifficultyPoints * 2)
end

local function updateDifficultyLine()
   local lineRelativePosition = 0.2 + 0.75 * (1 - skillAdvancementDifficultyFraction())
   local line = lookupLayout(mainElement.layout, { 'second_column', 'difficulty_line' })
   local linePosition = line.props.relativePosition
   line.props.relativePosition = v2(linePosition.x, lineRelativePosition)
end

local function firstColumn()
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add(textLines({
      lines = { 'ADVANTAGES/DISADVANTAGES' },
      relativeSize = v2(1, 0.08),
   }))
   content:add({
      template = I.MWUI.templates.horizontalLineThick,
      props = {
         anchor = v2(0, 0.5),
         relativePosition = v2(0, 0.08),
      },
   })
   local lines = {}
   for _, advantage in ipairs(specials.advantages) do
      table.insert(lines, advantage.name .. ' [' .. tostring(advantage.cost) .. ' points]')
   end
   for _, disadvantage in ipairs(specials.disadvantages) do
      table.insert(lines, disadvantage.name .. ' [' .. tostring(disadvantage.cost) .. ' points]')
   end
   local scrollableTextLine
   scrollableTextLine = ScrollableTextLines:new({
      lines = lines,
      events = {
         mouseDoubleClick = function(i)
            if i <= #specials.advantages then
               table.remove(specials.advantages, i)
            else
               table.remove(specials.disadvantages, i - #specials.advantages)
            end
            scrollableTextLine:remove(i)
            updateDifficultyLine()
            mainElement:update()
         end,
         onChange = function(_) mainElement:update() end,
      },
      props = {
         relativePosition = v2(0.05, 0.1),
         relativeSize = v2(0.9, 0.85),
         scrollbarRelativeSizeWidth = 0.05,
      },
   })
   content:add(scrollableTextLine:layout())
   return {
      content = content,
      props = {
         relativeSize = v2(0.48, 1),
      },
   }
end

local function secondColumn()
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add(textLines({
      lines = { 'SKILL', 'ADVANCEMENT', 'FOR CLASS' },
      relativeSize = v2(1, 0.15),
   }))
   content:add({
      template = I.MWUI.templates.horizontalLineThick,
      props = { relativePosition = v2(0, 0.15) },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0),
         relativePosition = v2(0.65, 0.2),
         text = 'DIFFICULT',
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0.5),
         relativePosition = v2(0.65, 0.575),
         text = 'AVERAGE',
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 1),
         relativePosition = v2(0.65, 0.95),
         text = 'EASY',
      },
   })
   content:add({
      type = ui.TYPE.Image,
      props = {
         alpha = 0.5,
         color = util.color.hex('910601'),
         relativePosition = v2(0.7, 0.2),
         relativeSize = v2(0.2, 0.15),
         resource = ui.texture({ path = 'white' }),
      },
   })
   content:add({
      type = ui.TYPE.Image,
      props = {
         alpha = 0.5,
         color = util.color.hex('910601'),
         relativePosition = v2(0.7, 0.8),
         relativeSize = v2(0.2, 0.15),
         resource = ui.texture({ path = 'white' }),
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0.5),
         relativePosition = v2(0.65, 0.35),
         text = 'x3.0',
      },
   })
   content:add({
      template = templates.textNormal,
      props = {
         anchor = v2(1, 0.5),
         relativePosition = v2(0.65, 0.8),
         text = 'x0.3',
      },
   })
   content:add({
      content = ui.content({ borders(true) }),
      props = {
         relativePosition = v2(0.7, 0.2),
         relativeSize = v2(0.2, 0.75),
      },
   })
   local lineRelativePosition = 0.2 + 0.75 * (1 - skillAdvancementDifficultyFraction())
   content:add({
      name = 'difficulty_line',
      type = ui.TYPE.Image,
      props = {
         color = rgb(0.5, 0.5, 0.5),
         anchor = v2(0, 0.5),
         relativePosition = v2(0.68, lineRelativePosition),
         relativeSize = v2(0.24, 0.01),
         resource = ui.texture({ path = 'white' }),
      },
   })
   return {
      name = 'second_column',
      content = content,
      props = {
         relativePosition = v2(0.49, 0),
         relativeSize = v2(0.25, 1),
      },
   }
end

local function updateHitPointsText()
   local text = lookupLayout(mainElement.layout, { 'hitPoints', 'boxedHitPoints', 'flex', '1' })
   text.props.text = tostring(specials.maxHp)
end

local function changeHitPoints(diff)
   ui.showMessage('Changing hit points is not supported yet')






end

local function hitPoint()
   local content = ui.content({})

   content:add(background({}))
   content:add(borders(true))
   content:add(textLines({
      lines = { 'MAX', 'HIT POINTS', 'PER LEVEL' },
      relativePosition = v2(0.1, 0.01),
      relativeSize = v2(0.8, 0.49),
   }))
   content:add(textButton({
      lines = { '+' },
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = function() changeHitPoints(1) end,
      },
      props = {
         relativePosition = v2(0.1, 0.5),
         relativeSize = v2(0.1, 0.2),
      },
   }))
   content:add(textButton({
      lines = { '-' },
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = function() changeHitPoints(-1) end,
      },
      props = {
         relativePosition = v2(0.1, 0.7),
         relativeSize = v2(0.1, 0.2),
      },
   }))
   content:add({
      name = 'boxedHitPoints',
      content = ui.content({
         borders(false),
         textLines({ lines = { tostring(specials.maxHp) } }),
      }),
      props = {
         relativePosition = v2(0.3, 0.5),
         relativeSize = v2(0.6, 0.4),
      },
   })
   return {
      name = 'hitPoints',
      content = content,
      props = {
         relativePosition = v2(0.75, 0),
         relativeSize = v2(0.25, 0.32),
      },
   }
end

local function createEditElement(availableSpecials, add)
   destroyMainElement()
   local names = {}
   for _, special in ipairs(availableSpecials) do
      table.insert(names, special.name .. ' [' .. tostring(special.cost) .. ' points]')
   end
   local scrollable
   scrollable = ScrollableTextLines:new({
      lines = names,
      events = {
         mouseDoubleClick = function(i)
            add(availableSpecials[i])
            destroyEditElement()
            createMainElement()
         end,
         onChange = function(_) editElement:update() end,
      },
      props = {
         relativePosition = v2(0.05, 0.05),
         relativeSize = v2(0.9, 0.7),
      },
   })
   editElementChangeSelection = function(offset)

      local newCurrent = scrollable.scrollbar.current + offset
      scrollable.scrollbar:setCurrent(newCurrent)
      scrollable:update()
      scrollable.options.events.onChange(newCurrent)
   end
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add(scrollable:layout())
   content:add(textButton({
      lines = { 'EXIT' },
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
      },
   }))
   editElement = ui.create({
      layer = 'Windows',
      content = content,
      props = {
         anchor = v2(0.5, 0.5),
         relativePosition = v2(0.5, 0.5),
         relativeSize = v2(0.5, 0.5),
      },
   })
   I.UI.setMode('Interface', { windows = {} })
end

local function openAddAdvantagesWindow()
   createEditElement(specials:availableAdvantages(), function(a) table.insert(specials.advantages, a) end)
end

local function openAddDisadvantagesWindow()
   createEditElement(specials:availableDisadvantages(), function(a) table.insert(specials.disadvantages, a) end)
end

local function editSpecialAdvantagesButton()
   return textButton({
      lines = { 'ADD', 'SPECIAL', 'ADVANTAGES' },
      backgroundOptions = {},
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = openAddAdvantagesWindow,
      },
      props = {
         relativePosition = v2(0.75, 0.33),
         relativeSize = v2(0.25, 0.16),
      },
   })
end

local function editSpecialDisadvantagesButton()
   return textButton({
      lines = { 'ADD', 'SPECIAL', 'DISADVANTAGES' },
      backgroundOptions = {},
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = openAddDisadvantagesWindow,
      },
      props = {
         relativePosition = v2(0.75, 0.50),
         relativeSize = v2(0.25, 0.16),
      },
   })
end

local function editReputationButton()
   return textButton({
      lines = { 'EDIT', 'REPUTATION' },
      backgroundOptions = {},
      events = {
         focusChange = function() mainElement:update() end,
         mouseClick = function() ui.showMessage('The "Edit Reputation" functionality is not supported yet') end,
      },
      props = {
         relativePosition = v2(0.75, 0.67),
         relativeSize = v2(0.25, 0.16),
      },
   })
end

local function calculateSpecialsSkillMultiplier(cost)
   if cost >= 0 then
      return 1 + (0.3 - 1) / 30 * cost
   else
      return 3 + (1 - 3) / 30 * (cost + 30)
   end
end

local specialsSkillMultiplier = 1

local function isSkillGainMultiplierEnabled()
   return settings:get('enable_special_skill_progression_modifier')
end

I.SkillProgression.addSkillUsedHandler(function(_, params)
   local multiplier = isSkillGainMultiplierEnabled() and 1 or specialsSkillMultiplier
   params.skillGain = params.skillGain * multiplier
   return true
end)





























local function removeExistingSpecials()
   for _, spell in ipairs(types.Actor.spells(self)) do
      if advantagesByAbilityId[spell.id] or disadvantagesByAbilityId[spell.id] then
         print('Removing spell ' .. spell.id)
         types.Actor.spells(self):remove(spell)
      end
   end
end

local function applySpecials()
   removeExistingSpecials()

   print('Applying specials abilities')
   for _, advantage in ipairs(specials.advantages) do
      if advantage.abilityId then
         types.Actor.spells(self):add(advantage.abilityId)
      end
   end
   for _, disadvantage in ipairs(specials.disadvantages) do
      if disadvantage.abilityId then
         types.Actor.spells(self):add(disadvantage.abilityId)
      end
   end

   specialsSkillMultiplier = calculateSpecialsSkillMultiplier(specials:cost())
   print('Applying specials skill multiplier ' .. tostring(specialsSkillMultiplier))


end

local function createApplyElement()
   local content = ui.content({})
   content:add(background({}))
   content:add(borders(true))
   content:add({
      content = ui.content({ borders(false) }),
      props = {
         relativePosition = v2(0.05, 0.05),
         relativeSize = v2(0.9, 0.5),
      },
   })
   local specialsCost = specials:cost()
   local text
   local enableApplyButton
   if specialsCost > maxValidDifficultyPoints or specialsCost < -maxValidDifficultyPoints then
      text = 'The total cost of the special advantages and disadvantages is ' .. tostring(specialsCost) ..
      ' which is outside the valid range [-' .. tostring(maxValidDifficultyPoints) .. ',' ..
      tostring(maxValidDifficultyPoints) .. ']. Do you want to exit or go back to editing?'
      enableApplyButton = false
   else
      text = 'Do you want to apply the special advantages and disadvantages, exit without applying them or go back to editing?'
      enableApplyButton = true
   end
   content:add({
      template = templates.textNormal,
      props = {
         autoSize = false,
         text = text,
         multiline = true,
         wordWrap = true,
         relativePosition = v2(0.1, 0.1),
         relativeSize = v2(0.8, 0.4),
      },
   })
   if enableApplyButton then
      content:add(textButton({
         lines = { 'APPLY' },
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
      }))
   end
   content:add(textButton({
      lines = { 'EXIT' },
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
   }))
   content:add(textButton({
      lines = { 'GO BACK' },
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
   }))
   applyElement = ui.create({
      layer = 'Windows',
      content = content,
      props = {
         anchor = v2(0.5, 0.5),
         relativePosition = v2(0.5, 0.5),
         relativeSize = v2(0.4, 0.3),
      },
   })
   I.UI.setMode('Interface', { windows = {} })
end

local function exitButton()
   return textButton({
      lines = { 'EXIT' },
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
   })
end

createMainElement = function()
   mainElement = ui.create({
      layer = 'Windows',
      name = 'outer',
      type = ui.TYPE.Widget,
      props = {
         anchor = v2(0.5, 0.5),
         relativePosition = v2(0.5, 0.5),
         relativeSize = v2(0.7, 0.8),
      },
      content = ui.content({
         firstColumn(),
         secondColumn(),
         hitPoint(),
         editSpecialAdvantagesButton(),
         editSpecialDisadvantagesButton(),
         editReputationButton(),
         exitButton(),
      }),
   })
   I.UI.setMode('Interface', { windows = {} })
end

local function getOpenSpecialMainElementKey()
   return settings:get('open_special_main_element_key')
end

local function loadPlayerSpecials()
   specials = AdvantagesDisadvantages:new()
   for _, spell in ipairs(types.Actor.spells(self)) do
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
end

local function onKeyPress(key)
   if not mainElement and input.getKeyName(key.code):lower() == getOpenSpecialMainElementKey():lower() then
      loadPlayerSpecials()
      createMainElement()
   elseif key.code == input.KEY.Escape then
      destroyMainElement()
      destroyEditElement()
      destroyApplyElement()
   elseif editElement and key.code == input.KEY.UpArrow then
      editElementChangeSelection(-1)
   elseif editElement and key.code == input.KEY.DownArrow then
      editElementChangeSelection(1)
   elseif editElement and key.code == input.KEY.Enter then

   end
end

local function onMouseWheel(vertical, _)
   if not editElement or not onMouseWheel then return end
   editElementChangeSelection(-vertical)
end

return {
   engineHandlers = {
      onKeyPress = onKeyPress,

      onMouseWheel = onMouseWheel,
   },
}
