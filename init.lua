-------------------------------------------------------------------------------------------------------------------------------
-- This mod was created by keanuWheeze from CP2077 Modding Tools Discord.
--
-- You are free to use this mod as long as you follow the following license guidelines:
--    * It may not be uploaded to any other site without my express permission.
--    * Using any code contained herein in another mod requires credits / asking me.
--    * You may not fork this code and make your own competing version of this mod available for download without my permission.
--
-------------------------------------------------------------------------------------------------------------------------------

as = {
    runtimeData = {
        cetOpen = false,
        inMenu = false,
        inGame = false
    },

    defaultSettings = {},
    settings = {},
    observers = require("modules/util/observers"),
	Cron = require("modules/external/Cron"),
    GameUI = require("modules/external/GameUI"),
    utils = require("modules/util/utils")
}

function as:new()
    registerForEvent("onInit", function()
        CName.add("arcade")

        self.logic = require("modules/logic"):new(self)
        self.observers.startInputObserver(self)
        self.logic:startCron()

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            self.runtimeData.inMenu = isInMenu
        end)

        self.GameUI.OnSessionStart(function()
            self.runtimeData.inGame = true
        end)

        self.GameUI.OnSessionEnd(function()
            self.runtimeData.inGame = false
            self.logic.machines = {}
            self.utils.hideCustomHints()
        end)

        self.GameUI.OnPhotoModeOpen(function()
            self.runtimeData.inMenu = true
        end)

        self.GameUI.OnPhotoModeClose(function()
            self.runtimeData.inMenu = false
        end)

        self.runtimeData.inGame = not self.GameUI.IsDetached() -- Required to check if ingame after reloading all mods
    end)

    registerForEvent("onShutdown", function ()
        if self.logic.currentWorkspot then
            self.logic.currentWorkspot:forceExit()
            self.logic.currentArcade.game:stop()
        end
        self.utils.hideCustomHints()
    end)

    registerForEvent("onUpdate", function (deltaTime)
        if (not self.runtimeData.inMenu) and self.runtimeData.inGame then
		    self.Cron.Update(deltaTime)
            self.logic:run(deltaTime)
        end
    end)

    registerForEvent("onOverlayOpen", function()
        self.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        self.runtimeData.cetOpen = false
    end)

    return self

end

return as:new()