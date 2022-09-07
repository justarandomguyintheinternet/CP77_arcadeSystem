local Cron = require("modules/external/Cron")
local utils = require("modules/util/utils")

observers = {
    noSave = false
}

function observers.startInputObserver(as)

    Override("gameScriptableSystem", "IsSavingLocked", function(_, wrapped)
        if observers.noSave then
            return true
        else
            return wrapped()
        end
    end)

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
        end

        if as.logic.currentWorkspot then
            if as.logic.currentWorkspot.inWorkspot then
                as.logic.currentArcade.game:handleInput(action)
            end
        end
    end)

    Override("ArcadeMachine", "SetupMinigame", function(this) -- Rebalance Probability
        local panzerMovie = ResRef.FromString("base\\movies\\misc\\arcade\\hishousai_panzer.bk2")
        local quadracerMovie = ResRef.FromString("base\\movies\\misc\\arcade\\quadracer.bk2")
        local retrosMovie = ResRef.FromString("base\\movies\\misc\\arcade\\retros.bk2")
        local roachraceMovie1 = ResRef.FromString("base\\movies\\misc\\arcade\\roach_race.bk2")
        local roachraceMovie2 = ResRef.FromString("base\\movies\\misc\\arcade\\roachrace.bk2")
        local minigame = ArcadeMinigame.INVALID
        this.currentGame = this:GetDevicePS():GetGameVideoPath()
        if not ResRef.IsValid(this.currentGame) then
            local randValue = RandRange(0, 4)
            if randValue == 0 then
                this.currentGame = panzerMovie
            elseif randValue == 1 then
                this.currentGame = quadracerMovie
            elseif randValue == 2 then
                this.currentGame = retrosMovie
            else
                this.currentGame = roachraceMovie1
            end
        end
        if Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGame, panzerMovie) then
            minigame = ArcadeMinigame.Panzer
            this.currentGameAudio = "mus_cp_arcade_panzer_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_panzer_STOP"
            this.meshAppearanceOn = "ap4"
            this.meshAppearanceOff = "ap4_off"
        elseif Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGame, quadracerMovie) then
            minigame = ArcadeMinigame.Quadracer
            this.currentGameAudio = "mus_cp_arcade_quadra_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_quadra_STOP"
            this.meshAppearanceOn = "ap1"
            this.meshAppearanceOff = "ap1_off"
        elseif Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGame, retrosMovie) then
            minigame = ArcadeMinigame.Retros
            this.currentGameAudio = "mus_cp_arcade_shooter_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_shooter_STOP"
            this.meshAppearanceOn = "ap3"
            this.meshAppearanceOff = "ap3_off"
        elseif Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGame, roachraceMovie1) or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGame, roachraceMovie2) then
            minigame = ArcadeMinigame.RoachRace
            this.currentGameAudio = "mus_cp_arcade_roach_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_roach_STOP"
            this.meshAppearanceOn = "ap2"
            this.meshAppearanceOff = "ap2_off"
        else
            minigame = ArcadeMinigame.INVALID
            this.meshAppearanceOn = "default"
            this.meshAppearanceOff = "default"
        end
        this:GetDevicePS():SetArcadeMinigame(minigame)
    end)

    ObserveAfter("ArcadeMachine", "SetupMinigame", function(this) -- For naturally spawning machines
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