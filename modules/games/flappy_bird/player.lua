local ink = require("modules/ui/inkHelper")

player = {}

function player:new(x, y)
	local o = {}

    o.x = x
    o.y = y

    o.velY = 0
    o.grav = 0.075
    o.closestTube = 100

    o.ink = nil
    o.birdInk = nil
    o.animeFrame = 1

	self.__index = self
   	return setmetatable(o, self)
end

function player:spawn(screen)
    self.birdInk = ink.image(100, 100, 60, 30, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'gryphon_1', 0, inkBrushMirrorType.Vertical)
    self.birdInk.pos:Reparent(screen, -1)
end

function player:update(dt)
    self.velY = self.velY + self.grav * (dt * 80)
    self.y = self.y + self.velY

    self.birdInk.pos:SetMargin(self.x - 30, self.y - 15, 0, 0)
    self.birdInk.image:SetRotation(self.velY * 10)
end

function player:updateAnimation()
    self.animeFrame = self.animeFrame + 1
    if self.animeFrame > 5 then
        self.animeFrame = 1
    end

    self.birdInk.image:SetTexturePart(tostring("gryphon_" .. self.animeFrame))
end

function player:jump()
    self.velY = -3.5
end

return player