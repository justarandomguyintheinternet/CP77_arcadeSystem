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

    o.fireRate = 0.4

	self.__index = self
    return setmetatable(o, self)
end

function enemy:spawn(screen)
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
        local p = require("modules/games/panzer/projectile"):new(self.game, self.x + self.size.x / 2, self.y + self.size.y, 0, -120, 20, "player", self.atlasPath, "shmup-title_flare2", {x = 6, y = 6}, false)
        p:spawn(screen)
        table.insert(self.game.projectiles, p)
    end)

    self.targetX = math.random(0, self.game.screenSize.x)

    table.insert(self.game.enemies, self)
end

function enemy:update(dt)
    self.y = self.y + self.scrollSpeed * dt

    if math.abs(self.targetX - self.x) > 14 then
        self.x = self.x + (self.targetX - self.x) / 120
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
    Cron.Halt(self.animeCron)
    Cron.Halt(self.shootCron)
    self.image.image:SetVisible(false)
    utils.removeItem(self.game.enemies, self)
end

return enemy