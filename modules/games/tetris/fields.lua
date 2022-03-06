local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")
local Cron  = require("modules/external/Cron")

local pieces = {
    [1] = {{1, 5, 9, 13}, {4, 5, 6, 7}},
    [2] = {{4, 5, 9, 10}, {2, 6, 5, 9}},
    [3] = {{6, 7, 9, 10}, {1, 5, 6, 10}},
    [4] = {{1, 2, 5, 9}, {4, 5, 6, 10}, {1, 5, 9, 8}, {0, 4, 5, 6}},
    [5] = {{1, 2, 6, 10}, {3, 5, 6, 7}, {2, 6, 10, 11}, {5, 6, 7, 9}},
    [6] = {{1, 4, 5, 6}, {1, 5, 6, 9}, {4, 5, 6, 9}, {1, 4, 5, 9}},
    [7] = {{1, 2, 5, 6}},
}

local colors = {
    [1] = color.red,
    [2] = color.green,
    [3] = color.blue,
    [4] = color.yellow,
    [5] = color.cyan,
    [6] = color.magenta,
    [7] = color.limegreen
}

fields = {}

function fields:new(game, x, y, xFields, yFields, fieldSize, gapSize)
	local o = {}

    o.game = game
    o.screen = nil

    o.x = x
    o.y = y

    o.xFields = xFields
    o.yFields = yFields

    o.fieldSize = fieldSize
    o.gapSize = gapSize

    o.fields = {}

    o.previewFields = {}
    o.previewPiece = {}

    o.currentPiece = {}

    o.moveDelay = 0.7
    o.time = 0
    o.minDelay = 0.15

	self.__index = self
   	return setmetatable(o, self)
end

function fields:spawn(screen)
    self.screen = screen

    for y = 1, self.yFields do
        self.fields[y] = {}
        for x = 1, self.xFields do
            self.fields[y][x] = self:spawnNewField(self.x + x * (self.fieldSize + self.gapSize), self.y + y * (self.fieldSize + self.gapSize))
        end
    end

    for y = 1, 4 do
        self.previewFields[y] = {}
        for x = 1, 4 do
            self.previewFields[y][x] = self:spawnNewField(self.x + 30 + (self.xFields + x) * (self.fieldSize + self.gapSize), self.y + 20 + y * (self.fieldSize + self.gapSize))
        end
    end

    self:setNewPreview()
    self:spawnPiece()
end

function fields:spawnNewField(x, y)
    local f = {color = color.black, ink = nil}

    f.ink = ink.rect(x, y, self.fieldSize, self.fieldSize, f.color)
    f.ink:Reparent(self.screen, -1)
    f.ink:SetVisible(false)

    return f
end

function fields:setNewPreview()
    for y = 1, 4 do
        for x = 1, 4 do
            self.previewFields[y][x].ink:SetVisible(false)
        end
    end

    local i = math.random(#pieces)
    local piece = pieces[i]

    self.previewPiece = piece
    self.previewColor = colors[i]
    for _, p in pairs(piece[1]) do
        self.previewFields[((p - (p % 4)) / 4) + 1][(p % 4) + 1].ink:SetVisible(true)
        self.previewFields[((p - (p % 4)) / 4) + 1][(p % 4) + 1].ink:SetTintColor(colors[i])
    end
end

function fields:spawnPiece() -- Takes the preview piece and spawns it
    self.currentPiece = {
        pieceData = utils.deepcopy(self.previewPiece),
        x = 3,
        y = 1,
        rot = 1,
        color = self.previewColor
    }

    self:setNewPreview()
    if self:intersects() then
        self.game:lost()
    else
        self:draw(false)
    end
end

function fields:draw(clear)
    for _, p in pairs(self.currentPiece.pieceData[self.currentPiece.rot]) do
        local x = self.currentPiece.x + (p % 4)
        local y = self.currentPiece.y + ((p - (p % 4)) / 4)

        if clear then
            self.fields[y][x].ink:SetVisible(false)
        else
            self.fields[y][x].ink:SetVisible(true)
            self.fields[y][x].ink:SetTintColor(self.currentPiece.color)
        end
    end
end

function fields:moveDown()
    self:draw(true)
    self.currentPiece.y = self.currentPiece.y + 1
    if self:intersects() then
        self.currentPiece.y = self.currentPiece.y - 1
        self:draw(false)
        self:breakLines()
        self:spawnPiece()
    end
    self:draw(false)
end

function fields:moveRight()
    self:draw(true)
    self.currentPiece.x = self.currentPiece.x + 1
    if self:intersects() then
        self.currentPiece.x = self.currentPiece.x - 1
        self:draw(false)
    end
    self:draw(false)
end

function fields:moveLeft()
    self:draw(true)
    self.currentPiece.x = self.currentPiece.x - 1
    if self:intersects() then
        self.currentPiece.x = self.currentPiece.x + 1
        self:draw(false)
    end
    self:draw(false)
end

function fields:intersects()
    local i = false
    for _, p in pairs(self.currentPiece.pieceData[self.currentPiece.rot]) do
        local x = self.currentPiece.x + (p % 4)
        local y = self.currentPiece.y + ((p - (p % 4)) / 4)

        if x < 1 or x > 10 then
            i = true
        end
        if y < 1 or y > 20 then
            i = true
        end

        if not i then
            if self.fields[y][x].ink:IsVisible() then
                i = true
            end
        end
    end

    return i
end

function fields:rotate()
    self:draw(true)
    self.currentPiece.rot = self.currentPiece.rot + 1
    if self.currentPiece.rot > #self.currentPiece.pieceData then self.currentPiece.rot = 1 end
    if self:intersects() then
        self.currentPiece.rot = self.currentPiece.rot - 1
        if self.currentPiece.rot < 1 then self.currentPiece.rot = #self.currentPiece.pieceData end
    end
    self:draw(false)

    utils.playSound("test_beep_01", 2)
end

function fields:breakLines()
    for y = self.yFields, 2, -1 do
        local empty = 0
        for x = self.xFields, 1, -1 do
            if self.fields[y][x].ink:IsVisible() then
                empty = empty + 1
            end
        end
        if empty == self.xFields then
            for Y = y, 2, -1 do
                for X = self.xFields, 1, -1 do
                    self.fields[Y][X].ink:SetVisible(self.fields[Y - 1][X].ink:IsVisible())
                    self.fields[Y][X].ink:SetTintColor(self.fields[Y - 1][X].ink:GetTintColor())
                end
            end
            self.game.score = self.game.score + 10
            self.moveDelay = math.max(self.moveDelay - 0.025, self.minDelay)

            utils.playSound("ui_hacking_access_granted", 2)
            self:breakLines()
        end
    end
end

function fields:update(dt)
    self.time = self.time + dt
    if self.time > self.moveDelay then
        self.time = 0
        self:moveDown()
    end
end

return fields