local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")

rain = {}

function rain:new(game, x, y, size, speed, length)
	local o = {}

    o.game = game

    o.x = x
    o.y = y

    o.speed = speed or math.random(4, 12)
    o.length = length or math.random(7, 12)
    o.size = size or math.random(8, 12)

    o.ink = nil

	self.__index = self
   	return setmetatable(o, self)
end

function rain:spawn(screen)
    local c = color.new(0, math.min(1, math.random() + 0.7), 0)

    self.ink = ink.text(self:generateString(), self.x, self.y, self.size, c)
    self.ink:Reparent(screen, -1)
end

function rain:generateString()
    local s = ""

    for _ = 1, self.length do
        s = s .. string.char(math.random(0, 126)) .. "\n"
    end

    return s
end

function rain:update(dt)
    if self.speed == 0 then return end

    self.y = self.y + (self.speed / 6) * (dt * 60)
    if self.y > 250 then
        self.y = - 150
        self.x = math.random(0, 320)
        self.ink:SetText(self:generateString())
        self.ink:SetTintColor(color.new(0, math.min(1, math.random() + 0.7), 0))
    end

    self.ink:SetMargin(self.x, self.y, 0, 0)
end

return rain