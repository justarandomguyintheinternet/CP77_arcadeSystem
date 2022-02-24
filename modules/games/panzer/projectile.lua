local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")

projectile = {}

function projectile:new(game, x, y, velX, velY, damage, targetTag, atlasPath, atlasPart, size, isExplosive)
	local o = {}

    o.game = game
    o.screen = nil

    o.x = x
    o.y = y
    o.velX = velX or 0
    o.velY = velY or 0

    o.damage = damage
    o.targetTag = targetTag

    o.size = size
    o.atlasPath = atlasPath
    o.atlasPart = atlasPart

    o.image = nil
    o.isExplosive = isExplosive

	self.__index = self
    return setmetatable(o, self)
end

function projectile:spawn(screen)
    self.screen = screen
    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, self.atlasPath, self.atlasPart, 0, inkBrushMirrorType.Vertical)
    self.image.pos:Reparent(screen, -1)
end

function projectile:update(dt)
    self.x = self.x - self.velX * dt
    self.y = self.y - self.velY * dt

    if self.x > self.game.screenSize.x + 10 or self.x < -10 then
        self:despawn()
    elseif self.y > self.game.screenSize.y + 10 or self.y < -10 then
        self:despawn()
    end

    self.image.pos:SetMargin(self.x, self.y, 0, 0)
end

function projectile:despawn()
    self.image.image:SetVisible(false)
    if self.isExplosive then
        local exp = require("modules/games/panzer/explosion"):new(self.game, self.x, self.y, self.size.y, self.size, 0.1)
        exp:spawn(self.screen)
    end
    utils.removeItem(self.game.projectiles, self)
end

return projectile