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
        local randValue = -1
        local shooterMovie1 = ResRef.FromString("base\\movies\\misc\\arcade\\td_title_screen_press_start.bk2")
        local shooterMovie2 = ResRef.FromString("base\\movies\\misc\\arcade\\retros.bk2")
        local tankMovie = ResRef.FromString("base\\movies\\misc\\arcade\\hishousai_panzer.bk2")
        local quadracerMovie = ResRef.FromString("base\\movies\\misc\\arcade\\quadracer.bk2")
        local roachraceMovie1 = ResRef.FromString("base\\movies\\misc\\arcade\\roach_race.bk2")
        local roachraceMovie2 = ResRef.FromString("base\\movies\\misc\\arcade\\roachrace.bk2")

        if this.arcadeMachineType == ArcadeMachineType.Pachinko then return end
        randValue = math.random(0, 9)
        if randValue >= 8 or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGameVideo, quadracerMovie) then
            this.minigame = ArcadeMinigame.Quadracer
        elseif randValue >= 6 or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGameVideo, tankMovie) then
            this.minigame = ArcadeMinigame.Tank
        elseif randValue >= 3 or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGameVideo, roachraceMovie1) or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGameVideo, roachraceMovie2) then
            this.minigame = ArcadeMinigame.RoachRace
        elseif randValue >= 0 or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGameVideo, shooterMovie1) or Game['OperatorEqual;redResourceReferenceScriptTokenResRef;Bool'](this.currentGameVideo, shooterMovie2) then
            this.minigame = ArcadeMinigame.Shooter
        end

        if this.minigame == ArcadeMinigame.Quadracer then
            this.currentGameVideo = quadracerMovie
            this.currentGameAudio = "mus_cp_arcade_quadra_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_quadra_STOP"
            this.meshAppearanceOn = "ap1"
            this.meshAppearanceOff = "ap1_off"
        elseif this.minigame == ArcadeMinigame.RoachRace then
            this.currentGameVideo = roachraceMovie1
            this.currentGameAudio = "mus_cp_arcade_roach_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_roach_STOP"
            this.meshAppearanceOn = "ap2"
            this.meshAppearanceOff = "ap2_off"
        elseif this.minigame == ArcadeMinigame.Shooter then
              this.currentGameVideo = shooterMovie1
              this.currentGameAudio = "mus_cp_arcade_shooter_START_menu"
              this.currentGameAudioStop = "mus_cp_arcade_shooter_STOP"
              this.meshAppearanceOn = "ap3"
              this.meshAppearanceOff = "ap3_off"
        elseif this.minigame == ArcadeMinigame.Tank then
            this.currentGameVideo = tankMovie
            this.currentGameAudio = "mus_cp_arcade_panzer_START_menu"
            this.currentGameAudioStop = "mus_cp_arcade_panzer_STOP"
            this.meshAppearanceOn = "ap4"
            this.meshAppearanceOff = "ap4_off"
        end

        this:GetDevicePS():SetArcadeMinigame(this.minigame)
    end)

    -- ObserveAfter("ArcadeMachine", "SetupMinigame", function(this) -- For naturally spawning machines
    --     if this and this:GetClassName().value == "ArcadeMachine" then
    --         as.logic:addMachine(this)
    --         print(this.uiComponent:GetGameController())
    --     end
    -- end)

    Observe("ArcadeMachine", "OnBeginArcadeMinigameUI", function ()
        utils.spendMoney(2)
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