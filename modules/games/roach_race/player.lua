local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")
local Cron = require("modules/external/Cron")

player = {}

function player:new(game, x, y)
	local o = {}

    o.game = game

    o.x = x
    o.y = y
    o.size = {x = 50, y = 40}

    o.velY = 0
    o.grav = 0.075
    o.dt = 0

    o.ink = nil
    o.birdInk = nil
    o.animeFrame = 1
    o.animeCron = nil

    o.lives = 3

	self.__index = self
   	return setmetatable(o, self)
end

function player:spawn(screen)
    self.ink = ink.image(100, 100, self.size.x, self.size.y, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'raoch_1', 0, inkBrushMirrorType.Both)
    self.ink.pos:Reparent(screen, -1)

    self.animeCron = Cron.Every(0.2, function ()
        self.animeFrame = self.animeFrame + 1
        if self.animeFrame > 5 then
            self.animeFrame = 1
        end

        self.ink.image:SetTexturePart(tostring("roach_" .. self.animeFrame))
    end)
end

function player:update(dt)
    self.dt = dt
    self.velY = self.velY + self.grav * (dt * 80)
    self.y = self.y + self.velY

    if self.y > self.game.screenSize.y - 45 then
        self.y = self.game.screenSize.y - 45
        self.velY = 0
    end

    self.ink.pos:SetMargin(self.x - 30, self.y - 15, 0, 0)
    self.ink.image:SetRotation(self.velY * 10)
end

function player:despawn()
    Cron.Halt(self.animeCron)
end

function player:jump()
    if self.velY ~= 0 then return end
    self.velY = -2.5 - math.abs((1 - (60 * self.dt)))
    utils.playSound("lcm_wallrun_in", 3)
end

return player