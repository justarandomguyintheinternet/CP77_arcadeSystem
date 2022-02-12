local Cron = require("modules/external/Cron")

observers = {}

function observers.startInputObserver(as)

    Observe('PlayerPuppet', 'OnGameAttached', function(this)
        observers.startListeners(this)
    end)

    Observe('PlayerPuppet', 'OnAction', function(_, action)
        local actionName = Game.NameToString(action:GetName(action))
        local actionType = action:GetType(action).value
        if actionName == 'UI_Apply' then
            if actionType == 'BUTTON_PRESSED' then
                as.logic:onInteract()
            end
        elseif actionName == 'UI_Exit' then
            if actionType == 'BUTTON_PRESSED' then
                as.logic:tryExitWorkspot()
            end
        end

        if as.logic.currentWorkspot then
            if as.logic.currentWorkspot.inWorkspot then
                as.logic.currentArcade.game:handleInput(action)
            end
        end
    end)

    ObserveAfter("ArcadeMachine", "InitializeGameAudioVisuals", function(this) -- For naturally spawning machines
        if this and this:GetClassName().value == "ArcadeMachine" then
            as.logic:addMachine(this)
        end
    end)

    Observe("ArcadeMachineInkGameController", "OnUninitialize", function (self)
        local this = self:GetOwner()
        if this and this:GetClassName().value == "ArcadeMachine" then
            as.logic:removeMachine(this)
        end
    end)

    Observe("ArcadeMachineInkGameController", "PlayVideo", function (self) -- For machines that dont get despawned, e.g. spawned with AMM
        local this = self:GetOwner()
        Cron.After(0.5, function ()
            as.logic:addMachine(this)
        end)
    end)
end

function observers.startListeners(player)
    player:UnregisterInputListener(player, 'UI_Apply')
    player:UnregisterInputListener(player, 'UI_Exit')

    player:RegisterInputListener(player, 'UI_Apply')
    player:RegisterInputListener(player, 'UI_Exit')
end

return observers