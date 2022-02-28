local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")
local utils = require("modules/util/utils")

player = {}

function player:new(x, y, game)
	local o = {}

    o.game = game
    o.screen = screen
    o.x = x
    o.y = y
    o.movementSpeed = 140
    o.originalSpeed = o.movementSpeed

    o.size = {x = 38, y = 60}
    o.image = nil
    o.animeFrame = 1

    o.health = 100
    o.damage = 5
    o.originalDamage = o.damage
    o.fireRate = 0.15
    o.shootDelay = nil

    o.chargeTime = 0
    o.chargeImage = nil
    o.chargeMult = 25

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
        self.y = self.y - (self.movementSpeed * dt) * self.game.input.analogForward
    end
    if self.game.input.backwards then
        self.y = self.y + (self.movementSpeed * dt) * self.game.input.analogForward
    end
    if self.game.input.right then
        self.x = self.x + (self.movementSpeed * dt) * self.game.input.analogRight
    end
    if self.game.input.left then
        self.x = self.x - (self.movementSpeed * dt) * self.game.input.analogRight
    end

    if self.game.input.chargeShoot then
        self.chargeTime = self.chargeTime + dt
        self.chargeTime = math.min(self.chargeTime, 1.5)

        if not self.chargeImage then
            utils.playSound("w_gun_shotgun_tech_satara_charge", 7)
            self.chargeImage = ink.image(self.size.x / 2, 0, 1, 1, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup_projectile", 0, inkBrushMirrorType.Vertical)
            self.chargeImage.pos:Reparent(self.image.pos, -1)
        end

        local size = self.chargeMult * self.chargeTime
        self.chargeImage.image:SetMargin(size, size, 0, 0)
        self.chargeImage.pos:SetMargin((self.size.x / 2) - math.floor(size / 2), -math.floor(size), 0, 0)

        self.movementSpeed = self.originalSpeed - (self.originalSpeed * self.chargeTime / 2)
    elseif self.chargeTime ~= 0 then
        self:releaseCharge()

        utils.stopSound("w_gun_shotgun_tech_satara_charge")
        utils.playSound("dev_surveillance_camera_detect", 3)
        self.image.pos:RemoveChild(self.chargeImage.pos)
        self.chargeImage = nil
        self.chargeTime = 0
        self.movementSpeed = self.originalSpeed
    end

    self.x = math.min(self.game.screenSize.x - self.size.x / 2, math.max(0 - self.size.x / 2, self.x))
    self.y= math.min(self.game.screenSize.y - self.size.y / 2, math.max(0 - self.size.y / 2, self.y))

    self.image.pos:SetMargin(self.x, self.y, 0, 0)

    if self.game.input.shoot then
        self:shoot()
    end

    if self.health == 0 then
        self:onDeath()
    end
end

function player:shoot()
    if self.shootDelay then return end

    local p = require("modules/games/panzer/projectile"):new(self.game)
    p.x = self.x + (self.size.x / 2) - 4
    p.y = self.y
    p.velY = 100
    p.damage = self.damage
    p.targetTag = "enemy"
    p.atlasPath = 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas'
    p.atlasPart = "shmup_projectile"
    p.size = {x = 8, y = 8}

    p:spawn(self.screen)
    p.image.image:SetTintColor(color.new(0, 2, 0, 2))

    table.insert(self.game.projectiles, p)

    utils.playSound("w_gun_npc_achilles_fire_charged_voice_03")

    self.shootDelay = true
    Cron.After(self.fireRate, function ()
        self.shootDelay = false
    end)
end

function player:releaseCharge()
    if self.chargeTime < 0.2 then return end

    local p = require("modules/games/panzer/projectile"):new(self.game)
    p.x = self.x + self.chargeImage.pos:GetMargin().left
    p.y = self.y + self.chargeImage.pos:GetMargin().top
    p.velY = 100 - self.chargeMult * self.chargeTime
    p.damage = self.damage * self.chargeTime * 5
    p.targetTag = "enemy"
    p.atlasPath = 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas'
    p.atlasPart = "shmup_projectile"
    p.size = {x = self.chargeMult * self.chargeTime, y = self.chargeMult * self.chargeTime}
    p.isExplosive = true

    p:spawn(self.screen)
    --p.image.image:SetTintColor(color.new(1, 0, 0, 1))

    table.insert(self.game.projectiles, p)
end

function player:onDamage(damage)
    utils.playSound("w_feedback_player_damage", 5)

    self.health = math.max(0, self.health - damage)

    self.image.image:SetOpacity(0.6)

    Cron.After(0.1, function ()
        if not self.image then return end

        self.image.image:SetOpacity(1)
    end)
end

function player:onDeath()
    collectgarbage()

    utils.playSound("v_panzer_dst_fx_explosion")
    utils.stopSound("w_gun_shotgun_tech_satara_charge")

    local exp = require("modules/games/panzer/explosion"):new(self.game, self.x, self.y, self.size.y + 20, self.size, 0.2)
    exp:spawn(self.screen)

    self.image.pos:RemoveChild(self.image.image)
    self.screen:RemoveChild(self.image.pos)
    self.image = nil

    self.game:lost()
end

return player