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
    o.size = {x = 25, y = 45}
    o.scrollSpeed = scrollSpeed
    o.speed = 5
    o.health = health

    o.image = nil
    o.atlasPath = "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas"
    o.atlasPart = "shmup-av"

    o.thruster = nil
    o.thrusterCron = nil
    o.thrusterStage = 1

    o.targetX = 0

    o.shootCron = nil
    o.burstLength = 4
    o.currentBurst = 1
    o.recovery = false

	self.__index = self
    return setmetatable(o, self)
end

function enemy:spawn(screen)
    self.screen = screen

    self.image = ink.image(self.x, self.y, self.size.x, self.size.y, self.atlasPath, self.atlasPart, 0, inkBrushMirrorType.Vertical)
    self.image.pos:Reparent(screen, -1)

    self.thruster = ink.image(0, 6, self.size.x, 38, self.atlasPath, "shmup-av-propulsion", 0, inkBrushMirrorType.Vertical)
    self.thruster.pos:Reparent(self.image.pos)

    self.thusterCron = Cron.Every(0.15, function()
        local stage = inkBrushMirrorType.NoMirror

        if self.thrusterStage == 2 then
            stage = inkBrushMirrorType.Horizontal
        elseif self.thrusterStage == 3 then
            stage = inkBrushMirrorType.Vertical
        elseif self.thrusterStage == 4 then
            stage = inkBrushMirrorType.Both
        end

        self.thrusterStage = self.thrusterStage + 1
        if self.thrusterStage == 5 then self.thrusterStage = 1 end
        self.thruster.image:SetBrushMirrorType(stage)
    end)

    self.shootCron = Cron.Every(0.2,  function()
        if not self.recovery then
            self.currentBurst = self.currentBurst + 1

            local p = require("modules/games/panzer/projectile"):new(self.game, self.x, self.y + 38, 0, -100, 20, "player", self.atlasPath, "shmup_missile", {x = 3, y = 14}, true)
            p:spawn(screen)
            table.insert(self.game.projectiles, p)

            local p = require("modules/games/panzer/projectile"):new(self.game, self.x + 22, self.y + 38, 0, -100, 20, "player", self.atlasPath, "shmup_missile", {x = 3, y = 14}, true)
            p:spawn(screen)
            table.insert(self.game.projectiles, p)

            if self.currentBurst == self.burstLength then
                self.recovery = true
                self.currentBurst = self.burstLength * 2
            end
        else
            self.currentBurst = self.currentBurst - 1
            if self.currentBurst == 0 then self.recovery = false end
        end
    end)

    self.targetX = math.random(0, self.game.screenSize.x)

    table.insert(self.game.enemies, self)
end

function enemy:update(dt)
    -- self.y = self.y + self.scrollSpeed * dt
    -- if math.abs(self.targetX - self.x) > 5 then
    --     self.x = self.x + (self.targetX - self.x) / 80
    -- else
    --     self.targetX = math.random(0, self.game.screenSize.x)
    -- end

    self.y = self.y + self.scrollSpeed * dt
    if math.abs(self.targetX - self.x) > 3 then
        if self.x > self.targetX then
            self.x = self.x - dt * self.speed
        else
            self.x = self.x + dt * self.speed
        end
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