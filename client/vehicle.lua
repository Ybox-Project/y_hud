local config = require 'config.client'
local currentindicatorL, currentindicatorR = false, false
local getEntitySpeed = GetEntitySpeed
local getVehicleFuelLevel = GetVehicleFuelLevel
local getIsVehicleEngineRunning = GetIsVehicleEngineRunning
local getVehicleLightsState = GetVehicleLightsState
local getVehicleTrailerVehicle = GetVehicleTrailerVehicle
local getVehicleIndicatorLights = GetVehicleIndicatorLights
local isMinimapRendering = IsMinimapRendering
local isControlJustPressed = IsControlJustPressed
local setVehicleIndicatorLights = SetVehicleIndicatorLights
local sendNUIMessage = SendNUIMessage
local doesVehicleUseFuel = DoesVehicleUseFuel
local getVehicleEstimatedMaxSpeed = GetVehicleEstimatedMaxSpeed
local getGameTimer = GetGameTimer
local SPEED_MULTIPLIER = config.useMPH and 2.236936 or 3.6

local function playLowFuelAlert()
    exports.qbx_core:Notify(locale("notify.low_fuel"), "error")
    for _ = 1, 5 do
        qbx.playAudio({
            audioName = "CONFIRM_BEEP",
            audioRef = 'HUD_MINI_GAME_SOUNDSET',
            source = cache.vehicle
        })
        Wait(500)
    end
end

local function vehiclehudloop()
    local currentindicators = getVehicleIndicatorLights(cache.vehicle)
    local indl = currentindicators == 1 or currentindicators == 3
    local indr = currentindicators == 2 or currentindicators == 3
    local warning = false

    CreateThread(function()
        local sleep
        while cache.seat == -1 do
            sleep = 1000
                if getIsVehicleEngineRunning(cache.vehicle) and isMinimapRendering() then
                local HasTrailer, Trailer = getVehicleTrailerVehicle(cache.vehicle)
                if not warning and isControlJustPressed(1, 174) then     -- <- is pressed
                    indl = not indl
                    indr = false
                end
                if not warning and isControlJustPressed(1, 175) then     -- -> is pressed
                    indr = not indr
                    indl = false
                end
                if isControlJustPressed(1, 173) then     -- down is pressed
                    warning = not warning
                    indl = warning
                    indr = warning
                end

                if isMinimapRendering() and (currentindicatorL ~= indl or currentindicatorR ~= indr) then
                    currentindicatorL, currentindicatorR = indl, indr

                    setVehicleIndicatorLights(cache.vehicle, 1, indl)
                    setVehicleIndicatorLights(cache.vehicle, 0, indr)
                    if HasTrailer then
                        setVehicleIndicatorLights(Trailer, 1, indl)
                        setVehicleIndicatorLights(Trailer, 0, indr)
                    end

                    sendNUIMessage({
                        update = true,
                        data = {
                            {
                                type = 'dashboardlights',
                                indicatorL = indl,
                                indicatorR = indr,
                            }
                        }
                    })
                end
                sleep = 0
            end
            Wait(sleep)
        end
    end)

    CreateThread(function()
        local sleep
        local showingHud = true
        local lastAlertTime
        while cache.vehicle do
            local data
            local engineIsRunning = getIsVehicleEngineRunning(cache.vehicle)
            if showingHud and not engineIsRunning then
                data = {
                    {
                        type = 'vehiclehud',
                        show = false
                    }
                }
                showingHud = false
            end

            sleep = 1000
            if engineIsRunning and isMinimapRendering() then
                showingHud = true
                local _, highbeam, lowbeam = getVehicleLightsState(cache.vehicle)
                data = {
                    {
                        type = 'vehiclehud',
                        show = true
                    },
                    {
                        type = 'speed',
                        speed = getEntitySpeed(cache.vehicle) * SPEED_MULTIPLIER
                    },
                    {
                        type = 'gauge',
                        name = 'fuel',
                        value = getVehicleFuelLevel(cache.vehicle) or 100
                    },
                    {
                        type = 'dashboardlights',
                        highbeam = highbeam,
                        lowbeam = lowbeam,
                    }
                }


                if doesVehicleUseFuel(cache.vehicle) and config.lowFuelAlert and getVehicleFuelLevel(cache.vehicle) < config.lowFuelAlert then
                    if not lastAlertTime or getGameTimer() - lastAlertTime > 1000 * config.lowFuelAlertInterval then
                        lastAlertTime = getGameTimer()
                        playLowFuelAlert()
                    end
                end
                sleep = 100
            end

            if data then
                sendNUIMessage({
                    update = true,
                    data = data
                })
            end
            Wait(sleep)
        end
    end)
end

local function initVehicleHud()
    local data = {
        {
            type = 'vehiclehud',
            show = false
        }
    }

    if cache.seat == -1 then
        local nitroLevel = Entity(cache.vehicle).state.nitro or 0
        data = {
            {
                type = 'gauge',
                name = 'nitro',
                value = nitroLevel,
                show = nitroLevel > 0
            },
            {
                type = 'gauge',
                name = 'fuel',
                value = getVehicleFuelLevel(cache.vehicle) or 0,
                show = doesVehicleUseFuel(cache.vehicle) or getVehicleFuelLevel(cache.vehicle) > 0
            },
            {
                type = 'speedmax',
                speed = ((getVehicleEstimatedMaxSpeed(cache.vehicle) * 3.6) -- should result a value ~ equal to fInitialDriveMaxFlatVel
                * (SPEED_MULTIPLIER == 3.6 and 1.32 or 0.82)) -- transform to real speed according to online sources (multiply by 1.32 for km/h and 0.82 for mph)
            }
        }
        vehiclehudloop()
    end

    sendNUIMessage({
        update = true,
        data = data
    })
end

qbx.entityStateHandler('nitro', function(veh, _, value)
    if veh ~= cache.vehicle then return end
    sendNUIMessage({
        update = true,
        data = {
            {
                type = 'gauge',
                name = 'nitro',
                value = value,
                show = value > 0
            }
        }
    })
end)

lib.onCache('vehicle', function(value)
    if not value then
        PlayerState:set('seatbelt', false, true)
        PlayerState:set('harness', false, true)
        sendNUIMessage({
            update = true,
            data = {
                {
                    type = 'vehiclehud',
                    show = false
                },
                {
                    type = 'seatbelt',
                    value = false,
                }
            }
        })
    end
    if not config.minimapAlwaysOn then
        DisplayRadar(value)
    end
end)

lib.onCache('seat', function(seat)
    if seat == -1 then
        SetTimeout(250, initVehicleHud)
    end
end)

CreateThread(function()
    SetTimeout(250, initVehicleHud)
end)

local harnessOn = false
AddStateBagChangeHandler('seatbelt', ('player:%s'):format(cache.serverId), function(_, _, value)
    if harnessOn then return end
    sendNUIMessage({
        update = true,
        data = {
            {
                type = 'seatbelt',
                value = value,
            }
        }
    })
end)

AddStateBagChangeHandler('harness', ('player:%s'):format(cache.serverId), function(_, _, value)
    harnessOn = value

    sendNUIMessage({
        update = true,
        data = {
            {
                type = 'seatbelt',
                value = value or PlayerState.seatbelt,
                harness = value,
            }
        }
    })
end)