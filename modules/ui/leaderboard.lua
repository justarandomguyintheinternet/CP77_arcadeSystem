local ink = require("modules/ui/inkHelper")
local utils = require("modules/util/utils")
local color = require("modules/ui/color")

local names = {
    "keanuWheeze",
    "nim",
    "Erok",
    "Scissors",
    "Spicy.dll",
    "Gorefiend",
    "Neurolinked",
    "rfuzzo",
    "psiberx",
    "johnson",
    "Vwarf",
    "CarbineHeroes",
    "_S1lv3rh4nd.exe",
    "Ming",
    "matsif",
    "BFG9000",
    "DJ_Kovrik",
    "Walrus420",
    "EvilLord",
    "alphaZomega",
    "alexx",
    "Hineytroll",
    "MaximiliumM",
    "HitmanHimself",
    "WopsS",
    "WSSDude",
    "jekky",
    "offline",
    "Auska",
    "anygoodname",
    "donk",
    "sombra",
    "b0kkr",
    "123321",
    "perfnormbeast",
    "yamashi",
    "RMK",
    "WillyJL",
    "DoctorPortal",
    "SilverGhost",
    "inuk",
    "Silvay",
    "Maks778",
    "Rosza",
    "Ms.Flower",
    "CrazyPotato",
    "PotatoWaifu",
    "jackhumbert",
    "Jato",
    "SPSTO",
    "KieleckiMayo",
    "presetMaker69",
    "T-Bug",
    "Wakako",
    "ChantingMulan",
    "tylerMcVicker",
    "pawelSusko"
}

board = {}

function board:new(nEntries, randFunc)
	local o = {}

    o.nEntries = nEntries
    o.randomFunc = randFunc

    o.bg = nil
    o.canvas = nil

    o.scores = {}

	self.__index = self
   	return setmetatable(o, self)
end

function board:spawn(playerScore)
    self:setNameScores()
	table.insert(self.scores, #self.scores, {name = "V", score = playerScore})
	self:sortLeaderboard()

    self.canvas = ink.canvas(0, 0)

    self.bg = ink.rect(-200, -200, 500, 500, color.black)
    self.bg:Reparent(self.canvas, -1)

    ink.text("Leaderboard:", -35, -22, 35, color.gold):Reparent(self.canvas, -1)

    for key, entry in pairs(self.scores) do
        local c = color.white
        if entry.name == "V" then
            c = color.yellow
        end

        ink.text(entry.name, 0, key * 16, 15, c):Reparent(self.canvas, -1)
        ink.text(entry.score, 100, key * 16, 15, c):Reparent(self.canvas, -1)
    end

    return self.canvas
end

function board:setNameScores() -- Sets the name / value pairs for the "randoms"
    local n = utils.deepcopy(names)
    self.scores = {}
    for i = 1, self.nEntries do
        cName = n[math.random(1, #n)]
        table.insert(self.scores, i, {name = cName, score = self:randomFunc()})
        utils.removeItem(n, cName)
    end
end

function board:update(newScore) -- Use this to update the player score
    self.canvas:SetVisible(false)
    self.canvas = nil

    for _, entry in pairs(self.scores) do
        if entry.name == "V" then
            entry.score = newScore
        end
    end
    self:sortLeaderboard()

    self.canvas = ink.canvas(0, 0)
    ink.text("Leaderboard:", -35, -22, 35, color.gold):Reparent(self.canvas, -1)

    for key, entry in pairs(self.scores) do
        local c = color.white
        if entry.name == "V" then
            entry.score = newScore
            c = color.yellow
        end

        ink.text(entry.name, 0, key * 16, 15, c):Reparent(self.canvas, -1)
        ink.text(entry.score, 100, key * 16, 15, c):Reparent(self.canvas, -1)
    end

    return self.canvas
end

function board:sortLeaderboard()
    table.sort(self.scores, function (a, b)
		return a.score > b.score
	end)
end

return board