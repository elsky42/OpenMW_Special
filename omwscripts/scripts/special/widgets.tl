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

    increase: function(Scrollbar)
    decrease: function(Scrollbar)
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
    self.scroller.props = self.scroller.props or {}
    self.scroller.props.relativeSize = v2(1, self.scrollerRelativeSizeY)
    self:updateScrollerRelativePosition()
end

function Scrollbar:update()
    self.scrollerRelativeSizeY = self.scrollerAreaRelativeSizeY / self.options.size

    if self.options.size <= 1 then return end
    
    if self._layout and self._layout.content and #self._layout.content > 1 then
        self:updateScroller()
        return
    end

    self._layout.content = ui.content {}

    -- border
    self._layout.content:add {
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
    self._layout.content:add(self.upButton)

    -- scroller
    self.scroller = { template = templates.sandImage }
    self._layout.content:add(self.scroller)
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
    self._layout.content:add(self.downButton)
end

function Scrollbar:changeSize(newSize: number)
    self.options.size = math.max(1, newSize)
    self.current = math.min(self.options.size, self.current)
    self:update()
end

function Scrollbar:decreaseSize()
    self:changeSize(self.options.size - 1)
end

function Scrollbar:setCurrent(newCurrent: number)
    self.current = math.max(1, math.min(self.options.size, newCurrent))
    self:updateScrollerRelativePosition()
end

function Scrollbar:increase() self:setCurrent(self.current + 1) end
function Scrollbar:decrease() self:setCurrent(self.current - 1) end

function Scrollbar:layout(): ui.Layout
    self._layout = {
        props = self.options.props as table,
    }
    self:update()
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


global record ScrollableProperties
    relativePosition: V2
    relativeSize: V2
    scrollbarRelativeSizeWidth: number
end

global record ScrollableEvents
    mouseClick: function(number)
    mouseDoubleClick: function(number)
    onChange: function(number)
end

global record ScrollableOptions
    lines: {ui.Layout}
    events: ScrollableEvents
    props: ScrollableProperties
end

global record Scrollable
    options: ScrollableOptions
    linesFlex: ui.Layout
    scrollbar: Scrollbar

    _layout: ui.Layout
end

local noOp = function() end

function Scrollable:new(options: ScrollableOptions): Scrollable
    local self: Scrollable = setmetatable({}, { __index = Scrollable })
    options.lines = options.lines or {}
    options.events = options.events or {}
    options.events.mouseClick = options.events.mouseClick or noOp
    options.events.mouseDoubleClick = options.events.mouseDoubleClick or noOp
    options.events.onChange = options.events.onChange or noOp
    options.props = options.props or {}
    options.props.scrollbarRelativeSizeWidth = options.props.scrollbarRelativeSizeWidth or 0.01
    self.options = options
    return self
end


function Scrollable:update()
    if not self.linesFlex then return end
    local linesFlexContent = ui.content { }
    for i, line in ipairs(self.options.lines) do
        if i >= self.scrollbar.current then
            linesFlexContent:add {
                type = ui.TYPE.Container,
                content = ui.content { line },
                events = {
                    mouseClick = async:callback(function()
                            self.options.events.mouseClick(i)
                        end),
                    mouseDoubleClick = async:callback(function()
                            self.options.events.mouseDoubleClick(i)
                        end),
                },
            }
        end
    end
    self.linesFlex.content = linesFlexContent
end

function Scrollable:updateAndOnChange()
    self:update()
    self.options.events.onChange(self.scrollbar.current)
end

function Scrollable:setCurrent(current: number)
    self.scrollbar:setCurrent(current)
    self:updateAndOnChange()
end

function Scrollable:increase()
    self.scrollbar:increase()
    self:updateAndOnChange()
end

function Scrollable:decrease()
    self.scrollbar:decrease()
    self:updateAndOnChange()
end

function Scrollable:setLines(lines: {ui.Layout})
    self.options.lines = lines or {}
    self.scrollbar:changeSize(#self.options.lines)
    self:update()
end

function Scrollable:remove(i: number)
    table.remove(self.options.lines, i)
    self.scrollbar:decreaseSize()
    self:updateAndOnChange()
end

function Scrollable:layout(): ui.Layout
    local content = ui.content {}

    local scrollbarPositionX = 1 - 2 * 0.01 - self.options.props.scrollbarRelativeSizeWidth 
    self.linesFlex = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = false,
            relativePosition = v2(0.01, 0.01),
            relativeSize = v2(scrollbarPositionX, 0.98),
        },
    }
    content:add(self.linesFlex)
    self.scrollbar = Scrollbar:new {
        size = #self.options.lines,
        events = {
            onChange = function(_: number) self:updateAndOnChange() end,
        },
        props = {
            relativePosition = v2(scrollbarPositionX, 0.01),
            relativeSize = v2(self.options.props.scrollbarRelativeSizeWidth, 0.98),
        },
    }
    local scrollbarLayout = self.scrollbar:layout()
    scrollbarLayout.name = 'scrollbar'
    content:add(self.scrollbar:layout())
    
    self:update()

    self._layout =  {
        content = content,
        props = self.options.props as table,
    }
    return self._layout
end

global record Expandable
    layout: ui.Layout
    data: any
    isExpanded: boolean
    items: {Expandable}
    numParents: number
end

function Expandable:new(expandable: Expandable): Expandable
    local self: Expandable = setmetatable(expandable, { __index = Expandable })
    expandable.isExpanded = expandable.isExpanded == nil and false or expandable.isExpanded
    expandable.items = expandable.items == nil and {} or expandable.items
    expandable.numParents = expandable.numParents == nil and 0 or expandable.numParents
    return self
end

global function flattenExpandables(expandables: {Expandable}): {Expandable}
    local layouts: {Expandable} = {}
    local toVisit: {Expandable} = {}
    for i = 0, #expandables - 1 do
        expandables[#expandables - i].numParents = 0
        table.insert(toVisit, expandables[#expandables - i])
    end
    while #toVisit > 0 do
        local current = table.remove(toVisit)
        table.insert(layouts, current)
        if current.isExpanded then
            for i = 0, #current.items - 1 do
                current.items[#current.items - i].numParents = current.numParents + 1
                table.insert(toVisit, current.items[#current.items - i])
            end
        end
    end
    return layouts
end

global record ExpandableScrollableEvents
    mouseClickGroup: function(Expandable)
    mouseClickNonGroup: function(Expandable)
    mouseDoubleClickGroup: function(Expandable)
    mouseDoubleClickNonGroup: function(Expandable)
    onChange: function(number) 
end

global record ExpandableScrollableOption
    items: {Expandable}
    events: ExpandableScrollableEvents
    props: ScrollableProperties
end

global record ScrollableGroups
    options: ExpandableScrollableOption

    scrollable: Scrollable

    _flattenedItems: {Expandable}
    _layout: ui.Layout
end

function ScrollableGroups:new(options: ExpandableScrollableOption): ScrollableGroups
    local self: ScrollableGroups = setmetatable({}, { __index = ScrollableGroups })
    self.options = options
    self.options.events = self.options.events or {}
    self.options.events.mouseClickGroup = self.options.events.mouseClickGroup or noOp
    self.options.events.mouseClickNonGroup = self.options.events.mouseClickNonGroup or noOp
    self.options.events.mouseDoubleClickGroup = self.options.events.mouseDoubleClickGroup or noOp
    self.options.events.mouseDoubleClickNonGroup = self.options.events.mouseDoubleClickNonGroup or noOp
    self.options.events.onChange = self.options.events.onChange or noOp
    self.options.items = self.options.items or {}
    self.options.props = self.options.props or {}
    return self
end

function ScrollableGroups:update()
    self._flattenedItems = flattenExpandables(self.options.items)
    local itemsLayouts: {ui.Layout} = {}
    for _, item in ipairs(self._flattenedItems) do
        item.items = item.items or {}
        local content = ui.content {}
        content:add {
            props = {
                size = v2(item.numParents * 20, 1),
            }
        }
        if #item.items > 0 then
            content:add {
                template = templates.textNormal,
                props = { text = item.isExpanded and '- ' or '+ ' },
            }
        end
        content:add(item.layout)
        table.insert(itemsLayouts, {
            type = ui.TYPE.Flex,
            content = content,
            events = {
                mouseClick = async:callback(function(): boolean
                        if #item.items > 0 then
                            self.options.events.mouseClickGroup(item)
                        else
                            self.options.events.mouseClickNonGroup(item)    
                        end
                        return true
                    end),
                mouseDoubleClick = async:callback(function(): boolean
                        if #item.items > 0 then
                            self.options.events.mouseDoubleClickGroup(item)
                        else
                            self.options.events.mouseDoubleClickNonGroup(item)    
                        end
                        return true
                    end)
            },
            props = { horizontal = true },
        } as ui.Layout)
    end
    self.scrollable:setLines(itemsLayouts)
end

function ScrollableGroups:updateAndOnChange()
    self:update()
    self.options.events.onChange()
end

function ScrollableGroups:layout(): ui.Layout
    self.scrollable = Scrollable:new {
        events = {
            mouseClick = function(i: integer)
                    self._flattenedItems[i].isExpanded = not self._flattenedItems[i].isExpanded
                    self:updateAndOnChange()
                end,
            onChange = self.options.events.onChange,
        },
        props = {
            relativeSize = v2(1, 1),
        },
    }
    self._layout = {
        content = ui.content { self.scrollable:layout() },
        props = self.options.props as table,
    }
    self:update()
    return self._layout
end

global record Grouppable
    layout: ui.Layout
    group: {string}
    data: any
end

global function group(grouppables: {Grouppable}): {Expandable}
    local expandables: {Expandable} = {}
    local expandablesByGroup: {string:Expandable} = {}
    for _, grouppable in ipairs(grouppables) do
        local pgroup: string = ''
        local lastExpandable: Expandable = nil

        for i, part in ipairs(grouppable.group) do
            pgroup = pgroup .. '.' .. part
            if not expandablesByGroup[pgroup] then
                local expandable = Expandable:new {
                    layout = {
                        template = templates.textNormal,
                        props = { text = part },
                    },
                }
                if lastExpandable then
                    table.insert(lastExpandable.items, expandable)
                end
                expandablesByGroup[pgroup] = expandable
                if i == 1 then
                    table.insert(expandables, expandable)
                end
            end
            lastExpandable = expandablesByGroup[pgroup]
        end

        if lastExpandable then
            lastExpandable.items = lastExpandable.items or {}
            table.insert(lastExpandable.items, {
                layout = grouppable.layout,
                data = grouppable.data,
            })
        else
            table.insert(expandables, {
                layout = grouppable.layout,
                data = grouppable.data,
            })
        end
    end
    return expandables
end