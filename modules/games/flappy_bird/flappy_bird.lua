local color = require("modules/ui/color")
local ink = require("modules/ui/inkHelper")
local Cron = require("modules/external/Cron")
local utils = require("modules/util/utils")
local tween = require("modules/external/tween/tween") -- https://github.com/kikito/tween.lua

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
	o.gameBG = {}
	o.tubes = {}
	o.player = nil
	o.animeCron = nil

	o.tubesPassed = 0
	o.scoreInk = nil
	o.startWidth = 160
	o.startHeight = 120

	o.gameOver = false
	o.gameText = nil
	o.overText = nil
	o.scoreText = nil
	o.continueText = nil

	o.highscore = 0
	o.boardScreen = nil
	o.leaderboard = nil

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
	--ink.rect(-40, -10, 400, 20, HDRColor.new({ Red = 1, Green = 1, Blue = 1, Alpha = 1.0 }), 0):Reparent(area, -1) -- clouds

	ink.rect(20, 300, 400, 400, HDRColor.new({ Red = 0, Green = 0.7, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)
	ink.rect(100, 280, 400, 400, HDRColor.new({ Red = 0, Green = 0.9, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)
	ink.rect(160, 310, 400, 400, HDRColor.new({ Red = 0, Green = 0.4, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)
	ink.rect(255, 320, 400, 400, HDRColor.new({ Red = 0, Green = 0.7, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5})):Reparent(area, -1)

    ink.text("Fappy", 40, 0, 50, color.yellow):Reparent(area, -1)
    ink.text("Berd", 100, 50, 40, color.red):Reparent(area, -1)

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
		self:renderGame(dt)
		if self.player.y < -10 or self.player.y > self.screenSize.y + 10 then
			self:lost()
		end
	end
end

function game:handleInput(action) -- Passed forward from onAction
	local actionName = Game.NameToString(action:GetName(action))
	local actionType = action:GetType(action).value

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
	elseif key == "up" then
		self.selectedItem = self.selectedItem - 1
		if self.selectedItem < 1 then
			self.selectedItem = 3
		end
		self:selectMenuItem()
	elseif key == "down" then
		self.selectedItem = self.selectedItem + 1
		if self.selectedItem > 3 then
			self.selectedItem = 1
		end
		self:selectMenuItem()
	end
end

function game:handleGameInput(key)
	if not self.inGame then return end

	if key == "jump" then
		self.player:jump()
	end
	if self.gameOver then
		self:switchToMenu()
	end
end

function game:goBack()
	if self.inMenu then
		self.as.logic:tryExitWorkspot()
	elseif self.inBoard then
		self:switchToMenu()
	elseif self.inGame then
		-- Add logic to stop and lose game
		self:switchToMenu()
	end
end

function game:switchToMenu()
	self.menuScreen:SetVisible(true)
	if self.gameScreen then self.gameScreen:SetVisible(false) end
	if self.boardScreen then self.boardScreen:SetVisible(false) end

	if self.inGame then
		self.tubes = {}
		self.tubesPassed = 0
		self.gameOver = false

		self.gameText:SetVisible(false)
		self.overText:SetVisible(false)
		self.scoreText:SetVisible(false)
		self.continueText:SetVisible(false)

		self.gameScreen = nil
	end

	self.inMenu = true
	self.inBoard = false
	self.inGame = false

	if self.animeCron then
		Cron.Halt(self.animeCron)
	end
end

function game:switchToGame()
	utils.spendMoney(2)
	if not self.gameScreen then
		self:initGame()
	end
	self.menuScreen:SetVisible(false)
	self.gameScreen:SetVisible(true)

	self.inMenu = false
	self.inGame = true

	self.animeCron = Cron.Every(0.2, function ()
		self.player:updateAnimation()
	end)
end

function game:switchToBoard() -- Switch to leaderboard
	if not self.boardScreen then
		self:initBoard()
	end
	self.menuScreen:SetVisible(false)
	self.boardScreen:SetVisible(true)

	self.inMenu = false
	self.inBoard = true
end
-- base/gameplay/gui/wigets/minimap
function game:initGame()
	self.gameScreen = ink.canvas(0, 0, inkEAnchor.TopLeft)
	self.gameScreen:Reparent(self.screen, -1)
	self.gameScreen:SetVisible(false)

	ink.rect(160, 120, 400, 400, HDRColor.new({ Red = 0, Green = 0.7, Blue = 1, Alpha = 1.0 }), 0, Vector2.new({X = 0.5, Y = 0.5})):Reparent(self.gameScreen, -1) -- bg
	ink.circle(250, 10, 65, HDRColor.new({ Red = 1, Green = 0.75, Blue = 0, Alpha = 1.0 })):Reparent(self.gameScreen, -1) -- sun

	for x = 1, 10 do -- mountains
		local x = (x * 100) - 150
		local y = 295 + math.random() * 100
		local r = ink.rect(x, y, 400, 400, HDRColor.new({ Red = 0, Green = 0.5 + math.random() * 0.5, Blue = 0, Alpha = 1.0 }), 45, Vector2.new({X = 0.5, Y = 0.5}))
		r:Reparent(self.gameScreen, -1)
		table.insert(self.gameBG, r)
	end

	local tube = require("modules/games/flappy_bird/tube")
	for x = 1, 10 do -- tubes
		local t = tube:new(x * self.startWidth + 150, 50 + math.random() * 150, self.startHeight, HDRColor.new({ Red = 0, Green = 0, Blue = 1, Alpha = 1.0 }))
		t:spawn(self.gameScreen)
		table.insert(self.tubes, t)
	end

	self.player = require("modules/games/flappy_bird/player"):new(100, self.screenSize.y / 2)
	self.player:spawn(self.gameScreen)

	self.scoreInk = ink.text("Score: 0", 20, 10, 20)
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
	local add = math.min(self.tubesPassed / 2, 20)
	local moveX = (dt * (50 + add))

	for _, rect in pairs(self.gameBG) do
		local margin = rect:GetMargin()

		if margin.left - moveX < -200 then
			local y = 295 + math.random() * 100
			margin.left = margin.left + 1000
			margin.top = y
			rect:SetTintColor(HDRColor.new({ Red = 0, Green = 0.5 + math.random() * 0.5, Blue = 0, Alpha = 1.0 }))
		end

		margin = inkMargin.new({ left = margin.left - moveX, top = margin.top, right = 0.0, bottom = 0.0 })
		rect:SetMargin(margin)
	end
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
	self.gameOver = true
	self.gameText:SetVisible(true)
	self.overText:SetVisible(true)

	if self.tubesPassed > self.highscore then
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

	if self.animeCron then
		Cron.Halt(self.animeCron)
	end
end

function game:getRightestTube()
	local x = 0
	local tube = nil

	for _, t in pairs(self.tubes) do
		if t.x > x then
			x = t.x
			tube = t
		end
	end

	return tube
end

function game:renderGame(dt)
	self:renderBG(dt)
	self:renderTubes(dt)
end

function game:selectMenuItem() -- Moves the selector rectangle
	local i = self.selectedItem - 1
	local height = 30

	self.selectorInk:SetMargin(inkMargin.new({ left = 0, top = i * height, right = 0.0, bottom = 0.0 }))
end

function game:loadHighscore()
	CName.add("arcade_bird_hs")
	self.highscore = Game.GetQuestsSystem():GetFactStr('arcade_bird_hs')
end

function game:saveHighscore(score)
	Game.GetQuestsSystem():SetFactStr('arcade_bird_hs', score)
end

function game:stop() -- Gets called when leaving workspot
	self:switchToMenu()
	self.gameScreen = nil
end

return game