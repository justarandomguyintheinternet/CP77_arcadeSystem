local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")

player = {}

function player:new(x, y, game)
	local o = {}

    o.game = game
    o.screen = screen
    o.x = x
    o.y = y
    o.movementSpeed = 120

    o.size = {x = 38, y = 60}
    o.image = nil
    o.animeFrame = 1

    o.health = 100
    o.fireRate = 0.15
    o.shootDelay = nil

	self.__index = self
   	return setmetatable(o, self)
end

function player:spawn(screen)
    self.screen = screen
    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', 'shmup_ship', 0, inkBrushMirrorType.Vertical)
    self.image.pos:Reparent(screen, -1)
end

function player:update(dt)
    if self.game.input.forward then
        self.y = self.y - self.movementSpeed * dt
    end
    if self.game.input.backwards then
        self.y = self.y + self.movementSpeed * dt
    end
    if self.game.input.right then
        self.x = self.x + self.movementSpeed * dt
    end
    if self.game.input.left then
        self.x = self.x - self.movementSpeed * dt
    end

    self.x = math.min(self.game.screenSize.x - self.size.x / 2, math.max(0 - self.size.x / 2, self.x))
    self.y= math.min(self.game.screenSize.y - self.size.y / 2, math.max(0 - self.size.y / 2, self.y))

    self.image.pos:SetMargin(self.x, self.y, 0, 0)

    if self.game.input.shoot then
        self:shoot()
    end
end

function player:shoot()
    if self.shootDelay then return end

    local p = require("modules/games/panzer/projectile"):new(self.game)
    p.x = self.x + (self.size.x / 2) - 4
    p.y = self.y
    p.velY = 100
    p.damage = 25
    p.targetTag = "enemy"
    p.atlasPath = 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas'
    p.atlasPart = "shmup_projectile"
    p.size = {x = 8, y = 8}

    p:spawn(self.screen)

    table.insert(self.game.projectiles, p)

    self.shootDelay = true
    Cron.After(self.fireRate, function ()
        self.shootDelay = false
    end)
end

function player:onDamage(damage)
    self.health = self.health - damage

    self.image.image:SetOpacity(0.6)

    Cron.After(0.1, function ()
        self.image.image:SetOpacity(1)
    end)
end

return player