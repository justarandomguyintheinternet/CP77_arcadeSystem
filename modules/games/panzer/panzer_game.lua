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
		["av"] = 35,
		["mech"] = 70,
		["drone"] = 100,
		["station"] = 40
	}
	o.spawnChance = 15

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

    local area = ink.canvas(45, 10)
    area:Reparent(self.menuScreen, -1)

	ink.rect(160, 120, 400, 400, HDRColor.new({ Red = 0, Green = 0.7, Blue = 1, Alpha = 1.0 }), 0, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1) -- bg
	ink.circle(250, 10, 65, HDRColor.new({ Red = 1, Green = 0.75, Blue = 0, Alpha = 1.0 })):Reparent(area, -1)

	ink.rect(20, 300, 400, 400, HDRColor.new({ Red = 0, Green = 0.7, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)
	ink.rect(100, 280, 400, 400, HDRColor.new({ Red = 0, Green = 0.9, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)
	ink.rect(160, 310, 400, 400, HDRColor.new({ Red = 0, Green = 0.4, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)
	ink.rect(255, 320, 400, 400, HDRColor.new({ Red = 0, Green = 0.7, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)

    ink.text("Panzer", 40, 0, 50, color.yellow):Reparent(area, -1)
    ink.text("Game", 100, 50, 40, color.red):Reparent(area, -1)

    local buttons = ink.canvas(110, 110)
    buttons:Reparent(self.menuScreen, -1)

	self.selectorInk = ink.rect(0, 0, 120, 25, HDRColor.new({ Red = 0, Green = 0.5, Blue = 0.5, Alpha = 1 }))
	self.selectorInk:Reparent(buttons, -1)

    ink.text("Play [2 E$]", 0, 0, 25):Reparent(buttons, -1)
    ink.text("Leaderboard", 0, 30, 25):Reparent(buttons, -1)
	ink.text("Exit", 0, 60, 25):Reparent(buttons, -1)

	self:loadHighscore()
end

function game:update(dt) -- Runs every frame once fully in workspot
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
		self.selectorInk:SetTintColor(color.new(0, 0.8, 0.8))
		Cron.After(0.1, function ()
			self.selectorInk:SetTintColor(color.new(0, 0.5, 0.5))
		end)

		if self.selectedItem == 3 then
			self.as.logic:tryExitWorkspot()
		elseif self.selectedItem == 2 then
			self:switchToBoard()
		elseif self.selectedItem == 1 then
			self:switchToGame()
		end
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

	self.enemySpawning = Cron.Every(0.5, function()
		if #self.enemies > 8 then return end

		if math.random() < (self.spawnChance / 100) + self.score / 100000 then
			local pick = self.bag[math.random(#self.bag)]

			if pick == "av" then
				local e = require("modules/games/panzer/enemies/avEnemy"):new(self, math.random(0, self.screenSize.x), 0, 4, 100)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			elseif pick == "drone" then
				local e = require("modules/games/panzer/enemies/drone"):new(self, math.random(0, self.screenSize.x), 0, 5, 100)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			elseif pick == "mech" then
				local e = require("modules/games/panzer/enemies/mech"):new(self, math.random(0, self.screenSize.x), 0, 6, 100)
				e.y = -e.size.y
				e:spawn(self.gameScreen)
			elseif pick == "station" then
				local e = require("modules/games/panzer/enemies/stationary"):new(self, math.random(0, self.screenSize.x), 0, 150)
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

function game:renderTubes(dt) -- Draw and move the tubes
	local closest = 1000000

	local add = math.min(self.tubesPassed / 2, 30)
	moveX = (dt * (80 + add))
	for _, tube in pairs(self.tubes) do
		local x = tube.x
		local y = tube.y
		local gap = nil

		x = x - moveX
		if x < -200 then
			y = 50 + math.random() * 150
			gap = math.max(70, self.startHeight - self.tubesPassed * 1)

			x = self:getRightestTube().x + (self.startWidth - self.tubesPassed)
			x = math.max(850, x)
		end

		tube:setPos(x, y, gap)

		if math.abs(x - self.player.x) < math.abs(closest) then
			closest = x - self.player.x
		end

		if tube:playerCollides(self.player.x, self.player.y, 10) then
			self:lost()
		end
	end

	self.scoreInk:SetText(tostring("Score: " .. self.tubesPassed))
	if closest < 0 and self.player.closestTube > 0 then
		self.tubesPassed = self.tubesPassed + 1
	end
	self.player.closestTube = closest
end

function game:lost()
	self:despawnAllObjects()
	Cron.Halt(self.enemySpawning)

	self.gameOver = true
	self.gameOverText:SetVisible(true)

	if self.score > self.highscore then
		self.highscore = self.score
		self:saveHighscore(self.highscore)
		if self.boardScreen then
			self.leaderboard:update(self.highscore):Reparent(self.boardScreen, -1)
			self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
		end
		self.hsText:SetVisible(true)
		self.hsText:SetText(tostring("New Highscore: " .. self.score))
	end

	self.continueText:SetVisible(true)
end

function game:renderHealth()
	self.healthText:SetText(tostring("HP: " .. self.player.health))
	self.scoreInk:SetText(tostring("Score: " .. self.score))
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
	Game.GetQuestsSystem():SetFactStr('arcade_panzer', score)
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
		utils.showInputHint("QuickMelee", "Back")
	end
end

function game:stop() -- Gets called when leaving workspot
	self:switchToMenu()
	self.gameScreen = nil
	utils.hideCustomHints()
end

return game