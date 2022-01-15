local config = require("modules/util/config")

ui = {}

function ui.setupNativeUI(arcade)
    local nativeSettings = GetMod("nativeSettings")

    if not nativeSettings then
        print("[Real Arcades] Error: NativeSettings lib not found!")
        arcade.runtimeData.nativeSettingsInstalled = false
        return
    end

    local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip) -- <-- This has been made by psiberx, all credits to him
        return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
    end)))

    if cetVer < 1.18 then
        arcade.runtimeData.nativeSettingsInstalled = false
        return
    end

    nativeSettings.addTab("/arcade", "Real Arcades")
    nativeSettings.addSubcategory("/arcade/general", "General Settings")
end

return ui