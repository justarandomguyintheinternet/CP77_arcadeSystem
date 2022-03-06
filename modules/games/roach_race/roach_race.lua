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
	o.gameBG = {}

	o.player = nil
	o.hearts = {}

	o.scoreInk = nil
	o.keys = {}

	o.obstacles = {}

	o.gameOver = false
	o.gameText = nil
	o.overText = nil
	o.scoreText = nil
	o.continueText = nil

	o.highscore = 0
	o.boardScreen = nil
	o.leaderboard = nil

	o.menuMusic = "mus_sq023_meet_joshua_01_START"
	o.gameMusic = "mus_sq031_cmf_01_START"
	o.lostMusic = "mus_q108_concert_glitch_nr1_START"

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

	local b = ink.image(0, 0, 500, 500, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'sky')
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(0, self.screenSize.y - 30, 500, 30, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'grass')
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(85, 55, 30, 15, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'cloud', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(160, 100, 30, 15, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'cloud', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(50, 180, 50, 40, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'roach_2', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(160, 200, 55, 20, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'roof', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(220, 140, 60, 30, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'gryphon_5', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(60, 20, 200, 30, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'title_1_roach', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

	local b = ink.image(85, 55, 200, 40, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'title_1_race', 0, inkBrushMirrorType.Both)
    b.pos:Reparent(self.menuScreen, -1)

    local buttons = ink.canvas(110, 110)
    buttons:Reparent(self.menuScreen, -1)

	self.selectorInk = ink.rect(0, 0, 120, 25, HDRColor.new({ Red = 0.5, Green = 0.5, Blue = 0, Alpha = 1 }))
	self.selectorInk:Reparent(buttons, -1)

    ink.text("Play [2 E$]", 0, 0, 25):Reparent(buttons, -1)
    ink.text("Leaderboard", 0, 30, 25):Reparent(buttons, -1)
	ink.text("Exit", 0, 60, 25):Reparent(buttons, -1)

	local fluff = ink.text("[c] WHuntRed Ltd. 2063\n All rights reserved.", self.screenSize.x - 75, self.screenSize.y - 30, 8)
	fluff:Reparent(self.menuScreen, -1)

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
		self:updateObstacles(dt)
		self:renderGame(dt)
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
			self:handleGameInput("jump")
		end
	end
end

function game:handleMenuInput(key)
	if not self.inMenu then return end

	if key == "interact" then
		self.selectorInk:SetTintColor(color.new(0.8, 0.8, 0))
		Cron.After(0.1, function ()
			self.selectorInk:SetTintColor(color.new(0.5, 0.5, 0))

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

function game:handleGameInput(key)
	if not self.inGame then return end

	if key == "jump" then
		self.player:jump()
	end
	if self.gameOver then
		self:goBack()
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
		utils.stopSound(self.lostMusic)

		self:switchToMenu()
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

		self.gameText:SetVisible(false)
		self.overText:SetVisible(false)
		self.scoreText:SetVisible(false)
		self.continueText:SetVisible(false)

		self:clearBG()
		self.player:despawn()
		self.gameScreen = nil
	end

	self.inMenu = true
	self.inBoard = false
	self.inGame = false
end

function game:clearBG()
	self.gameScreen:RemoveAllChildren()
	self.gameBG = {}
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
	self.gameScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.gameScreen:Reparent(self.screen, -1)
	self.gameScreen:SetVisible(false)

	self:initBG()

	self.player = require("modules/games/roach_race/player"):new(self, 70, self.screenSize.y - 50)
	self.player:spawn(self.gameScreen)

	self.scoreInk = ink.text("Score: 0", 200, 10, 20)
	self.scoreInk:Reparent(self.gameScreen, -1)

	self.gameText = ink.text("GAME ", 35, 90, 55, color.red)
	self.gameText:SetVisible(false)
	self.gameText:Reparent(self.gameScreen, -1)

	self.overText = ink.text("OVER", 175, 90, 55, color.red)
	self.overText:SetVisible(false)
	self.overText:Reparent(self.gameScreen, -1)

	self.scoreText = ink.text("", 85, 140, 25, HDRColor.new({ Red = 0, Green = 1.25, Blue = 0, Alpha = 1 }))
	self.scoreText:SetVisible(false)
	self.scoreText:Reparent(self.gameScreen, -1)

	self.continueText = ink.text("Press JUMP to continue", 85, 210, 15)
	self.continueText:SetVisible(false)
	self.continueText:Reparent(self.gameScreen, -1)

	local o = require("modules/games/roach_race/obstacle"):new(250, 160, {x = 60, y = 40}, {"gryphon_1", "gryphon_2", "gryphon_3", "gryphon_4","gryphon_5"}, 0.2, 1.5)
	o:spawn(self.gameScreen)
	table.insert(self.obstacles, o)

	local o = require("modules/games/roach_race/obstacle"):new(350, 190, {x = 15, y = 15}, {"carrot"}, 0.2)
	o:spawn(self.gameScreen)
	table.insert(self.obstacles, o)
end

function game:initBG()
	local b = ink.image(0, 0, 500, 500, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'sky')
    b.pos:Reparent(self.gameScreen, -1)

	local b = ink.image(0, self.screenSize.y - 30, 500, 30, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'grass')
    b.pos:Reparent(self.gameScreen, -1)

	for i = 1, 8 do
		local x = 0
		if i ~= 1 then
			x = self:getRightestCloud().pos:GetMargin().left + math.random(50, 100)
		end

		local c = ink.image(x, math.random(5, self.screenSize.y - 50), 30, 15, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'cloud', 0, inkBrushMirrorType.Both)
    	c.pos:Reparent(self.gameScreen, -1)
		table.insert(self.gameBG, c)
	end

	for i = 1, 3 do
		local h = ink.image((i * 18) + 15, 15, 15, 15, 'base\\gameplay\\gui\\world\\vending_machines\\atlas_roach_race.inkatlas', 'hearth', 0, inkBrushMirrorType.Both)
    	h.pos:Reparent(self.gameScreen, -1)
		self.hearts[i] = h
	end
end

function game:initBoard()
	self.boardScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.boardScreen:Reparent(self.screen, -1)
	self.boardScreen:SetVisible(false)

	self.leaderboard = require("modules/ui/leaderboard"):new(10, function ()
		return math.random(4, 87)
	end)
	self.leaderboard:spawn(self.highscore):Reparent(self.boardScreen, -1)
	self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
end

function game:renderBG(dt) -- Move background
	local add = math.min(self.score / 2, 20)
	local moveX = (dt * (50 + add))

	for _, cloud in pairs(self.gameBG) do
		local margin = cloud.pos:GetMargin()

		if margin.left - moveX < -200 then
			local y = math.random(5, self.screenSize.y - 50)

			margin.left = self:getRightestCloud().pos:GetMargin().left + math.random(50, 100)
			margin.top = y
		end

		margin = inkMargin.new({ left = margin.left - moveX, top = margin.top, right = 0.0, bottom = 0.0 })
		cloud.pos:SetMargin(margin)
	end

	for h = 1, 3 do
		if h <= self.player.lives then
			self.hearts[h].image:SetVisible(true)
		else
			self.hearts[h].image:SetVisible(false)
		end
	end
end

function game:updateObstacles(dt)
	local add = math.min(self.score / 2, 20)
	local moveX = (dt * (50 + add))

	for _, obj in pairs(self.obstacles) do
		obj.x = obj.x - (moveX + add) * obj.speed

		if obj.x + obj.size.x < 0 then
			obj:despawn()
			self.gameScreen:RemoveChild(obj.ink.pos)
			utils.removeItem(self.obstacles, obj)
		else
			local m = obj.ink.pos:GetMargin()
			m.left = obj.x
			obj.ink.pos:SetMargin(m)

			if obj.notHit and obj.x + obj.size.x > self.player.x and obj.x < self.player.x + self.player.size.x and obj.y + obj.size.y > self.player.y and obj.y < self.player.y + self.player.size.y then
				obj.notHit = false

				if obj.sprites[1] == "carrot" then
					self.player.lives = math.min(3, self.player.lives + 1)

					obj:despawn()
					self.gameScreen:RemoveChild(obj.ink.pos)
					utils.removeItem(self.obstacles, obj)
				else
					self.player.lives = self.player.lives - 1
				end
			end
		end
	end

	if self.player.lives <= 0 then self:lost() end
end

function game:lost()
	self.gameOver = true
	self.gameText:SetVisible(true)
	self.overText:SetVisible(true)

	if self.score > self.highscore then
		self.highscore = self.tubesPassed
		self:saveHighscore(self.highscore)
		if self.boardScreen then
			self.leaderboard:update(self.highscore):Reparent(self.boardScreen, -1)
			self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
		end
		self.scoreText:SetVisible(true)
		self.scoreText:SetText(tostring("New Highscore: " .. self.tubesPassed))
	end

	self.continueText:SetVisible(true)

	utils.stopSound(self.gameMusic)
	utils.playSound(self.lostMusic)
end

function game:getRightestCloud()
	local x = -100
	local c = nil

	for _, t in pairs(self.gameBG) do
		local margin = t.pos:GetMargin()

		if margin.left > x then
			x = margin.left
			c = t
		end
	end

	return c
end

function game:renderGame(dt)
	self:renderBG(dt)
end

function game:selectMenuItem() -- Moves the selector rectangle
	local i = self.selectedItem - 1
	local height = 30

	self.selectorInk:SetMargin(inkMargin.new({ left = 0, top = i * height, right = 0.0, bottom = 0.0 }))
end

function game:loadHighscore()
	CName.add("arcade_roach_hs")
	self.highscore = Game.GetQuestsSystem():GetFactStr('arcade_roach_hs')
end

function game:saveHighscore(score)
	Game.GetQuestsSystem():SetFactStr('arcade_roach_hs', score)
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
		utils.showInputHint("Jump", "Jump")
		utils.showInputHint("QuickMelee", "Back")
	end
end

function game:stop() -- Gets called when leaving workspot
	self:switchToMenu()
	utils.stopSound(self.menuMusic)
	utils.stopSound(self.gameMusic)
	utils.stopSound(self.lostMusic)

	self.screen:RemoveChild(self.gameScreen)
	self.gameScreen = nil
	self.initialized = false
	utils.hideCustomHints()
end

return game