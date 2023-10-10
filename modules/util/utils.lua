---@diagnostic disable: undefined-doc-name
miscUtils = {}

function miscUtils.deepcopy(origin)
	local orig_type = type(origin)
    local copy
    if orig_type == 'table' then
        copy = {}
        for origin_key, origin_value in next, origin, nil do
            copy[miscUtils.deepcopy(origin_key)] = miscUtils.deepcopy(origin_value)
        end
        setmetatable(copy, miscUtils.deepcopy(getmetatable(origin)))
    else
        copy = origin
    end
    return copy
end

function miscUtils.distanceVector(from, to)
    return math.sqrt((to.x - from.x)^2 + (to.y - from.y)^2 + (to.z - from.z)^2)
end

function miscUtils.indexValue(table, value)
    local index={}
    for k,v in pairs(table) do
        index[v]=k
    end
    return index[value]
end

function miscUtils.has_value(tab, val)
    for _, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function miscUtils.getIndex(tab, val)
    local index = nil
    for i, v in ipairs(tab) do
		if v == val then
			index = i
		end
    end
    return index
end

function miscUtils.removeItem(tab, val)
    table.remove(tab, miscUtils.getIndex(tab, val))
end

function miscUtils.addVector(v1, v2)
    return Vector4.new(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z, v1.w + v2.w)
end

function miscUtils.subVector(v1, v2)
    return Vector4.new(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z, v1.w - v2.w)
end

function miscUtils.multVector(v1, factor)
    return Vector4.new(v1.x * factor, v1.y * factor, v1.z * factor, v1.w * factor)
end

function miscUtils.multVecXVec(v1, v2)
    return Vector4.new(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z, v1.w * v2.w)
end

function miscUtils.addEuler(e1, e2)
    return EulerAngles.new(e1.roll + e2.roll, e1.pitch + e2.pitch, e1.yaw + e2.yaw)
end

function miscUtils.subEuler(e1, e2)
    return EulerAngles.new(e1.roll - e2.roll, e1.pitch - e2.pitch, e1.yaw - e2.yaw)
end

function miscUtils.multEuler(e1, factor)
    return EulerAngles.new(e1.roll * factor, e1.pitch * factor, e1.yaw * factor)
end

function miscUtils.fromVector(vector) -- Returns table with x y z w from given Vector4
    return {x = vector.x, y = vector.y, z = vector.z, w = vector.w}
end

function miscUtils.fromQuaternion(quat) -- Returns table with i j k r from given Quaternion
    return {i = quat.i, j = quat.j, k = quat.k, r = quat.r}
end

function miscUtils.getVector(tab) -- Returns Vector4 object from given table containing x y z w
    return(Vector4.new(tab.x, tab.y, tab.z, tab.w))
end

function miscUtils.getQuaternion(tab) -- Returns Quaternion object from given table containing i j k r
    return(Quaternion.new(tab.i, tab.j, tab.k, tab.r))
end

function miscUtils.fromEuler(eul) -- Returns table with roll pitch yaw from given EulerAngles
    return {roll = eul.roll, pitch = eul.pitch, yaw = eul.yaw}
end

function miscUtils.getEuler(tab) -- Returns EulerAngles object from given table containing roll pitch yaw
    return(EulerAngles.new(tab.roll, tab.pitch, tab.yaw))
end

function miscUtils.distanceVector(from, to)
    return math.sqrt((to.x - from.x)^2 + (to.y - from.y)^2 + (to.z - from.z)^2)
end

-- All this code has been created by psiberx
function miscUtils.createInteractionChoice(action, title)
    local choiceData =  InteractionChoiceData.new()
    choiceData.localizedName = title
    choiceData.inputAction = action

    local choiceType = ChoiceTypeWrapper.new()
    choiceType:SetType(gameinteractionsChoiceType.Blueline)
    choiceData.type = choiceType

    return choiceData
end

function miscUtils.prepareVisualizersInfo(hub)
    local visualizersInfo = VisualizersInfo.new()
    visualizersInfo.activeVisId = hub.id
    visualizersInfo.visIds = { hub.id }

    return visualizersInfo
end

function miscUtils.createInteractionHub(titel, action, active)
    local choiceHubData =  InteractionChoiceHubData.new()
    choiceHubData.id = -1001
    choiceHubData.active = active
    choiceHubData.flags = EVisualizerDefinitionFlags.Undefined
    choiceHubData.title = titel

    local choices = {}
    table.insert(choices, miscUtils.createInteractionChoice(action, titel))
    choiceHubData.choices = choices

    local visualizersInfo = miscUtils.prepareVisualizersInfo(choiceHubData)

    local blackboardDefs = Game.GetAllBlackboardDefs()
    local interactionBB = Game.GetBlackboardSystem():Get(blackboardDefs.UIInteractions)
    interactionBB:SetVariant(blackboardDefs.UIInteractions.InteractionChoiceHub, ToVariant(choiceHubData), true)
    interactionBB:SetVariant(blackboardDefs.UIInteractions.VisualizersInfo, ToVariant(visualizersInfo), true)
end
-- ^^^^ All this code has been created by psiberx ^^^^

function miscUtils.showInputHint(key, text, prio, holdAnimation, source)
    local hold = holdAnimation or false
    local evt = UpdateInputHintEvent.new()
    local data = InputHintData.new()
    data.action = key
    data.source = source or "arcade"
    data.localizedLabel = text
    data.enableHoldAnimation = hold
    data.sortingPriority  = prio or 1
    evt = UpdateInputHintEvent.new()
    evt.data = data
    evt.show = true
    evt.targetHintContainer = "GameplayInputHelper"
    Game.GetUISystem():QueueEvent(evt)
end

function miscUtils.hideCustomHints(source)
    if not Game.GetUISystem() then return end

    local evt = DeleteInputHintBySourceEvent.new()
    evt.source = source or "arcade"
    evt.targetHintContainer = "GameplayInputHelper"
    Game.GetUISystem():QueueEvent(evt)
end

---@param path string
---@param pos Vector4
---@param rot Quaternion
---@return entityID
function miscUtils.spawnObject(path, pos, rot)
    local transform = Game.GetPlayer():GetWorldTransform()
    transform:SetOrientation(rot)
    transform:SetPosition(pos)
    local entityID = exEntitySpawner.Spawn(path, transform)
    return entityID
end

function miscUtils.ragdollNPC(force, npc)
    local player = GetPlayer()
    local target = npc or Game.GetTargetingSystem():GetLookAtObject(player)

    if not target then
        return
    end

    local vecadd = Game['OperatorAdd;Vector4Vector4;Vector4']
    local vecmulf = Game['OperatorMultiply;Vector4Float;Vector4']

    target:QueueEvent(CreateForceRagdollEvent("Debug Command"))

    local distance = Vector4.Distance(target:GetWorldPosition(), GetPlayer():GetWorldPosition())
    local playerCamPos = GetPlayer():GetWorldPosition()
    local playerCamFwd = Game.GetCameraSystem():GetActiveCameraForward()
    local pulseOrigin = vecadd(playerCamPos, vecmulf(Vector4.Normalize(playerCamFwd), distance * 0.85))

    Game.GetDelaySystem():DelayEvent(target, CreateRagdollApplyImpulseEvent(pulseOrigin, vecmulf(Vector4.Normalize(playerCamFwd), force), 5.00), 0.10, false)
end

function miscUtils.isSameInstance(a, b)
	return Game['OperatorEqual;IScriptableIScriptable;Bool'](a, b)
end

function miscUtils.multColor(color, x)
    return HDRColor.new({ Red = color.Red * x, Green = color.Green * x, Blue = color.Blue * x, Alpha = color.Alpha * x })
end

function miscUtils.rotate2D(x, y, degree)
    local deg = math.rad(degree)
    return {x = (x * math.cos(deg) - y * math.sin(deg)),
            y = (x * math.sin(deg) + y * math.cos(deg))}
end

function miscUtils.distance2D(x1, y1, x2, y2)
	local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
end

function miscUtils.spendMoney(amount)
    local tdbid = TweakDBID.new("Items.money")
    local moneyId = gameItemID.FromTDBID(tdbid)
    Game.GetTransactionSystem():RemoveItem(Game.GetPlayer(), moneyId, amount)
end

function miscUtils.playSound(name, mult)
    local m = mult or 1

    for _ = 1, m do
        local audioEvent = SoundPlayEvent.new ()
        audioEvent.soundName = name
        GetPlayer():QueueEvent(audioEvent)
    end
end

function miscUtils.stopSound(name)
    local audioEvent = SoundStopEvent.new()
    audioEvent.soundName = name
    GetPlayer():QueueEvent(audioEvent)
end

function miscUtils.applyStatus(effect)
    Game.GetStatusEffectSystem():ApplyStatusEffect(GetPlayer():GetEntityID(), effect, GetPlayer():GetRecordID(), GetPlayer():GetEntityID())
end

function miscUtils.removeStatus(effect)
    Game.GetStatusEffectSystem():RemoveStatusEffect(GetPlayer():GetEntityID(), effect)
end

return miscUtils