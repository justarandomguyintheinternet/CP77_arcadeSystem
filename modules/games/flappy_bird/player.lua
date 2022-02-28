local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")

player = {}

function player:new(game, x, y)
	local o = {}

    o.game = game

    o.x = x
    o.y = y

    o.velY = 0
    o.grav = 0.075
    o.closestTube = 100

    o.ink = nil
    o.birdInk = nil
    o.animeFrame = 1

    o.dt = 0

	self.__index = self
   	return setmetatable(o, self)
end

function player:spawn(screen)
    self.birdInk = ink.image(100, 100, 60, 30, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'gryphon_1', 0, inkBrushMirrorType.Vertical)
    self.birdInk.pos:Reparent(screen, -1)
end

function player:update(dt)
    self.dt = dt
    self.velY = self.velY + self.grav * (dt * 80)
    self.y = self.y + self.velY

    self.birdInk.pos:SetMargin(self.x - 30, self.y - 15, 0, 0)
    self.birdInk.image:SetRotation(self.velY * 10)

    if self.y < -10 or self.y > self.game.screenSize.y + 10 then
        self.game:lost()
    end
end

function player:updateAnimation()
    self.animeFrame = self.animeFrame + 1
    if self.animeFrame > 5 then
        self.animeFrame = 1
    end

    self.birdInk.image:SetTexturePart(tostring("gryphon_" .. self.animeFrame))
end

function player:jump()
    self.velY = -2.5 - math.abs((1 - (60 * self.dt)))
    utils.playSound("lcm_wallrun_in", 3)
end

return player