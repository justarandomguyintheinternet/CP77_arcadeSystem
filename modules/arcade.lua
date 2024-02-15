local Cron = require("modules/external/Cron")

arcade = {}

function arcade:new(arcadeSys, object)
	local o = {}

    o.as = arcadeSys
    o.objectID = object:GetEntityID()
	o.game = nil

	self.__index = self
   	return setmetatable(o, self)
end

---@return ArcadeMachine
function arcade:getObject()
	return Game.FindEntityByID(self.objectID)
end

function arcade:init(gameType) -- Setup game
	Cron.After(1, function () -- Wait until GameController is initialized
		if not self:getObject() or self:getObject().uiComponent:GetGameController() == nil then -- Not yet ready, add it visually
			self.as.logic:removeMachine(self:getObject())
			return
		end

		local audio = self:getObject().currentGameAudio.value -- Pachinko machine
		if audio == "None" or audio == "mus_cp_arcade_roach_START_menu" or audio == "mus_cp_arcade_shooter_START_menu" then
			self.as.logic:removeMachine(self:getObject())
			return
		end

		-- if audio == "mus_cp_arcade_panzer_START_menu" then
		-- 	self.game = require("modules/games/panzer/panzer_game"):new(self.as, self)
		-- elseif audio == "mus_cp_arcade_quadra_START_menu" then
		-- 	self.game = require("modules/games/tetris/tetris"):new(self.as, self)
		-- elseif audio == "mus_cp_arcade_shooter_START_menu" then
		-- 	self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
		-- elseif audio == "mus_cp_arcade_roach_START_menu" then
		-- 	self.game = require("modules/games/roach_race/roach_race"):new(self.as, self)
		-- else
		-- 	self.game = require("modules/games/roach_race/roach_race"):new(self.as, self)
		-- end

		if gameType == "panzer" then
			self.game = require("modules/games/panzer/panzer_game"):new(self.as, self)
		elseif gameType == "tetris" then
			self.game = require("modules/games/tetris/tetris"):new(self.as, self)
		elseif gameType == "bird" then
			self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
		elseif gameType == "roach" then
			self.game = require("modules/games/roach_race/roach_race"):new(self.as, self)
		end

		self.game:init()
		self.game:showDefault()
	end)
end

return arcade