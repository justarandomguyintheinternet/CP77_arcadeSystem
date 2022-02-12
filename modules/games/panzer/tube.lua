local ink = require("modules/ui/inkHelper")
local width = 20

tube = {}

function tube:new(x, y, gapY, color)
	local o = {}

    o.x = x
    o.y = y
    o.gapY = gapY
    o.color = color

    o.topTube = nil
    o.bottomTube = nil

    o.topRect = nil
    o.bottomRect = nil

	self.__index = self
   	return setmetatable(o, self)
end

function tube:spawn(screen)
    local y = self.y - 200 - (self.gapY / 2)
    self.topTube = ink.rect(self.x, y, width, 400, self.color, 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.topTube:Reparent(screen, -1)

    local y = self.y + 200 + (self.gapY / 2)
    self.bottomTube = ink.rect(self.x, y, width, 400, self.color, 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.bottomTube:Reparent(screen, -1)

    local y = self.y - (self.gapY / 2)
    self.topRect = ink.rect(self.x, y, width * 1.5, 10, self.color, 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.topRect:Reparent(screen, -1)

    local y = self.y + (self.gapY / 2)
    self.bottomRect = ink.rect(self.x, y, width * 1.5, 10, self.color, 0, Vector2.new({X = 0.5, Y = 0.5}))
    self.bottomRect:Reparent(screen, -1)
end

function tube:setPos(x, y, gapY)
    self.x = x
    self.y = y
    self.gapY = gapY or self.gapY

    local y = self.y - 200 - (self.gapY / 2)
    self.topTube:SetMargin(x, y, 0, 0)

    local y = self.y + 200 + (self.gapY / 2)
    self.bottomTube:SetMargin(x, y, 0, 0)

    local y = self.y - (self.gapY / 2)
    self.topRect:SetMargin(x, y, 0, 0)

    local y = self.y + (self.gapY / 2)
    self.bottomRect:SetMargin(x, y, 0, 0)
end

function tube:playerCollides(x, y, size)
    local collides = false

    if math.abs(self.x - x) < (size / 2 + width / 2) then
        if math.abs(self.y - y) > (self.gapY / 2 + size / 2) - 10 then
            collides = true
        end
    end

    return collides
end

return tube