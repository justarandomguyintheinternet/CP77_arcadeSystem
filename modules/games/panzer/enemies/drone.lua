local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")
local Cron = require("modules/external/Cron")

enemy = {}

function enemy:new(game, x, y, scrollSpeed, health)
	local o = {}

    o.game = game
    o.screen = nil

    o.x = x
    o.y = y
    o.size = {x = 25, y = 30}
    o.scrollSpeed = scrollSpeed
    o.speed = 7
    o.health = health

    o.image = nil
    o.atlasPath = "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas"
    o.atlasPart = "shmup_drone"

    o.thruster = nil
    o.thrusterCron = nil
    o.thrusterStage = 1

    o.targetX = 0

    o.fireRate = 0.4

	self.__index = self
    return setmetatable(o, self)
end

function enemy:spawn(screen)
    self.screen = screen

    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, self.atlasPath, self.atlasPart, 0, inkBrushMirrorType.Vertical)
    self.image.pos:Reparent(screen, -1)

    self.thruster = ink.image(0, 12, self.size.x, self.size.y - 16, self.atlasPath, "shmup_drone-propulsion", 0, inkBrushMirrorType.Vertical)
    self.thruster.pos:Reparent(self.image.pos)

    self.thusterCron = Cron.Every(0.15, function()
        local stage = inkBrushMirrorType.NoMirror

        if self.thrusterStage == 2 then
            stage = inkBrushMirrorType.Horizontal
        end

        self.thrusterStage = self.thrusterStage + 1
        if self.thrusterStage == 3 then self.thrusterStage = 1 end
        self.thruster.image:SetBrushMirrorType(stage)
    end)

    self.shootCron = Cron.Every(self.fireRate,  function()
        local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, 0, -100, 20, "player", self.atlasPath, "shmup_projectile", {x = 6, y = 6}, false)
        p:spawn(screen)
        table.insert(self.game.projectiles, p)
    end)

    self.targetX = math.random(0, self.game.screenSize.x)

    table.insert(self.game.enemies, self)
end

function enemy:update(dt)
    self.y = self.y + self.scrollSpeed * dt

    if math.abs(self.targetX - self.x) > 15 then
        self.x = self.x + (self.targetX - self.x) / 80
    else
        self.targetX = math.random(0, self.game.screenSize.x)
    end

    self.image.pos:SetMargin(self.x, self.y, 0, 0)
end

function enemy:onDamage(damage)
    self.health = self.health - damage

    if self.health < 0 then
        self:destroy()
    else
        self.image.image:SetOpacity(0.6)
        self.thruster.image:SetOpacity(0.1)

        Cron.After(0.1, function ()
            self.image.image:SetOpacity(1)
            self.thruster.image:SetOpacity(1)
        end)
    end
end

function enemy:destroy()
    self:despawn()

    local exp = require("modules/games/panzer/explosion"):new(self.game, self.x, self.y, self.size.y, self.size, 0.15)
    exp:spawn(self.screen)
end

function enemy:despawn()
    Cron.Halt(self.thusterCron)
    Cron.Halt(self.shootCron)
    self.image.image:SetVisible(false)
    self.thruster.image:SetVisible(false)
    utils.removeItem(self.game.enemies, self)
end

return enemy