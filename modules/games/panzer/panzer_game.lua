local color = require("modules/ui/color")
local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")
local utils = require("modules/util/utils")

game = {}

function game:new(arcadeSys, arcade)
	local o = {}

    o.as = arcadeSys
    o.arcade = arcade
	o.screenSize = {x = 320, y = 240} -- Size of arcade screen

	o.inMenu = true
	o.inBoard = false
	o.inGame = false
	o.initialized = false

	o.screen = nil

	o.menuScreen = nil -- Menu screen
	o.selectorInk = nil
	o.selectedItem = 1

	o.gameScreen = nil

	o.player = nil
	o.input = {forward = false, backwards = false, right = false, left = false, shoot = false}
	o.keys = {}
	o.animeCron = nil

	o.score = 0
	o.scoreInk = nil

	o.gameOver = false
	o.gameOverText = nil
	o.hsText = nil
	o.continueText = nil
	o.healthText = nil

	o.highscore = 0
	o.boardScreen = nil
	o.leaderboard = nil

	o.bg1 = nil
	o.bg2 = nil
	o.bgY = 600
	o.scrollSpeed = 0.3

	o.projectiles = {}
	o.enemies = {}
	o.explosions = {}

	o.enemySpawning = nil
	o.chances = {
		["av"] = 30,
		["mech"] = 70,
		["drone"] = 100,
		["station"] = 40
	}
	o.spawnChance = 10

	o.menuMusic = "mus_sq029_vr_game_01_loop_START"
	o.gameMusic = "mus_mq022_maglev_01_START"

	self.__index = self
   	return setmetatable(o, self)
end

function game:init() -- Init the screen, can be left as is
    local rootWidget = self.arcade:getObject().uiComponent:GetGameController():GetRootCompoundWidget()

	rootWidget:GetWidgetByPath(BuildWidgetPath({'main_display'})):SetVisible(false) -- Disable video

    local area = inkCanvas.new() -- Base canvas
	area:SetInteractive(true)
	area:SetName('area')
	area:SetAnchor(inkEAnchor.Centered)
	area:SetMargin(inkMargin.new({ left = 0.0, top = 0.0, right = 0.0, bottom = 0.0 }))
	area:Reparent(rootWidget, -1)

	self.screen = inkCanvas.new() -- Canvas to draw on
	self.screen:SetName("mainCanvas")
	self.screen:SetSize(self.screenSize.x, self.screenSize.y)
	self.screen:SetAnchorPoint(Vector2.new({ X = 0.5, Y = 0.5 }))
	self.screen:Reparent(area, -1)
end

function game:showDefault() -- Show the default home screen
	self.menuScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.menuScreen:Reparent(self.screen, -1)

	self.bg1 = ink.image(0, -100, self.screenSize.x, self.screenSize.y, "base\\gameplay\\gui\\world\\arcade_games\\quadracer\\quadracer_assets.inkatlas", "sky", 0, inkBrushMirrorType.Vertical)
	self.bg1.pos:Reparent(self.menuScreen, -1)

	self.bg2 = ink.image(0, 50, self.screenSize.x, self.screenSize.y, "base\\gameplay\\gui\\world\\arcade_games\\contra\\run_and_gun_bkgrnd_spritesheet.inkatlas", "Sky")
	self.bg2.pos:Reparent(self.menuScreen, -1)

	self.bgFlare1 = ink.image(40, 45, 20, 20, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup-title_flare1", 30, inkBrushMirrorType.Vertical)
	self.bgFlare1.pos:Reparent(self.menuScreen, -1)

	self.bgFlare2 = ink.image(205, 20, 20, 20, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup-title_flare1", 60, inkBrushMirrorType.Vertical)
	self.bgFlare2.pos:Reparent(self.menuScreen, -1)

	self.bgFlare3 = ink.image(220, 80, 15, 15, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup-title_flare1", -45, inkBrushMirrorType.Vertical)
	self.bgFlare3.pos:Reparent(self.menuScreen, -1)

	self.titelPlayer = ink.image(160, 180, 38, 60, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup_ship", 0, inkBrushMirrorType.Vertical)
	self.titelPlayer.pos:Reparent(self.menuScreen, -1)

	self.titelE1 = ink.image(250, 50, 50, 90, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup-av", 0, inkBrushMirrorType.Vertical)
	self.titelE1.pos:Reparent(self.menuScreen, -1)

	self.titelExp = ink.image(250, 50, 65, 65, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup-blast2", 0, inkBrushMirrorType.Vertical)
	self.titelExp.pos:Reparent(self.menuScreen, -1)

	self.titelE2 = ink.image(45, 80, 50, 60, 'base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas', "shmup_bot01", 0, inkBrushMirrorType.Vertical)
	self.titelE2.pos:Reparent(self.menuScreen, -1)

	self.titelFluff = ink.text("[c] kWStudios Co. Ltd. 2067\n All rights reserved.", 15, self.screenSize.y - 30, 8)
	self.titelFluff:Reparent(self.menuScreen, -1)

    local area = ink.canvas(45, 10)
    area:Reparent(self.menuScreen, -1)

    ink.text("Panzer", 20, 0, 50, color.orange):Reparent(area, -1)
    ink.text("Shooter", 40, 50, 40, color.yellow):Reparent(area, -1)
	ink.text("XTREME", 150, 50, 40, color.red, nil, nil, 45):Reparent(area, -1)

	local buttons = ink.canvas(110, 110)
    buttons:Reparent(self.menuScreen, -1)

	self.selectorInk = ink.rect(0, 0, 120, 25, color.red)
	self.selectorInk:Reparent(buttons, -1)

    ink.text("Play [2 E$]", 0, 0, 25):Reparent(buttons, -1)
    ink.text("Leaderboard", 0, 30, 25):Reparent(buttons, -1)
	ink.text("Exit", 0, 60, 25):Reparent(buttons, -1)

	self:loadHighscore()
end

function game:onEnteredWorkspot() -- Gets called once after entering the workspot
	utils.playSound(self.menuMusic)
end

function game:update(dt) -- Runs every frame once fully in workspot
	if not self.initialized then
		self.initialized = true
		self:onEnteredWorkspot()
	end
	if self.inGame and not self.gameOver then
		self.player:update(dt)
		self:updateProjectiles(dt)
		self:updateEnemies(dt)
		self:renderBG(dt)
		self:renderHealth()
	end
end

function game:handleInput(action) -- Passed forward from onAction
	local actionName = Game.NameToString(action:GetName(action))
	local actionType = action:GetType(action).value

	if utils.has_value(self.keys, actionName) then return end

	table.insert(self.keys, actionName)
	Cron.NextTick(function ()
		utils.removeItem(self.keys, actionName)
	end)

	if actionName == 'UI_Apply' then
		if actionType == 'BUTTON_PRESSED' then
			self:handleMenuInput("interact")
		end
	elseif actionName == 'ChoiceScrollDown' then
		if actionType == 'BUTTON_PRESSED' then
			self:handleMenuInput("down")
		end
	elseif actionName == 'ChoiceScrollUp' then
		if actionType == 'BUTTON_PRESSED' then
			self:handleMenuInput("up")
		end
	elseif actionName == 'QuickMelee' then
		if actionType == 'BUTTON_PRESSED' then
			self:goBack()
		end
	elseif actionName == 'Jump' then
		if actionType == 'BUTTON_PRESSED' then
			self.input.shoot = true
			if self.inGame and self.gameOver then
				self:goBack()
			end
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.shoot = false
		end
	elseif actionName == 'Reload' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.chargeShoot = true
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.chargeShoot = false
		end
	elseif actionName == 'Forward' then
		if actionType == 'BUTTON_PRESSED' then
			self.input.forward = true
			self.input.analogForward = 1
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.forward = false
			self.input.analogForward = 0
		end
	elseif actionName == 'Back' then
		if actionType == 'BUTTON_PRESSED' then
			self.input.backwards = true
			self.input.analogForward = -1
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.backwards = false
			self.input.analogForward = 0
		end
	elseif actionName == 'Left' then
		if actionType == 'BUTTON_PRESSED' then
			self.input.left = true
			self.input.analogRight = -1
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.left = false
			self.input.analogRight = 0
		end
	elseif actionName == 'Right' then
		if actionType == 'BUTTON_PRESSED' then
			self.input.right = true
			self.input.analogRight = 1
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.right = false
			self.input.analogRight = 0
		end
	end

	if actionName == "MoveX" then -- Controller movement
		local x = action:GetValue(action)
		if x < 0 then
			self.input.left = true
			self.input.right = false
			self.input.analogRight = -x
		else
			self.input.right = true
			self.input.left = false
			self.input.analogRight = x
		end
		if x == 0 then
			self.input.right = false
			self.input.left = false
			self.input.analogRight = 0
		end
	end

	if actionName == "MoveY" then
		local x = action:GetValue(action)
		if x < 0 then
			self.input.backwards = true
			self.input.forward = false
			self.input.analogForward = -x
		else
			self.input.backwards = false
			self.input.forward = true
			self.input.analogForward = x
		end
		if x == 0 then
			self.input.backwards = false
			self.input.forward = false
			self.input.analogForward = 0
		end
	end
end

function game:handleMenuInput(key)
	if not self.inMenu then return end

	if key == "interact" then
		self.selectorInk:SetTintColor(color.darkred)
		Cron.After(0.1, function ()
			self.selectorInk:SetTintColor(color.red)

			if self.selectedItem == 3 then
				self.as.logic:tryExitWorkspot()
			elseif self.selectedItem == 2 then
				self:switchToBoard()
			elseif self.selectedItem == 1 then
				utils.stopSound(self.menuMusic)
				utils.playSound(self.gameMusic, 2)
				self:switchToGame()
			end
		end)

		utils.playSound("ui_loot_additional")
	elseif key == "up" then
		self.selectedItem = self.selectedItem - 1
		if self.selectedItem < 1 then
			self.selectedItem = 3
		end
		self:selectMenuItem()
		utils.playSound("ui_menu_onpress")
	elseif key == "down" then
		self.selectedItem = self.selectedItem + 1
		if self.selectedItem > 3 then
			self.selectedItem = 1
		end
		self:selectMenuItem()
		utils.playSound("ui_menu_onpress")
	end
end

function game:goBack()
	if self.inMenu then
		self.as.logic:tryExitWorkspot()
	elseif self.inBoard then
		self:switchToMenu()
	elseif self.inGame then
		utils.stopSound(self.gameMusic)
		utils.playSound(self.menuMusic)
		utils.stopSound("mus_q108_concert_glitch_nr1_START")

		self:switchToMenu()
		self.enemies = {}
	end
end

function game:switchToMenu()
	utils.hideCustomHints()
	self:showHints("menu")

	self.menuScreen:SetVisible(true)
	if self.gameScreen then self.gameScreen:SetVisible(false) end
	if self.boardScreen then self.boardScreen:SetVisible(false) end

	if self.inGame then
		self.gameOver = false

		self.gameOverText:SetVisible(false)
		self.hsText:SetVisible(false)
		self.continueText:SetVisible(false)
		self:despawnAllObjects()

		self.gameScreen = nil

		Cron.Halt(self.enemySpawning)
	end

	self.inMenu = true
	self.inBoard = false
	self.inGame = false
end

function game:despawnAllObjects()
	for _, e in pairs(self.enemies) do
		e:despawn(false)
	end

	for _, p in pairs(self.projectiles) do
		p:despawn()
	end
end

function game:switchToGame()
	utils.hideCustomHints()
	self:showHints("game")

	utils.spendMoney(2)
	if not self.gameScreen then
		self:initGame()
	end
	self.menuScreen:SetVisible(false)
	self.gameScreen:SetVisible(true)

	self.inMenu = false
	self.inGame = true

	self.score = 0
	self:startEnemySpawning()
end

function game:switchToBoard() -- Switch to leaderboard
	utils.hideCustomHints()
	self:showHints("board")

	if not self.boardScreen then
		self:initBoard()
	end
	self.menuScreen:SetVisible(false)
	self.boardScreen:SetVisible(true)

	self.inMenu = false
	self.inBoard = true
end

function game:initGame()
	-- Init game screen canvas
	self.gameScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.gameScreen:Reparent(self.screen, -1)
	self.gameScreen:SetVisible(false)

	-- Init both BG images
	self.bg1 = ink.image(0, 0, self.screenSize.x, self.bgY + 3, "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas", "BG", 0, inkBrushMirrorType.Vertical)
	self.bg1.pos:Reparent(self.gameScreen, -1)
	self.bg2 = ink.image(0, -self.bgY, self.screenSize.x, self.bgY + 3, "base\\gameplay\\gui\\world\\arcade_games\\panzer\\hishousai-panzer-spritesheet.inkatlas", "BG", 0, inkBrushMirrorType.Vertical)
	self.bg2.pos:Reparent(self.gameScreen, -1)

	-- Score text during gameplay
	self.scoreInk = ink.text("Score: 0", 20, 10, 20)
	self.scoreInk:Reparent(self.gameScreen, -1)

	self.gameOverText = ink.text("GAME OVER", 35, 90, 55, color.red)
	self.gameOverText:SetVisible(false)
	self.gameOverText:Reparent(self.gameScreen, -1)

	-- Score text when game is over
	self.hsText = ink.text("", 85, 140, 25, HDRColor.new({ Red = 0, Green = 1.25, Blue = 0, Alpha = 1 }))
	self.hsText:SetVisible(false)
	self.hsText:Reparent(self.gameScreen, -1)

	self.continueText = ink.text("Press SHOOT to continue", 85, 210, 15)
	self.continueText:SetVisible(false)
	self.continueText:Reparent(self.gameScreen, -1)

	-- Spawn player
	self.player = require("modules/games/panzer/player"):new(self.screenSize.x / 2, self.screenSize.y / 2, self)
	self.player:spawn(self.gameScreen)

	-- Player health text
	self.healthText = ink.text(tostring("HP: " .. self.player.health), 240, 10, 20)
	self.healthText:Reparent(self.gameScreen, -1)
end

function game:startEnemySpawning()
	self.bag = {}

	for k, v in pairs(self.chances) do
		for _ = 0, v do
			table.insert(self.bag, k)
		end
	end

	self.enemySpawning = Cron.Every(0.3, function()
		if #self.enemies > 8 then return end

		if math.random() < (self.spawnChance / 100) + self.score / 25000 then
			local pick = self.bag[math.random(#self.bag)]

			local speed = math.min(1, self.score / 15000)
			self.player.damage = self.player.originalDamage + speed * 18

			if pick == "av" then
				local e = require("modules/games/panzer/enemies/avEnemy"):new(self, math.random(0, self.screenSize.x), 0, 4, 40, 5 + speed * 2, 3 + speed * 3)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			elseif pick == "drone" then
				local e = require("modules/games/panzer/enemies/drone"):new(self, math.random(0, self.screenSize.x), 0, 5, 25, 80 + speed * 20, 2 + speed * 2)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			elseif pick == "mech" then
				local e = require("modules/games/panzer/enemies/mech"):new(self, math.random(0, self.screenSize.x), 0, 6, 20, 120 + speed * 40, 3 + speed * 3)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			elseif pick == "station" then
				local e = require("modules/games/panzer/enemies/stationary"):new(self, math.random(0, self.screenSize.x), 0, 30, nil, 1 + speed)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			end
		end
	end)
end

function game:initBoard()
	self.boardScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.boardScreen:Reparent(self.screen, -1)
	self.boardScreen:SetVisible(false)

	self.leaderboard = require("modules/ui/leaderboard"):new(10, function ()
		return math.random(15, 150) * 50
	end)
	self.leaderboard:spawn(self.highscore):Reparent(self.boardScreen, -1)
	self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
end

function game:renderBG(dt) -- Move background
	local ySpeed = self.scrollSpeed * (dt / 0.016)

	local margin = self.bg1.pos:GetMargin()
	if margin.top > self.bgY then
		margin.top = -self.bgY
	end

	margin.top = margin.top + ySpeed
	self.bg1.pos:SetMargin(margin)

	local margin = self.bg2.pos:GetMargin()
	if margin.top > self.bgY then
		margin.top = -self.bgY
	end

	margin.top = margin.top + ySpeed
	self.bg2.pos:SetMargin(margin)
end

function game:lost()
	self:despawnAllObjects()
	Cron.Halt(self.enemySpawning)

	self.gameOver = true
	self.gameOverText:SetVisible(true)

	if self.score > self.highscore then
		self.highscore = math.floor(self.score + 0.5)
		self:saveHighscore(self.highscore)
		if self.boardScreen then
			self.leaderboard:update(self.highscore):Reparent(self.boardScreen, -1)
			self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
		end
		self.hsText:SetVisible(true)
		self.hsText:SetText(tostring("New Highscore: " .. self.score))
	end

	self.continueText:SetVisible(true)

	utils.stopSound(self.gameMusic)
	utils.playSound("mus_q108_concert_glitch_nr1_START", 2)
end

function game:renderHealth()
	self.healthText:SetText(tostring("HP: " .. math.floor(self.player.health)))
	self.scoreInk:SetText(tostring("Score: " .. math.floor(self.score)))
end

function game:updateProjectiles(dt)
	for _, p in pairs(self.projectiles) do
		p:update(dt)
		if p.targetTag == "player" and p.x + p.size.x > self.player.x and p.x < self.player.x + self.player.size.x and p.y + p.size.y > self.player.y and p.y < self.player.y + self.player.size.y then
			self.player:onDamage(p.damage)
			p:despawn()
		end

		if p.targetTag == "enemy" then
			for _, e in pairs(self.enemies) do
				if p.x + p.size.x > e.x and p.x < e.x + e.size.x and p.y + p.size.y > e.y and p.y < e.y + e.size.y then
					e:onDamage(p.damage)
					p:despawn()
				end
			end
		end
	end
end

function game:updateEnemies(dt)
	for _, e in pairs(self.enemies) do
		e:update(dt)
	end
end

function game:selectMenuItem() -- Moves the selector rectangle
	local i = self.selectedItem - 1
	local height = 30

	self.selectorInk:SetMargin(inkMargin.new({ left = 0, top = i * height, right = 0.0, bottom = 0.0 }))
end

function game:loadHighscore()
	CName.add("arcade_panzer")
	self.highscore = Game.GetQuestsSystem():GetFactStr('arcade_panzer')
end

function game:saveHighscore(score)
	Game.GetQuestsSystem():SetFactStr('arcade_panzer', math.floor(score + 0.5))
end

function game:showHints(stage)
	if stage == "menu" then
		utils.showInputHint("ChoiceScrollDown", "Scroll up")
		utils.showInputHint("ChoiceScrollUp", "Scroll down")
		utils.showInputHint("UI_Apply", "Select")
		utils.showInputHint("QuickMelee", "Back")
	elseif stage == "board" then
		utils.showInputHint("QuickMelee", "Back")
	elseif stage == "game" then
		utils.showInputHint("Jump", "Shoot")
		utils.showInputHint("Reload", "[HOLD] Charge Shot", true)
		utils.showInputHint("QuickMelee", "Back")
	end
end

function game:stop() -- Gets called when leaving workspot
	self:switchToMenu()
	utils.stopSound(self.menuMusic)
	utils.stopSound(self.gameMusic)
	utils.stopSound("mus_q108_concert_glitch_nr1_START")
	utils.stopSound("w_gun_shotgun_tech_satara_charge")

	self.screen:RemoveChild(self.gameScreen)
	self.gameScreen = nil
	self.initialized = false
	utils.hideCustomHints()
end

return game