local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local _utils = require('scripts.special.utils')

local v2 = util.vector2
local V2 = util.Vector2

global sandColor = I.MWUI.templates.textNormal.props.textColor as util.Color
global lightSandColor = I.MWUI.templates.textHeader.props.textColor as util.Color

local function calculateTextSize(): number
    local screenSize = ui.layers[ui.layers.indexOf('Windows') as integer].size
    return screenSize.y / 35
end

local function calculateTextNormalTemplate(): ui.Template
    local textTemplate = auxUi.deepLayoutCopy(I.MWUI.templates.textNormal as table) as ui.Template
    textTemplate.props.textSize = calculateTextSize()
    textTemplate.props.textColor = sandColor
    return textTemplate
end

local function calculateTextHeaderTemplate(): ui.Template
    local textTemplate = auxUi.deepLayoutCopy(calculateTextNormalTemplate() as table) as ui.Template
    textTemplate.props.textColor = lightSandColor
    return textTemplate
end

global templates = {
    sandImage = {
        type = ui.TYPE.Image,
        props = {
            alpha = 0.8,
            color = sandColor,
            resource = ui.texture { path = 'white' },
        },
    } as ui.Template,

    textHeader = calculateTextHeaderTemplate(),
    textNormal = calculateTextNormalTemplate(),
}

global record BackgroundOptions
    alpha: number | nil
    color: util.Color | nil
end

global function background(options: BackgroundOptions): ui.Layout
    return {
        type = ui.TYPE.Image,
        props = {
            alpha = options.alpha or 0.9,
            color = options.color or util.color.rgb(0, 0, 0),
            relativeSize = v2(1, 1),
            resource = ui.texture { path = 'white' },
        },
    }
end

global function borders(thick: boolean): ui.Layout
    return {
        template = thick and I.MWUI.templates.bordersThick or I.MWUI.templates.borders,
        props = { relativeSize = v2(1, 1) },
    }
end

local record TextLinesOptions
    color: util.Color | nil
    flexName: string | nil
    lines: {string}
    relativePosition: V2 | nil
    relativeSize: V2 | nil
    size: V2 | nil
end

global function textLines(options: TextLinesOptions): ui.Layout
    local content = ui.content {}
    for i, line in ipairs(options.lines) do
        content:add {
            name = tostring(i),
            template = templates.textNormal,
            props = {
                text = line,
                textColor = options.color,
            }
        }
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

global record TextButtonEvents
    focusGain: function()
    focusLoss: function()
    focusChange: function()
    mouseClick: function(event: ui.MouseEvent)
end

global record TextButtonProperties
    relativePosition: V2
    relativeSize: V2
    size: V2
end

global record TextButtonOptions
    lines: {string}
    normalTextColor: util.Color | nil
    backgroundOptions: BackgroundOptions | nil
    events: TextButtonEvents
    props: TextButtonProperties
end

global record TextButton
    options: TextButtonOptions

    textLines: ui.Layout
end

function TextButton:new(options: TextButtonOptions): TextButton
    local self: TextButton = setmetatable({}, { __index = TextButton })
    self.options = options
    local unfocusedColor = options.normalTextColor or sandColor
    self.textLines = textLines {
        color = unfocusedColor,
        lines = options.lines,
    }
    return self
end

function TextButton:changeTextColor(color: util.Color)
    for i, _ in ipairs(self.options.lines) do
        lookupLayout(self.textLines, {tostring(i)}).props.textColor = color
    end
    if self.options.events.focusChange then self.options.events.focusChange() end
end

function TextButton:layout(): ui.Layout
    local content = ui.content {}
    if self.options.backgroundOptions ~= nil then
        content:add(background(self.options.backgroundOptions))
    end
    content:add(borders(true))
    content:add(self.textLines)
    local events = {}
    local unfocusedColor = self.options.normalTextColor or sandColor
    events.focusGain = async:callback(self.options.events.focusGain or function() self:changeTextColor(lightSandColor) end)
    events.focusLoss = async:callback(self.options.events.focusLoss or function() self:changeTextColor(unfocusedColor) end)
    if self.options.events and self.options.events.mouseClick then
        events.mouseClick = async:callback(self.options.events.mouseClick)
    end
    return {
        content = content,
        events = events,
        props = self.options.props as table,
    }
end

global record ScrollbarProperties
    relativePosition: V2
    relativeSize: V2
end

global record ScrollbarEvents
    onChange: function(number)
end

global record ScrollbarOptions
    size: number
    events: ScrollbarEvents
    props: ScrollbarProperties
end

global record Scrollbar
    options: ScrollbarOptions
    buttonRelativeSizeY: number
    scrollerAreaRelativeSizeY: number
    scrollerRelativeSizeY: number
    current: number

    upButton: ui.Layout
    scroller: ui.Layout
    downButton: ui.Layout
    _layout: ui.Layout
end

function Scrollbar:new(options: ScrollbarOptions): Scrollbar
    local self: Scrollbar = setmetatable({}, { __index = Scrollbar })
    options.size = options.size or 1
    options.events = options.events or {}
    options.events.onChange = options.events.onChange or function(_: number) end
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
            self._layout.content = ui.content {}
        end
    else
        self.scrollerRelativeSizeY = self.scrollerAreaRelativeSizeY / self.options.size
        self:updateScroller()
    end
end

function Scrollbar:setCurrent(newCurrent: number)
    self.current = math.max(1, math.min(self.options.size, newCurrent))
    self:updateScrollerRelativePosition()
end

function Scrollbar:increase() self:setCurrent(self.current + 1) end
function Scrollbar:decrease() self:setCurrent(self.current - 1) end

function Scrollbar:layout(): ui.Layout
    if self.options.size <= 1 then return {} end
    local content = ui.content {}
    
    -- border
    content:add {
        template = I.MWUI.templates.borders,
        props = { relativeSize = v2(1, 1) },
    }

    -- up button
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

    -- scroller
    self.scroller = {
        template = templates.sandImage,
    }
    content:add(self.scroller)
    self:updateScroller()

    -- down button
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
        props = self.options.props as table,
    }
    return self._layout
end

global record ScrollableTextLinesProperties
    relativePosition: V2
    relativeSize: V2
    scrollbarRelativeSizeWidth: number
end

global record ScrollableTextLinesEvents
    mouseDoubleClick: function(number)
    onChange: function(number)
end

global record ScrollableTextLinesOptions
    lines: {string}
    events: ScrollableTextLinesEvents
    props: ScrollableTextLinesProperties
end

global record ScrollableTextLines
    options: ScrollableTextLinesOptions
    linesFlex: ui.Layout
    scrollbar: Scrollbar
end

function ScrollableTextLines:new(options: ScrollableTextLinesOptions): ScrollableTextLines
    local self: ScrollableTextLines = setmetatable({}, { __index = ScrollableTextLines })
    options.lines = options.lines or {}
    options.events = options.events or {}
    options.events.mouseDoubleClick = options.events.mouseDoubleClick or function(_: number) end
    options.events.onChange = options.events.onChange or function(_: number) end
    options.props = options.props or {}
    options.props.scrollbarRelativeSizeWidth = options.props.scrollbarRelativeSizeWidth or 0.01
    self.options = options
    return self
end

function ScrollableTextLines:update()
    if not self.linesFlex then return end
    local linesFlexContent = ui.content { }
    for i, line in ipairs(self.options.lines) do
        if i >= self.scrollbar.current then
            local isFirst = i == self.scrollbar.current
            linesFlexContent:add {
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
            }
        end
    end
    self.linesFlex.content = linesFlexContent
end

function ScrollableTextLines:remove(i: number)
    table.remove(self.options.lines, i)
    self.scrollbar:decreaseSize()
    self:update()
    self.options.events.onChange(self.scrollbar.current)
end

function ScrollableTextLines:layout(): ui.Layout
    local content = ui.content {}

    self.linesFlex = {
        type = ui.TYPE.Flex,
        props = {
            relativePosition = v2(0.01, 0.01),
            relativeSize = v2(1 - 2 * 0.01 - self.options.props.scrollbarRelativeSizeWidth, 0.98),
        },
    }
    content:add(self.linesFlex)
    self.scrollbar = Scrollbar:new {
        size = #self.options.lines,
        events = {
            onChange = function(newCurrent: number)
                    self:update()
                    self.options.events.onChange(newCurrent)
                end,
        },
        props = {
            relativePosition = v2(0.98, 0.01),
            relativeSize = v2(self.options.props.scrollbarRelativeSizeWidth, 0.98),
        },
    }
    content:add(self.scrollbar:layout())
    
    self:update()

    return {
        content = content,
        props = self.options.props as table,
    }
end
