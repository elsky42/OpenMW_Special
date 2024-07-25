local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local table = _tl_compat and _tl_compat.table or table; local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local _utils = require('scripts.special.utils')

local v2 = util.vector2
local V2 = util.Vector2

sandColor = I.MWUI.templates.textNormal.props.textColor
lightSandColor = I.MWUI.templates.textHeader.props.textColor

local function calculateTextSize()
   local screenSize = ui.layers[ui.layers.indexOf('Windows')].size
   return screenSize.y / 35
end

local function calculateTextNormalTemplate()
   local textTemplate = auxUi.deepLayoutCopy(I.MWUI.templates.textNormal)
   textTemplate.props.textSize = calculateTextSize()
   textTemplate.props.textColor = sandColor
   return textTemplate
end

local function calculateTextHeaderTemplate()
   local textTemplate = auxUi.deepLayoutCopy(calculateTextNormalTemplate())
   textTemplate.props.textColor = lightSandColor
   return textTemplate
end

templates = {
   sandImage = {
      type = ui.TYPE.Image,
      props = {
         alpha = 0.8,
         color = sandColor,
         resource = ui.texture({ path = 'white' }),
      },
   },

   textHeader = calculateTextHeaderTemplate(),
   textNormal = calculateTextNormalTemplate(),
}

BackgroundOptions = {}




function background(options)
   return {
      type = ui.TYPE.Image,
      props = {
         alpha = options.alpha or 0.9,
         color = options.color or util.color.rgb(0, 0, 0),
         relativeSize = v2(1, 1),
         resource = ui.texture({ path = 'white' }),
      },
   }
end

function borders(thick)
   return {
      template = thick and I.MWUI.templates.bordersThick or I.MWUI.templates.borders,
      props = { relativeSize = v2(1, 1) },
   }
end










function textLines(options)
   local content = ui.content({})
   for i, line in ipairs(options.lines) do
      content:add({
         name = tostring(i),
         template = templates.textNormal,
         props = { text = line },
      })
   end
   return {
      type = ui.TYPE.Flex,
      name = options.flexName or 'flex',
      props = {
         autoSize = false,
         arrange = ui.ALIGNMENT.Center,
         align = ui.ALIGNMENT.Center,
         relativePosition = options.relativePosition or v2(0, 0),
         relativeSize = options.relativeSize or v2(1, 1),
         size = options.size or v2(0, 0),
      },
      content = content,
   }
end

TextButtonEvents = {}




TextButtonProperties = {}




TextButtonOptions = {}






function textButton(options)
   local label = textLines({ lines = options.lines })
   local changeTextColor = function(color)
      for i, _ in ipairs(options.lines) do
         lookupLayout(label, { tostring(i) }).props.textColor = color
      end
      if options.events.focusChange then options.events.focusChange() end
   end
   local content = ui.content({})
   if options.backgroundOptions ~= nil then
      content:add(background(options.backgroundOptions))
   end
   content:add(borders(true))
   content:add(label)
   local events = {}
   events.focusGain = async:callback(function() changeTextColor(lightSandColor) end)
   events.focusLoss = async:callback(function() changeTextColor(sandColor) end)
   if options.events and options.events.mouseClick then
      events.mouseClick = async:callback(options.events.mouseClick)
   end
   return {
      content = content,
      events = events,
      props = options.props,
   }
end

ScrollbarProperties = {}




ScrollbarEvents = {}



ScrollbarOptions = {}





Scrollbar = {}












function Scrollbar:new(options)
   local self = setmetatable({}, { __index = Scrollbar })
   options.size = options.size or 1
   options.events = options.events or {}
   options.events.onChange = options.events.onChange or function(_) end
   options.props = options.props or {}
   self.options = options
   self.buttonRelativeSizeY = 0.1
   self.scrollerAreaRelativeSizeY = 1 - 2 * self.buttonRelativeSizeY
   self.scrollerRelativeSizeY = self.scrollerAreaRelativeSizeY / self.options.size
   self.current = 1
   return self
end

function Scrollbar:updateScrollerRelativePosition()
   if not self.scroller then return end
   local scrollerRelativePositionY = self.buttonRelativeSizeY +
   (self.current - 1) * self.scrollerRelativeSizeY
   self.scroller.props = self.scroller.props or {}
   self.scroller.props.relativePosition = v2(0, scrollerRelativePositionY)
end

function Scrollbar:updateScroller()
   if not self.scroller then return end
   self.scroller.props = self.scroller.props or {}
   self.scroller.props.relativeSize = v2(1, self.scrollerRelativeSizeY)
   self:updateScrollerRelativePosition()
end

function Scrollbar:decreaseSize()
   self.options.size = math.max(1, self.options.size - 1)
   self.current = math.min(self.options.size, self.current)
   if self.options.size <= 1 then
      if self._layout then
         self._layout.content = ui.content({})
      end
   else
      self.scrollerRelativeSizeY = self.scrollerAreaRelativeSizeY / self.options.size
      self:updateScroller()
   end
end

function Scrollbar:setCurrent(newCurrent)
   self.current = math.max(1, math.min(self.options.size, newCurrent))
   self:updateScrollerRelativePosition()
end

function Scrollbar:increase() self:setCurrent(self.current + 1) end
function Scrollbar:decrease() self:setCurrent(self.current - 1) end

function Scrollbar:layout()
   if self.options.size <= 1 then return {} end
   local content = ui.content({})


   content:add({
      template = I.MWUI.templates.borders,
      props = { relativeSize = v2(1, 1) },
   })


   self.upButton = {
      template = templates.sandImage,
      events = {
         mouseClick = async:callback(function()
            self:decrease()
            self.options.events.onChange(self.current)
         end),
      },
      props = {
         relativeSize = v2(1, self.buttonRelativeSizeY),
      },
   }
   content:add(self.upButton)


   self.scroller = {
      template = templates.sandImage,
   }
   content:add(self.scroller)
   self:updateScroller()


   local downButtonRelativePositionY = self.buttonRelativeSizeY + self.scrollerAreaRelativeSizeY
   self.downButton = {
      template = templates.sandImage,
      events = {
         mouseClick = async:callback(function()
            self:increase()
            self.options.events.onChange(self.current)
         end),
      },
      props = {
         relativePosition = v2(0, downButtonRelativePositionY),
         relativeSize = v2(1, self.buttonRelativeSizeY),
      },
   }
   content:add(self.downButton)

   self._layout = {
      content = content,
      props = self.options.props,
   }
   return self._layout
end

ScrollableTextLinesProperties = {}





ScrollableTextLinesEvents = {}




ScrollableTextLinesOptions = {}





ScrollableTextLines = {}





function ScrollableTextLines:new(options)
   local self = setmetatable({}, { __index = ScrollableTextLines })
   options.lines = options.lines or {}
   options.events = options.events or {}
   options.events.mouseDoubleClick = options.events.mouseDoubleClick or function(_) end
   options.events.onChange = options.events.onChange or function(_) end
   options.props = options.props or {}
   options.props.scrollbarRelativeSizeWidth = options.props.scrollbarRelativeSizeWidth or 0.01
   self.options = options
   return self
end

function ScrollableTextLines:update()
   if not self.linesFlex then return end
   local linesFlexContent = ui.content({})
   for i, line in ipairs(self.options.lines) do
      if i >= self.scrollbar.current then
         local isFirst = i == self.scrollbar.current
         linesFlexContent:add({
            template = isFirst and templates.textHeader or templates.textNormal,
            events = {
               mouseClick = async:callback(function()
                  self.scrollbar:setCurrent(i)
                  self:update()
                  self.options.events.onChange(i)
               end),
               mouseDoubleClick = async:callback(function()
                  self.options.events.mouseDoubleClick(i)
               end),
            },
            props = { text = line },
         })
      end
   end
   self.linesFlex.content = linesFlexContent
end

function ScrollableTextLines:remove(i)
   table.remove(self.options.lines, i)
   self.scrollbar:decreaseSize()
   self:update()
   self.options.events.onChange(self.scrollbar.current)
end

function ScrollableTextLines:layout()
   local content = ui.content({})

   self.linesFlex = {
      type = ui.TYPE.Flex,
      props = {
         relativePosition = v2(0.01, 0.01),
         relativeSize = v2(1 - 2 * 0.01 - self.options.props.scrollbarRelativeSizeWidth, 0.98),
      },
   }
   content:add(self.linesFlex)
   self.scrollbar = Scrollbar:new({
      size = #self.options.lines,
      events = {
         onChange = function(newCurrent)
            self:update()
            self.options.events.onChange(newCurrent)
         end,
      },
      props = {
         relativePosition = v2(0.98, 0.01),
         relativeSize = v2(self.options.props.scrollbarRelativeSizeWidth, 0.98),
      },
   })
   content:add(self.scrollbar:layout())

   self:update()

   return {
      content = content,
      props = self.options.props,
   }
end
