local ink = require("modules/ui/inkHelper")

projectile = {}

function projectile:new(game, x, y, velX, velY, damage, atlasPath, atlasPart, size)
	local o = {}

    o.game = game

    o.x = x
    o.y = y
    o.velX = velX
    o.velY = velY

    o.damge = damage

    o.size = size
    o.atlasPath = atlasPath
    o.atlasPart = atlasPart

    o.image = nil

	self.__index = self
    return setmetatable(o, self)
end

function projectile:spawn(screen)
    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, self.atlasPath, self.atlasPart, 0, inkBrushMirrorType.Vertical)
    self.image.pos:Reparent(screen, -1)
end

function projectile:update(dt)
    self.x = self.x - self.velX * dt
    self.y = self.y - self.velY * dt

    if self.x > self.game.screenSize.x + 5 then
        self.image.image:SetVisible(false)
        self = nil
    elseif self.y > self.game.screenSize.y + 5 then
        self.image.image:SetVisible(false)
        self = nil
    end

    self.image.pos:SetMargin(self.x, self.y, 0, 0)
end

return projectile