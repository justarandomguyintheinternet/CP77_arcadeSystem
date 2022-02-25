local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")
local Cron = require("modules/external/Cron")

enemy = {}

function enemy:new(game, x, y, health)
	local o = {}

    o.game = game
    o.screen = nil

    o.x = x
    o.y = y
    o.size = {x = 20, y = 25}
    o.speed = 5
    o.health = health

    o.image = nil
    o.atlasPath = "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas"
    o.atlasPart = "shmup_drone"

    o.shootCron = nil
    o.burstLength = 8
    o.currentBurst = 1
    o.recovery = false

    o.bulletSize = {x = 5, y = 5}
    o.damage = 5

	self.__index = self
    return setmetatable(o, self)
end

function enemy:spawn(screen)
    self.screen = screen

    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, self.atlasPath, self.atlasPart, 0, inkBrushMirrorType.Both)
    self.image.pos:Reparent(screen, -1)

    self.shootCron = Cron.Every(0.2,  function()
        if not self.recovery then
            self.currentBurst = self.currentBurst + 1

            local ySpeed = -100

            local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, -120, ySpeed, self.damage, "player", self.atlasPath, "shmup_projectile", self.bulletSize, false)
            p:spawn(screen)
            table.insert(self.game.projectiles, p)

            local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, -50, ySpeed, self.damage, "player", self.atlasPath, "shmup_projectile", self.bulletSize, false)
            p:spawn(screen)
            table.insert(self.game.projectiles, p)

            local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, 50, ySpeed, self.damage, "player", self.atlasPath, "shmup_projectile", self.bulletSize, false)
            p:spawn(screen)
            table.insert(self.game.projectiles, p)

            local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, 120, ySpeed, self.damage, "player", self.atlasPath, "shmup_projectile", self.bulletSize, false)
            p:spawn(screen)
            table.insert(self.game.projectiles, p)

            if self.currentBurst == self.burstLength then
                self.recovery = true
                self.currentBurst = math.floor(self.burstLength * 2.5)
            end
        else
            self.currentBurst = self.currentBurst - 1
            if self.currentBurst == 0 then self.recovery = false end
        end
    end)

    table.insert(self.game.enemies, self)
end

function enemy:update(dt)
    self.y = self.y + self.game.scrollSpeed * (dt / 0.016)

    self.image.pos:SetMargin(self.x, self.y, 0, 0)
end

function enemy:onDamage(damage)
    self.health = self.health - damage

    if self.health < 0 then
        self:destroy()
    else
        self.image.image:SetOpacity(0.6)

        Cron.After(0.1, function ()
            self.image.image:SetOpacity(1)
        end)
    end
end

function enemy:destroy()
    self:despawn()

    local exp = require("modules/games/panzer/explosion"):new(self.game, self.x, self.y, self.size.y, self.size, 0.15)
    exp:spawn(self.screen)
end

function enemy:despawn()
    Cron.Halt(self.shootCron)
    self.image.image:SetVisible(false)
    utils.removeItem(self.game.enemies, self)
end

return enemy