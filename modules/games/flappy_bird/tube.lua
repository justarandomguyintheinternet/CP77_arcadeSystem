local ink = require("modules/ui/inkHelper")

tube = {}

function tube:new(x, y, gapY)
	local o = {}

    o.x = x
    o.y = y
    o.gapY = gapY

    o.topTube = nil
    o.bottomTube = nil

    o.size = {x = 15, y = 200}
    o.path = "base\\gameplay\\gui\\world\\arcade_games\\contra\\run_and_gun_bkgrnd_spritesheet.inkatlas"
    o.part = "Pipe_white"

	self.__index = self
   	return setmetatable(o, self)
end

function tube:spawn(screen)
    self.topTube = ink.image(self.x + self.size.x / 2, self.y - self.gapY / 2 - self.size.y, self.size.x, self.size.y, self.path, self.part, 0)
    self.topTube.pos:Reparent(screen, -1)

    self.bottomTube = ink.image(self.x + self.size.x / 2, self.y + self.gapY / 2, self.size.x, self.size.y, self.path, self.part, 0)
    self.bottomTube.pos:Reparent(screen, -1)
end

function tube:setPos(x, y, gapY)
    self.x = x
    self.y = y
    self.gapY = gapY or self.gapY

    self.topTube.pos:SetMargin(self.x + self.size.x / 2, self.y - self.gapY / 2 - self.size.y, 0, 0)
    self.bottomTube.pos:SetMargin(self.x + self.size.x / 2, self.y + self.gapY / 2, 0, 0)
end

function tube:playerCollides(x, y, size)
    local collides = false

    if math.abs(self.x - x) < (size / 2 + self.size.x / 2) then
        if math.abs(self.y - y) > (self.gapY / 2 + size / 2) - 10 then
            collides = true
        end
    end

    return collides
end

return tube