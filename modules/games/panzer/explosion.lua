local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")
local utils = require("modules/util/utils")

explosion = {}

function explosion:new(game, x, y, size, targetSize, animationSpeed)
	local o = {}

    o.game = game
    o.screen = screen

    o.x = x
    o.y = y
    o.size = size
    o.atlasPath = "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas"

    o.targetSize = targetSize
    o.animationSpeed = animationSpeed or 0.2

	self.__index = self
   	return setmetatable(o, self)
end

function explosion:spawn(screen)
    table.insert(self.game.explosions, self)

    if self.targetSize then
        self.x = self.x + (self.targetSize.x - self.size) / 2
        self.y = self.y + (self.targetSize.y - self.size) / 2
    end
    self.explosion = ink.image(self.x, self.y, self.size, self.size, self.atlasPath, "shmup-blast1", 0, inkBrushMirrorType.Vertical)
    self.explosion.pos:Reparent(screen, -1)

    Cron.Every(self.animationSpeed, {tick = 1}, function(timer)
        if timer.tick < 4 then
            timer.tick = timer.tick + 1
            local part = tostring("shmup-blast" .. timer.tick)
            self.explosion.image:SetTexturePart(part)
        else
            self.explosion.image:SetVisible(false)
            utils.removeItem(self.game.explosions, self)
            timer:Halt()
        end
    end)
end

return explosion