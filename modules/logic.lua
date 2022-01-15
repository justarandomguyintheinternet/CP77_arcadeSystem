local utils = require("modules/util/utils")

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
	if self:looksAtArcade() and not self.currentWorkspot then
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

function logic:addMachine(object) -- Gets called OnGameAttached
	local alreadyHasMachine = false
	for _, arcade in pairs(self.machines) do
		if utils.isSameInstance(object, arcade.object) then
			alreadyHasMachine = true
			print("already has machine")
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
		if utils.isSameInstance(machine.object, obj) then
			return k, machine
		end
	end
end

function logic:looksAtArcade()
	local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
	if not target then return false end
	if Vector4.GetAngleBetween(target:GetWorldForward(), utils.subVector(target:GetWorldPosition(), GetPlayer():GetWorldPosition())) < 90 then return end
	if (target:GetWorldPosition():Distance(GetPlayer():GetWorldPosition()) < self.arcadeRange) and target:GetClassName().value == "ArcadeMachine" then
		return true
	else
		return false
	end
end

function logic:onInteract() -- Called from onAction observer
	if self:looksAtArcade() and not self.currentWorkspot then
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