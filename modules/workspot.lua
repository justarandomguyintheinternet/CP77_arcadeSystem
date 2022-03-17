local tween = require("modules/external/tween/tween") -- https://github.com/kikito/tween.lua
local utils = require("modules/util/utils")

workspot = {}

function workspot:new(arcadeSys)
	local o = {}

    o.as = arcadeSys
    o.target = nil
	o.distToTarget = 0.35
	o.offset = Vector4.new(0, 0, -0.15)

	o.targetPos = Vector4.new(0, 0, 0, 0)
	o.targetRot = EulerAngles.new(0, 0, 0)

	o.originRot = EulerAngles.new(0, 0, 0)
	o.originPos = Vector4.new(0, 0, 0, 0)

	o.enteringWorkspot = false
	o.exitingWorkspot = false
	o.inWorkspot = false

	o.transition = nil
	o.transitionTime = 1.5
	o.transitionFunc = tween.easing.inOutQuart

	self.__index = self
   	return setmetatable(o, self)
end

function workspot:enter(target) -- Enter a "workspot" in front of an object
	self.target = target
	self.enteringWorkspot = true
	self:applyRestrictions()

	self.originPos = GetPlayer():GetWorldPosition() -- Setup original pos and rot
	self.originRot = GetPlayer():GetWorldOrientation():ToEulerAngles()
	self.originRot.pitch = Vector4.new(-Game.GetCameraSystem():GetActiveCameraForward().x, -Game.GetCameraSystem():GetActiveCameraForward().y, -Game.GetCameraSystem():GetActiveCameraForward().z, -Game.GetCameraSystem():GetActiveCameraForward().w):ToRotation().pitch -- Yeah boi

	self.targetPos = utils.addVector(target:GetWorldPosition(), utils.multVector(target:GetWorldForward(), self.distToTarget)) -- Setup target pos
	self.targetPos = utils.addVector(self.targetPos, self.offset)

	local dirVector = utils.subVector(target:GetWorldPosition(), self.targetPos) -- Setup target rot
	self.targetRot = dirVector:ToRotation()
	self.targetRot.pitch = self.targetRot.pitch - 4 -- Small correction

	local props = {pos = {x = self.originPos.x, y = self.originPos.y, z = self.originPos.z}, rot = {roll = self.originRot.roll, pitch = self.originRot.pitch, yaw = self.originRot.yaw}}
	local target = {pos = {x = self.targetPos.x, y = self.targetPos.y, z = self.targetPos.z}, rot = {roll = self.targetRot.roll, pitch = self.targetRot.pitch, yaw = self.targetRot.yaw}}
	self.transition = tween.new(self.transitionTime, props, target, self.transitionFunc) -- Setup tweening
end

function workspot:exit()
	if not self.inWorkspot then return end

	self.inWorkspot = false
	self.exitingWorkspot = true

	local props = {pos = {x = self.targetPos.x, y = self.targetPos.y, z = self.targetPos.z}, rot = {roll = self.targetRot.roll, pitch = self.targetRot.pitch, yaw = self.targetRot.yaw}}
	local target = {pos = {x = self.originPos.x, y = self.originPos.y, z = self.originPos.z}, rot = {roll = self.originRot.roll, pitch = self.originRot.pitch, yaw = self.originRot.yaw}}
	self.transition = tween.new(self.transitionTime, props, target, self.transitionFunc) -- Setup tweening
end

function workspot:update(dt) -- Update workspot
	if self.enteringWorkspot then
		local done = self.transition:update(dt)
		if done then
			self.enteringWorkspot = false
			self.inWorkspot = true
		end
		self:updatePos()
	elseif self.exitingWorkspot then
		local done = self.transition:update(dt)
		if done then
			self.exitingWorkspot = false
			self:removeRestrictions()
			self.as.logic:onExitedWorkspot()
		end
		self:updatePos()
	elseif self.inWorkspot then
		Game.GetTeleportationFacility():Teleport(GetPlayer(), self.targetPos, self.targetRot)
		Game.GetPlayer():GetFPPCameraComponent().pitchMin = self.targetRot.pitch - 0.01
		Game.GetPlayer():GetFPPCameraComponent().pitchMax = self.targetRot.pitch
	end
end

function workspot:updatePos()
	local currentPos = Vector4.new(self.transition.subject.pos.x, self.transition.subject.pos.y, self.transition.subject.pos.z, 0)
	local currentRot = EulerAngles.new(self.transition.subject.rot.roll, self.transition.subject.rot.pitch, self.transition.subject.rot.yaw)

	Game.GetTeleportationFacility():Teleport(GetPlayer(), currentPos, currentRot)
	Game.GetPlayer():GetFPPCameraComponent().pitchMin = currentRot.pitch - 0.01
	Game.GetPlayer():GetFPPCameraComponent().pitchMax = currentRot.pitch
end

function workspot:forceExit()
	self:removeRestrictions()
	Game.GetTeleportationFacility():Teleport(GetPlayer(), self.originPos, self.originRot)
	Game.GetPlayer():GetFPPCameraComponent().pitchMin = self.originRot.pitch - 0.01
	Game.GetPlayer():GetFPPCameraComponent().pitchMax = self.originRot.pitch
end

function workspot:applyRestrictions()
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoMovement")
	Game.ApplyEffectOnPlayer("GameplayRestriction.FastForwardCrouchLock")
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoZooming")
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoScanning")
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoCombat")
	Game.ApplyEffectOnPlayer("GameplayRestriction.VehicleNoSummoning")
	Game.ApplyEffectOnPlayer("GameplayRestriction.NoPhone")
	StatusEffectHelper.RemoveStatusEffectsWithTag(GetPlayer(), "Breathing")

	if GetMod("ImmersiveFirstPerson") then
		GetMod("ImmersiveFirstPerson").api.Disable()
	end
end

function workspot:removeRestrictions()
	Game.RemoveEffectPlayer("GameplayRestriction.NoMovement")
	Game.RemoveEffectPlayer("GameplayRestriction.NoZooming")
	Game.RemoveEffectPlayer("GameplayRestriction.NoScanning")
	Game.RemoveEffectPlayer("GameplayRestriction.NoCombat")
	Game.RemoveEffectPlayer("GameplayRestriction.FastForwardCrouchLock")
	Game.RemoveEffectPlayer("GameplayRestriction.VehicleNoSummoning")
	Game.RemoveEffectPlayer("GameplayRestriction.NoPhone")
	GetPlayer():ReevaluateAllBreathingEffects()

	if GetMod("ImmersiveFirstPerson") then
		GetMod("ImmersiveFirstPerson").api.Enable()
	end
end

return workspot