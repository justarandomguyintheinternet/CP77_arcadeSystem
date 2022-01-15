local Cron = require("modules/external/Cron")

arcade = {}

function arcade:new(arcadeSys, object)
	local o = {}

    o.as = arcadeSys
    o.object = object
	o.game = nil

	self.__index = self
   	return setmetatable(o, self)
end

function arcade:init() -- Setup game
	local audio = self.object.currentGameAudio.value

	if audio == "mus_cp_arcade_panzer_START_menu" then
		self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
	elseif audio == "mus_cp_arcade_quadra_START_menu" then
		self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
	elseif audio == "mus_cp_arcade_shooter_START_menu" then
		self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
	elseif audio == "mus_cp_arcade_roach_START_menu" then
		self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
	else
		self.game = require("modules/games/flappy_bird/flappy_bird"):new(self.as, self)
	end
	Cron.After(0.25, function () -- Wait until GameController is initialized
		self.game:init()
		self.game:showDefault()
	end)
end

return arcade