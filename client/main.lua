local config = require 'config.client'
PlayerState = LocalPlayer.state
local displayBars = false
local toggleHud = true
local toggleCinematic = false
local SendNUIMessage = SendNUIMessage

local function initHud()
    if config.minimapAlwaysOn then
        DisplayRadar(PlayerState.isLoggedIn)
    end
    SendNUIMessage({
        update = true,
        data = {
            { type = 'showHud', value = PlayerState.isLoggedIn },
            { type = 'progress', name = 'hunger', value = PlayerState.hunger or 0 },
            { type = 'progress', name = 'thirst', value = PlayerState.thirst or 0 },
            { type = 'progress', name = 'stress', value = PlayerState.stress or 0 },
            { type = 'progress', name = 'voice', value = PlayerState?.proximity?.distance and PlayerState?.proximity?.distance * 10 },
        }
    })
end

AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value then
        initHud()
    end

    if config.minimapAlwaysOn then
        DisplayRadar(value)
    else
        DisplayRadar(value == false)
    end

    SendNUIMessage({
        update = true,
        data = {
            {
                type = 'showHud',
                value = value,
            }
        }
    })
end)

CreateThread(function()
    SetTimeout(250, initHud)

    -- Disable the minimap in character selection
    if not PlayerState.isLoggedIn then
        DisplayRadar(false)
    end

    Wait(500)
    SetMinimapComponent(15, true, 0)
    SetRadarBigmapEnabled(false, false)
    FlashMinimapDisplay()
    SetRadarZoom(200)
end)

local function BlackBars()
    DrawRect(0.0, 0.0, 2.0, config.cinematicHeight, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, config.cinematicHeight, 0, 0, 0, 255)
end

local function cinematicThread()
    CreateThread(function()
        while displayBars do
            BlackBars()
            Wait(0)
        end
    end)
end

local function togglehud()
    toggleHud = not toggleHud
    if displayBars then
        toggleHud = false
    end

    DisplayRadar(toggleHud)
    SendNUIMessage({
        update = true,
        data = {
            {
                type = 'showHud',
                value = toggleHud,
            }
        }
    })
end

local function toggleCinematicMode()
    toggleCinematic = not toggleCinematic
    if toggleCinematic then
        cinematicThread()
        displayBars = true
    else
        displayBars = false
    end
    togglehud()
end

RegisterNetEvent('qbx_hud:client:toggleCinematicMode', function()
    toggleCinematicMode()
    exports.qbx_core:Notify(locale(("notify.cinematic_%s"):format(toggleCinematic and 'on' or 'off')))
end)

RegisterNetEvent('qbx_hud:client:hideHud', function()
    SendNUIMessage({
        update = true,
        data = {
            {
                type = 'showHud',
                value = false,
            }
        }
    })
end)

RegisterNetEvent('qbx_hud:client:showHud', function()
    if not toggleCinematic and toggleHud then
        SendNUIMessage({
            update = true,
            data = {
                {
                    type = 'showHud',
                    value = true,
                }
            }
        })
    end
end)

RegisterNetEvent('qbx_hud:client:togglehud', function()
    if not displayBars then
        togglehud()
        exports.qbx_core:Notify(locale(("notify.hud_%s"):format(toggleHud and 'on' or 'off')))
    end
end)