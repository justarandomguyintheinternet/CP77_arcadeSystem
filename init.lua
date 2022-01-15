-------------------------------------------------------------------------------------------------------------------------------
-- This mod was created by keanuWheeze from CP2077 Modding Tools Discord.
--
-- You are free to use this mod as long as you follow the following license guidelines:
--    * It may not be uploaded to any other site without my express permission.
--    * Using any code contained herein in another mod requires credits / asking me.
--    * You may not fork this code and make your own competing version of this mod available for download without my permission.
--
-------------------------------------------------------------------------------------------------------------------------------
-- Credits:
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
    GameUI = require("modules/external/GameUI")
}

function as:new()
    registerForEvent("onInit", function()
        as.logic = require("modules/logic"):new(as)
        as.observers.startInputObserver(as)

        Observe('RadialWheelController', 'OnIsInMenuChanged', function(_, isInMenu) -- Setup observer and GameUI to detect inGame / inMenu
            as.runtimeData.inMenu = isInMenu
        end)

        as.GameUI.OnSessionStart(function()
            as.runtimeData.inGame = true
        end)

        as.GameUI.OnSessionEnd(function()
            as.runtimeData.inGame = false
        end)

        as.GameUI.OnPhotoModeOpen(function()
            as.runtimeData.inMenu = true
        end)

        as.GameUI.OnPhotoModeClose(function()
            as.runtimeData.inMenu = false
        end)

        as.runtimeData.inGame = not as.GameUI.IsDetached() -- Required to check if ingame after reloading all mods
    end)

    registerForEvent("onShutdown", function ()
        if as.logic.currentWorkspot then
            as.logic.currentWorkspot:forceExit()
        end
    end)

    registerForEvent("onUpdate", function (deltaTime)
        if (not as.runtimeData.inMenu) and as.runtimeData.inGame then
		    as.Cron.Update(deltaTime)
            as.logic:run(deltaTime)
        end
    end)

    registerForEvent("onDraw", function()

    end)

    registerForEvent("onOverlayOpen", function()
        as.runtimeData.cetOpen = true
    end)

    registerForEvent("onOverlayClose", function()
        as.runtimeData.cetOpen = false
    end)

    return as

end

return as:new()