local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")

obstacle = {}

function obstacle:new(x, y, size, sprites, delay, speed, sizeCol)
	local o = {}

    o.x = x
    o.y = y

    o.size = size or {x = 15, y = 15}
    o.sizeCollision = sizeCol or size
    o.path = 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas'
    o.sprites = sprites

    o.animeDelay = delay or 0.2
    o.animeFrame = 1
    o.animeCron = nil
    o.speed = speed or 1

    o.ink = nil
    o.notHit = true

	self.__index = self
   	return setmetatable(o, self)
end

function obstacle:spawn(screen)
    self.ink = ink.image(self.x, self.y, self.size.x, self.size.y, self.path, self.sprites[1], 0, inkBrushMirrorType.Both)
    self.ink.pos:Reparent(screen, -1)

    self.animeCron = Cron.Every(self.animeDelay, function ()
        self.animeFrame = self.animeFrame + 1
        if self.animeFrame > #self.sprites then
            self.animeFrame = 1
        end

        self.ink.image:SetTexturePart(self.sprites[self.animeFrame])
    end)
end

function obstacle:despawn()
    Cron.Halt(self.animeCron)
end

return obstacle