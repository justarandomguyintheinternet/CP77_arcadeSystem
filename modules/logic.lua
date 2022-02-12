local utils = require("modules/util/utils")
local Cron  = require("modules/external/Cron")

logic = {}

function logic:new(arcadeSys)
	local o = {}

    o.as = arcadeSys
	o.machines = {}
	o.currentWorkspot = nil
	o.currentArcade = nil

	o.inArcade = false
	o.arcadeRange = 1.5
	o.hudActive = false

	self.__index = self
   	return setmetatable(o, self)
end

function logic:run(dt) -- Runs inside onUpdate
	local targetData = self:looksAtArcade()
	if targetData.isArcade and self:getArcadeByObject(targetData.target) and not self.currentWorkspot then
		utils.createInteractionHub("Play", "UI_Apply", true)
		self.hudActive = true
	elseif self.hudActive then
		self.hudActive = false
		utils.createInteractionHub("Play", "UI_Apply", false)
	end

	if self.currentWorkspot then
		self.currentWorkspot:update(dt)
		if self.currentWorkspot.inWorkspot then
			self.currentArcade.game:update(dt)
		end
	end
end

function logic:startCron()
	Cron.Every(0.25, function ()
        local searchQuery = Game["TSQ_ALL;"]()
        searchQuery.maxDistance = 25
        searchQuery.includeSecondaryTargets = false
		searchQuery.ignoreInstigator = true

        local _, objects = Game.GetTargetingSystem():GetTargetParts(GetPlayer(), searchQuery)
        for _, v in ipairs(objects) do
            local obj = v:GetComponent():GetEntity()

			if obj and obj:GetClassName().value == "ArcadeMachine" then
				self:addMachine(obj)
			end
		end
	end)
end

function logic:addMachine(object) -- Gets called OnGameAttached
	local alreadyHasMachine = false
	for _, arcade in pairs(self.machines) do
		if utils.isSameInstance(object, arcade:getObject()) then
			alreadyHasMachine = true
			break
		end
	end
	if alreadyHasMachine then return end

	local a = require("modules/arcade"):new(self.as, object)
	a:init()
	table.insert(self.machines, a)
end

function logic:removeMachine(object) -- Gets called OnDetach
	local key, _ = self:getArcadeByObject(object)
	table.remove(self.machines, key)
end

function logic:getArcadeByObject(obj)
	for k, machine in ipairs(self.machines) do
		if utils.isSameInstance(machine:getObject(), obj) then
			return k, machine
		end
	end

	return nil
end

function logic:looksAtArcade()
	local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
	if not target then return {target = nil, isArcade = false} end

	self:addMachine(target)

	if Vector4.GetAngleBetween(target:GetWorldForward(), utils.subVector(target:GetWorldPosition(), GetPlayer():GetWorldPosition())) < 90 then return end
	if (target:GetWorldPosition():Distance(GetPlayer():GetWorldPosition()) < self.arcadeRange) and target:GetClassName().value == "ArcadeMachine" then
		return {target = target, isArcade = true}
	else
		return {target = target, isArcade = false}
	end
end

function logic:onInteract() -- Called from onAction observer
	if self:looksAtArcade().isArcade and not self.currentWorkspot then
		local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
		_, self.currentArcade = self:getArcadeByObject(target)
		self.currentWorkspot = require("modules/workspot"):new(self.as)
		self.currentWorkspot:enter(target)
	end
end

function logic:tryExitWorkspot() -- Called from onAction
	if not self.currentWorkspot then return end
	self.currentArcade.game:stop()
	self.currentWorkspot:exit()
end

function logic:onExitedWorkspot() -- Gets called when workspot has finished exit anim
	self.currentWorkspot = nil
end

return logic