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
	o.rains = {}
	o.fields = nil

	o.keys = {}
	o.input = {backwards = false, right = false, left = false}

	o.gameOver = false
	o.gameText = nil
	o.overText = nil
	o.scoreText = nil
	o.continueText = nil

	o.highscore = 0
	o.boardScreen = nil
	o.leaderboard = nil

	o.menuMusic = "mus_q112_hanako_arasaka_assault_01_START"
	o.gameMusic = "mus_mq028_kill_01_START"
	o.lostMusic = "ui_hacking_access_denied"

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

	ink.rect(0, 0, 500, 500, color.black):Reparent(self.menuScreen, -1)

	local area = ink.canvas(42, 16)
    area:Reparent(self.menuScreen, -1)

    ink.text("Netriss", 55, 0, 50, color.lime):Reparent(area, -1)
	ink.text("Resurrections", 40, 50, 30, color.lime):Reparent(area, -1)

	local r = require("modules/games/tetris/codeRain"):new(self, 50, 25)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 100, 50)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 60, 120)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 15, 35)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 190, 50)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 150, 25)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 150, 120)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 125, 100)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 210, 10)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 230, 70)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 235, 120)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 250, 90)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 270, 45)
	r:spawn(self.menuScreen)

	local r = require("modules/games/tetris/codeRain"):new(self, 285, 75)
	r:spawn(self.menuScreen)

    local buttons = ink.canvas(110, 110)
    buttons:Reparent(self.menuScreen, -1)

	self.selectorInk = ink.rect(0, 0, 120, 25, HDRColor.new({ Red = 0, Green = 0.8, Blue = 0, Alpha = 1 }))
	self.selectorInk:Reparent(buttons, -1)

    ink.text("Play [2 E$]", 0, 0, 25):Reparent(buttons, -1)
    ink.text("Leaderboard", 0, 30, 25):Reparent(buttons, -1)
	ink.text("Exit", 0, 60, 25):Reparent(buttons, -1)

	local fluff = ink.text("[c] kWStudios Co. Ltd. 2048\n All rights reserved.", 15, self.screenSize.y - 30, 8)
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
			if self.gameOver then self:goBack() end
			if not self.inGame then return end
			self.fields:rotate()
		end
	elseif actionName == 'Back' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.backwards = true
			self.fields:moveDown()
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.backwards = false
		end
	elseif actionName == 'Left' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.left = true
			self.fields:moveLeft()
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.left = false
		end
	elseif actionName == 'Right' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.right = true
			self.fields:moveRight()
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.right = false
		end
	elseif actionName == 'UI_MoveRight' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.right = true
			self.fields:moveRight()
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.right = false
		end
	elseif actionName == 'UI_MoveLeft' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.left = true
			self.fields:moveLeft()
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.left = false
		end
	elseif actionName == 'UI_MoveDown' then
		if not self.inGame then return end

		if actionType == 'BUTTON_PRESSED' then
			self.input.backwards = true
			self.fields:moveDown()
		elseif actionType == 'BUTTON_RELEASED' then
			self.input.backwards = false
		end
	end
end

function game:handleMenuInput(key)
	if not self.inMenu then return end

	if key == "interact" then
		self.selectorInk:SetTintColor(color.new(0, 1, 0))
		Cron.After(0.1, function ()
			self.selectorInk:SetTintColor(color.new(0, 0.8, 0))

			if self.selectedItem == 3 then
				self.as.logic:tryExitWorkspot()
			elseif self.selectedItem == 2 then
				self:switchToBoard()
			elseif self.selectedItem == 1 then
				utils.stopSound(self.menuMusic)
				utils.playSound(self.gameMusic)

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
		self.gameScreen = nil
	end

	self.inMenu = true
	self.inBoard = false
	self.inGame = false
end

function game:clearBG()
	self.gameScreen:RemoveAllChildren()
	self.fields:despawn()
	self.fields = nil
	self.rains = {}
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
	self.fields = require("modules/games/tetris/fields"):new(self, 95, 0, 10, 20, 10, 1)
	self.fields:spawn(self.gameScreen)

	self.nextInk = ink.text("Next Piece:", 233, 10, 14)
	self.nextInk:Reparent(self.gameScreen, -1)

	self.scoreInk = ink.text("Score: 0", 20, 10, 20)
	self.scoreInk:Reparent(self.gameScreen, -1)

	self.gameText = ink.text("GAME ", 35, 90, 55, color.red)
	self.gameText:SetVisible(false)
	self.gameText:Reparent(self.gameScreen, -1)

	self.overText = ink.text("OVER", 175, 90, 55, color.red)
	self.overText:SetVisible(false)
	self.overText:Reparent(self.gameScreen, -1)

	self.scoreText = ink.text("", 85, 140, 25, color.blue)
	self.scoreText:SetVisible(false)
	self.scoreText:Reparent(self.gameScreen, -1)

	self.continueText = ink.text("Press JUMP to continue", 85, 210, 15)
	self.continueText:SetVisible(false)
	self.continueText:Reparent(self.gameScreen, -1)
end

function game:initBG()
	ink.rect(0, 0, 500, 500, color.black):Reparent(self.gameScreen, -1)

	for _ = 1, 20 do
		local r = require("modules/games/tetris/codeRain"):new(self, math.random(1, self.screenSize.x), math.random(-100, self.screenSize.y - 100))
		r:spawn(self.gameScreen)

		table.insert(self.rains, r)
	end

	ink.rect(95, 0, 5, 300, color.green):Reparent(self.gameScreen, -1)
	ink.rect(220, 0, 5, 300, color.green):Reparent(self.gameScreen, -1)
	ink.rect(220, 85, 100, 5, color.green):Reparent(self.gameScreen, -1)
end

function game:initBoard()
	self.boardScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.boardScreen:Reparent(self.screen, -1)
	self.boardScreen:SetVisible(false)

	self.leaderboard = require("modules/ui/leaderboard"):new(10, function ()
		return math.random(2, 35) * 10
	end)
	self.leaderboard:spawn(self.highscore):Reparent(self.boardScreen, -1)
	self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
end

function game:lost()
	self.gameOver = true
	self.gameText:SetVisible(true)
	self.overText:SetVisible(true)

	if self.score > self.highscore then
		self.highscore = self.score
		self:saveHighscore(self.highscore)
		if self.boardScreen then
			self.leaderboard:update(self.highscore):Reparent(self.boardScreen, -1)
			self.leaderboard.canvas:SetMargin(110, 28, 0, 0)
		end
		self.scoreText:SetVisible(true)
		self.scoreText:SetText(tostring("New Highscore: " .. self.score))
	end

	self.continueText:SetVisible(true)

	utils.stopSound(self.gameMusic)
	utils.playSound(self.lostMusic, 4)
end

function game:renderGame(dt)
	self:renderBG(dt)
	self.scoreInk:SetText(tostring("Score: " .. self.score))
end

function game:renderBG(dt)
	for _, rain in pairs(self.rains) do
		rain:update(dt)
	end
end

function game:selectMenuItem() -- Moves the selector rectangle
	local i = self.selectedItem - 1
	local height = 30

	self.selectorInk:SetMargin(inkMargin.new({ left = 0, top = i * height, right = 0.0, bottom = 0.0 }))
end

function game:loadHighscore()
	CName.add("arcade_tetris_hs")
	self.highscore = Game.GetQuestsSystem():GetFactStr('arcade_tetris_hs')
end

function game:saveHighscore(score)
	Game.GetQuestsSystem():SetFactStr('arcade_tetris_hs', score)
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
		utils.showInputHint("QuickMelee", "Back")
		utils.showInputHint("UI_MoveRight", "Move Right")
		utils.showInputHint("UI_MoveLeft", "Move Left")
		utils.showInputHint("UI_MoveDown", "Move Down")
		utils.showInputHint("Jump", "Rotate Piece")
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