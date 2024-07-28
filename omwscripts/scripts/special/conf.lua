local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local core = require('openmw.core')

maxDifficultyPoints = 50
maxPaddingPoints = 20
maxValidDifficultyPoints = maxDifficultyPoints - maxPaddingPoints
reputationCost = 2

Special = {}




















function Special:new(special)
   assert(special)
   local self = setmetatable(special, { __index = Special })
   return self
end

function Special:copy()
   local copy = Special:new()
   copy.id = self.id
   copy.name = self.name
   copy.abilityId = self.abilityId
   copy.abilityIdAtNight = self.abilityIdAtNight
   local phobiaOf = self.phobiaOf
   if type(phobiaOf) == "table" then
      for _, phobia in ipairs(phobiaOf) do
         table.insert(copy.phobiaOf, phobia)
      end
   end
   copy.cost = self.cost
end

advantages = {}
advantagesById = {}
advantagesByAbilityId = {}
disadvantages = {}
disadvantagesById = {}
disadvantagesByAbilityId = {}

local function checkAbilityExists(abilityId)
   if (core.magic.spells.records)[abilityId] == nil then
      error('Ability ' .. abilityId .. ' not found in game! Please load the plugin special.omwaddon.')
   end
end

checkAbilityExists('special_phobia')

local function addSpecial(special)
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

local function percentageToNoun(percentage)
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

local function firstToUpper(str)
   return (str:gsub("^%l", string.upper))
end

local function spacesToUnderscores(str)
   return (str:gsub(" +", "_"))
end

for _, element in ipairs({ 'fire', 'frost', 'shock', 'poison' }) do
   for absoluteCost, absolutePercentage in pairs({ [40] = 100,
[30] = 75,
[20] = 50,
[10] = 25, }) do
      for cost, percentage in pairs({ [absoluteCost] = absolutePercentage,
[-absoluteCost] = -absolutePercentage, }) do
         local noun = percentageToNoun(percentage)
         local id = spacesToUnderscores(noun) .. '_to_' .. element
         local abilityId = 'special_' .. id
         checkAbilityExists(abilityId)
         local name = firstToUpper(noun) .. ' to ' .. firstToUpper(element) .. ' (' .. tostring(percentage) .. '%)'
         addSpecial({ id = id, name = name, abilityId = abilityId, cost = cost })
      end
   end
end

for absoluteCost, absolutePercentage in pairs({ [40] = 75,
[30] = 50,
[20] = 25, }) do
   for cost, percentage in pairs({ [absoluteCost] = absolutePercentage,
[-absoluteCost] = -absolutePercentage, }) do
      local noun = percentageToNoun(percentage)
      local id = spacesToUnderscores(noun) .. '_to_magicka'
      local abilityId = 'special_' .. id
      local name = firstToUpper(noun) .. ' to magicka (' .. tostring(percentage) .. '%)'
      addSpecial({ id = id, name = name, abilityId = abilityId, cost = cost })
   end
end

addSpecial({
   id = 'robust',
   name = 'Robust (+10 End)',
   abilityId = 'special_robust',
   cost = 20,
})

addSpecial({
   id = 'fragile',
   name = 'Fragile (-10 End)',
   abilityId = 'special_fragile',
   cost = -20,
})

addSpecial({
   id = 'strong',
   name = 'Strong (+10 Str)',
   abilityId = 'special_strong',
   cost = 20,
})

addSpecial({
   id = 'weak',
   name = 'Weak (-10 Str)',
   abilityId = 'special_weak',
   cost = -20,
})

addSpecial({
   id = 'agile',
   name = 'Agile (+10 Agi)',
   abilityId = 'special_agile',
   cost = 20,
})

addSpecial({
   id = 'Clumsy',
   name = 'Clumsy (-10 Agi)',
   abilityId = 'special_clumsy',
   cost = -20,
})

addSpecial({
   id = 'fast',
   name = 'Fast (+10 Spe)',
   abilityId = 'special_fast',
   cost = 20,
})

addSpecial({
   id = 'slow',
   name = 'Slow (-10 Spe)',
   abilityId = 'special_slow',
   cost = -20,
})

addSpecial({
   id = 'charismatic',
   name = 'Charismatic (+10 Cha)',
   abilityId = 'special_charismatic',
   cost = 20,
})

addSpecial({
   id = 'uncharismatic',
   name = 'Uncharismatic (-10 Cha)',
   abilityId = 'special_uncharismatic',
   cost = -20,
})

addSpecial({
   id = 'intelligent',
   name = 'Intelligent (+10 Int)',
   abilityId = 'special_intelligent',
   cost = 20,
})

addSpecial({
   id = 'stupid',
   name = 'Stupid (-10 Int)',
   abilityId = 'special_stupid',
   cost = -20,
})

addSpecial({
   id = 'resolute',
   name = 'Resolute (+10 Wil)',
   abilityId = 'special_resolute',
   cost = 20,
})

addSpecial({
   id = 'irresolute',
   name = 'Irresolute (-10 Wil)',
   abilityId = 'special_irresolute',
   cost = -20,
})

addSpecial({
   id = 'lucky',
   name = 'Lucky (+10 Luc)',
   abilityId = 'special_lucky',
   cost = 20,
})

addSpecial({
   id = 'unlucky',
   name = 'Unlucky (-10 Luc)',
   abilityId = 'special_unlucky',
   cost = -20,
})

addSpecial({
   id = 'regenerative',
   name = 'Regenerative (1hp/s)',
   abilityId = 'special_regenerative',
   cost = 20,
})

addSpecial({
   id = 'relentless',
   name = 'Relentless (4fp/s)',
   abilityId = 'special_relentless',
   cost = 20,
})

addSpecial({
   id = 'recharging',
   name = 'Recharging (1mp/s)',
   abilityId = 'special_recharging',
   cost = 20,
})

for _, skill in ipairs({ 'Heavy Armor',
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
'Restoration', }) do
   local idPostfix = spacesToUnderscores(skill:lower())

   local id = 'proficient_in_' .. idPostfix
   addSpecial({
      id = id,
      name = 'Proficient in ' .. skill .. ' (+20)',
      abilityId = 'special_' .. id,
      cost = 20,
   })

   id = 'inept_at_' .. idPostfix
   addSpecial({
      id = id,
      name = 'Inept at ' .. skill .. ' (-100)',
      abilityId = 'special_' .. id,
      cost = -5,
   })
end

addSpecial({
   id = 'shadowborn',
   name = 'Shadowborn (Chameleon 20)',
   abilityId = 'special_shadowborn',
   cost = 20,
})

addSpecial({
   id = 'dodger',
   name = 'Dodger (Sanctuary 20)',
   abilityId = 'special_dodger',
   cost = 20,
})




addSpecial({
   id = 'phobia_of_ash_creatures',
   name = 'Phobia of Ash Creatures (-20 all skills)',
   phobiaOf = { 'ascended_sleeper', 'dagoth', 'ash', 'corprus' },
   cost = -30,
})


for _, beastAndMatch in ipairs({
      { 'alit', { 'alit' } },
      { 'cliff racer', { 'cliff.*racer' } },
      { 'dreugh', { 'dreugh' } },
      { 'guar', { 'guar' } },
      { 'kagouti', { 'kagouti' } },
      { 'mudcrab', { 'mudcrab' } },
      { 'netch', { 'netch' } },
      { 'nix-hound', { 'nix.*hound' } },
      { 'rat', { 'rat' } },
      { 'shalk', { 'shalk' } },
      { 'slaughterfish', { 'slaughterfish' } },
      { 'kwama', { 'kwama', 'scrib' } },
   }) do
   addSpecial({
      id = 'phobia_of_' .. spacesToUnderscores(beastAndMatch[1]),
      name = 'Phobia of ' .. firstToUpper(beastAndMatch[1]) .. ' (-20 all skills)',
      phobiaOf = beastAndMatch[2],
      cost = -2,
   })
end


addSpecial({
   id = 'phobia_of_daedra',
   name = 'Phobia of Daedra (-20 all skills)',
   phobiaOf = { 'atronach', 'clannfear', 'daedroth', 'dremora', 'golden.*saint', 'hunger', 'ogrim', 'scamp', 'winged.*twilight' },
   cost = -40,
})

for _, daedraAndMatch in ipairs({
      { 'atronach', { 'atronach' } },
      { 'clannfear', { 'clannfear' } },
      { 'daedroth', { 'daedroth' } },
      { 'dremora', { 'dremora' } },
      { 'golden saint', { 'golden.*saint' } },
      { 'hunger', { 'hunger' } },
      { 'ogrim', { 'ogrim' } },
      { 'scamp', { 'scamp' } },
      { 'winged twilight', { 'winged.*twilight' } },
   }) do
   addSpecial({
      id = 'phobia_of_' .. spacesToUnderscores(daedraAndMatch[1]),
      name = 'Phobia of ' .. firstToUpper(daedraAndMatch[1]) .. ' (-20 all skills)',
      phobiaOf = daedraAndMatch[2],
      cost = -5,
   })
end


addSpecial({
   id = 'phobia_of_dwemer_constructs',
   name = 'Phobia of Dwemer Constructs (-20 all skills)',
   phobiaOf = { 'centurion' },
   cost = -20,
})


addSpecial({
   id = 'phobia_of_ghosts',
   name = 'Phobia of Ghosts (-20 all skills)',
   phobiaOf = { 'ghost', 'wraith', 'gateway.*haunt', 'ancestor.*guardian', 'ancestor.*wisewoman', 'dahrik.*mezalf' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_boneundead',
   name = 'Phobia of Bone Undead (-20 all skills)',
   phobiaOf = { 'bonelord', 'bonewalker', 'wolf.*bone' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_skeletons',
   name = 'Phobia of Skeletons (-20 all skills)',
   phobiaOf = { 'skeleton', 'worm.*lord' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_liches',
   name = 'Phobia of Liches (-20 all skills)',
   phobiaOf = { 'lich' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_draugr',
   name = 'Phobia of Draugr (-20 all skills)',
   phobiaOf = { 'draugr' },
   cost = -10,
})



addSpecial({
   id = 'night_person',
   name = 'Night Person (+10 AG/IN/WI/CH at night)',
   abilityIdAtNight = 'special_night_person',
   cost = 10,
})

addSpecial({
   id = 'good_natured',
   name = 'Good Natured',
   abilityId = 'special_good_natured',
   cost = 0,
})

addSpecial({
   id = 'small_frame',
   name = 'Small Frame',
   abilityId = 'special_small_frame',
   cost = 0,
})

AdvantagesDisadvantages = {}







function AdvantagesDisadvantages:new()
   local self = setmetatable({}, { __index = AdvantagesDisadvantages })
   self.maxHp = 0
   self.advantages = {}
   self.disadvantages = {}
   self.reputation = {}
   return self
end

function AdvantagesDisadvantages:copy()
   local copy = AdvantagesDisadvantages:new()
   copy.maxHp = self.maxHp
   for _, special in ipairs(self.advantages) do
      table.insert(copy.advantages, special:copy())
   end
   for _, special in ipairs(self.disadvantages) do
      table.insert(copy.disadvantages, special:copy())
   end
   for factionId, reputationModifier in pairs(self.reputation) do
      copy.reputation[factionId] = reputationModifier
   end
end

function AdvantagesDisadvantages:isNotEmpty()
   return self.maxHp ~= 0 or #self.advantages ~= 0 or #self.disadvantages ~= 0
end

function AdvantagesDisadvantages:cost()
   local cost = self.maxHp
   for _, advantage in ipairs(self.advantages) do
      cost = cost + advantage.cost
   end
   for _, disadvantage in ipairs(self.disadvantages) do
      cost = cost + disadvantage.cost
   end
   for _, reputation in pairs(self.reputation) do
      if reputation < 0 then
         cost = cost - reputationCost
      elseif reputation > 0 then
         cost = cost + reputationCost
      end
   end
   return cost
end

function AdvantagesDisadvantages:availableAdvantages()
   local notAvailableAdvantages = {}
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

function AdvantagesDisadvantages:availableDisadvantages()
   local notAvailableDisadvantages = {}
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
