local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")
local Cron = require("modules/external/Cron")

mech = {}

function mech:new(game, x, y, scrollSpeed, health, movementSpeed, damage, hpPayback)
	local o = {}

    o.game = game
    o.screen = nil

    o.x = x
    o.y = y
    o.size = {x = 25, y = 30}
    o.scrollSpeed = scrollSpeed
    o.speed = movementSpeed or 120
    o.health = health

    o.image = nil
    o.atlasPath = "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas"
    o.atlasParts = {
        "shmup_bot01",
        "shmup_bot02",
        "shmup_bot03",
        "shmup_bot04",
        "shmup_bot05",
        "shmup_bot06"
    }

    o.animeCron = nil
    o.animeSpeed = 0.2
    o.animeStage = 1

    o.targetX = 0

    o.shootCron = nil
    o.fireRate = 0.4
    o.damage = damage or 5

    o.hpPayback = hpPayback or o.health / 5

	self.__index = self
    return setmetatable(o, self)
end

function mech:spawn(screen)
    self.screen = screen

    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, self.atlasPath, self.atlasParts[self.animeStage], 0, inkBrushMirrorType.Vertical)
    self.image.pos:Reparent(screen, -1)

    self.animeCron = Cron.Every(self.animeSpeed, function()
        self.image.image:SetTexturePart(self.atlasParts[self.animeStage])

        self.animeStage = self.animeStage + 1
        if self.animeStage > 6 then
            self.animeStage = 1
        end
    end)

    self.shootCron = Cron.Every(self.fireRate,  function()
        local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, 0, -120, self.damage, "player", self.atlasPath, "shmup-title_flare2", {x = 6, y = 6}, false)
        p:spawn(screen)
        table.insert(self.game.projectiles, p)
        utils.playSound("dev_drone_griffin_default_wea_rifle_fire_auto_voice_02_stop")
    end)

    self.targetX = math.random(0, self.game.screenSize.x)

    table.insert(self.game.enemies, self)
end

function mech:update(dt)
    self.y = self.y + self.scrollSpeed * dt

    if math.abs(self.targetX - self.x) > 14 then
        self.x = self.x + (self.targetX - self.x) / self.speed
    else
        self.targetX = math.random(0, self.game.screenSize.x)
    end

    self.image.pos:SetMargin(self.x, self.y, 0, 0)

    if self.y > self.game.screenSize.y + self.size.y then self:despawn() end
end

function mech:onDamage(damage)
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

function mech:destroy()
    self:despawn(true)
    utils.playSound("dev_fire_extinguisher_explode", 2)

    local exp = require("modules/games/panzer/explosion"):new(self.game, self.x, self.y, self.size.y, self.size, 0.15)
    exp:spawn(self.screen)

    self.game.player.health = self.game.player.health + self.hpPayback
end

function mech:despawn(hard)
    Cron.Halt(self.animeCron)
    Cron.Halt(self.shootCron)

    if hard then
        self.image.image:SetVisible(false)
    end

    self.game.enemies[utils.indexValue(self.game.enemies, self)] = nil
end

return mech