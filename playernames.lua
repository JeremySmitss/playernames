local mpGamerTags = {}
local mpGamerTagSettings = {}

-- gebruik deze export als je versie 1.9.5+ gebruikt :P
ESX = exports['es_extended']:getSharedObject()

--[[ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end) --]]


local gtComponent = {
    GAMER_NAME = 0,
    CREW_TAG = 1,
    healthArmour = 2,
    BIG_TEXT = 3,
    AUDIO_ICON = 4,
    MP_USING_MENU = 5,
    MP_PASSIVE_MODE = 6,
    WANTED_STARS = 7,
    MP_DRIVER = 8,
    MP_CO_DRIVER = 9,
    MP_TAGGED = 10,
    GAMER_NAME_NEARBY = 11,
    ARROW = 12,
    MP_PACKAGES = 13,
    INV_IF_PED_FOLLOWING = 14,
    RANK_TEXT = 15,
    MP_TYPING = 16
}

local function makeSettings()
    return {
        alphas = {},
        colors = {},
        healthColor = false,
        toggles = {},
        wantedLevel = false
    }
end

local templateStr = GetConvar('playerNames_svTemplate', '[{{id}}]')

local maxDistance = 1500
local alwaysShow = false

local showName = false
RegisterCommand('alwaysshowname', function()
    if showName == false then
        exports['esx_rpchat']:printToChat("EasyAdmin", "Spelernamen staan nu ^2aan")
        showName = true
    else
        if showName == true then
            exports['esx_rpchat']:printToChat("EasyAdmin", "Spelernamen staan nu ^8uit")
        showName = false
        end
    end
end)

local showBlip = false
RegisterCommand('alwaysshowblip', function()
    if showBlip == false then
        exports['esx_rpchat']:printToChat("EasyAdmin", "Spelerblips staan nu ^2aan")
        playerblips()    
        showBlip = true
    else
        if showBlip == true then
            exports['esx_rpchat']:printToChat("EasyAdmin", "Spelerblips staan nu ^8uit")
            showBlip = false
            removeblip()
        end
    end
end)

--[[RegisterCommand('alwaysshowname_test', function()
    local players = ESX.Game.GetPlayers()

    for k,v in ipairs(players) do
        local targetPed = GetPlayerPed(v)
        print(('A player with server id %s found at %s!'):format(GetPlayerServerId(v), GetEntityCoords(targetPed)))
    end
end)--]]

function playerblips()
    local blips = {}
    local ped = PlayerId()
    local players = ESX.Game.GetPlayers()

    for k,v in ipairs(players) do
        local targetPed = GetPlayerPed(v)

            local blip = AddBlipForEntity(targetPed)
            SetBlipColour(blip, 4)
            SetBlipScale(blip, 1.0)
            SetBlipDisplay(blip, 2)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(GetPlayerName(v))
            EndTextCommandSetBlipName(blip)
    end
end

function removeblip()
    local players = ESX.Game.GetPlayers()

    for k,v in ipairs(players) do
        local targetPed = GetPlayerPed(v)
        local blip = GetBlipFromEntity(targetPed)
        RemoveBlip(blip)
    end
end

-- wist niet zeker of deze werkt... 
--[[local whitelist = {
    steamname = ['Jeremyy']
}--]]

local function ShouldShowName(ped, distance, player)
    if distance > maxDistance then
        return false
    end
    local name = GetPlayerName(player)
    if whitelist[name] and not IsEntityVisible(ped) then
        return false
    end
    if alwaysShow and OnDuty then
        return true
    else
        return showName and ((IsEntityVisible(ped) and HasEntityClearLosToEntity(PlayerPedId(), ped, 273)) or NetworkIsInSpectatorMode())
    end
end

function ToggleNameCommand()
    HideName = not HideName
    GlobalState.HideName = HideName

    for k, v in pairs(mpGamerTagSettings) do
        v.rename = true
    end
end

RegisterKeyMapping('+showName', "Laat Id van speler zien", 'keyboard', 'z')

-- Dit is een leuke command :P, test zelf maar uit hihi
    --[[local spawnedPeds = {}
    RegisterCommand('fake_tags', function()
        if #spawnedPeds > 0 then
            for i = 1, #spawnedPeds do
                DeleteEntity(spawnedPeds[i])
            end
            spawnedPeds = {}
            return
        end
        local coords = GetEntityCoords(PlayerPedId())
        for i=1, 100 do
            local ped = ClonePed(PlayerPedId(), 0.0, true)
            NetworkRegisterEntityAsNetworked(ped)
            CreateFakeMpGamerTag(ped, "Jeremy" .. tostring(i), false, false, '', 0)
            table.insert(spawnedPeds, ped)
            SetEntityCoords(ped, coords)
            if i % 18 == 0 then
                coords = vector3(coords.x + 1, coords.y - 18 * 1, coords.z)
            else
                coords = vector3(coords.x, coords.y + 1, coords.z)
            end
            Citizen.Wait(0)
        end
    end)--]] 

local mpGamerTagsNetId = {}

AddEventHandler("onPlayerDropped", function(netId)
    local tagData = mpGamerTagsNetId[netId]
    if tagData then
        RemoveMpGamerTag(tagData.tag)
        mpGamerTagsNetId[netId] = nil
        mpGamerTags[tagData.player] = nil
    end
end)

Citizen.CreateThread(function()
    while true do
        -- return if no template string is set
        while not templateStr do
            Citizen.Wait(1000)
        end

        Citizen.Wait(1000)

        -- get local coordinates to compare to
        local localCoords = GetFinalRenderedCamCoord()
        local playerId = PlayerId()
        -- for each valid player index
        local players = GetActivePlayers()
        for i=1, #players do
            if i % 10 == 0 then
                Citizen.Wait(0)
            end
            local player = players[i]
            -- if the player exists
            if player ~= playerId then
                -- get their ped
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) then
                    local pedCoords = GetEntityCoords(ped)

                    -- make a new settings list if needed
                    if not mpGamerTagSettings[player] then
                        mpGamerTagSettings[player] = makeSettings()
                    end

                    -- check the ped, because changing player models may recreate the ped
                    -- also check gamer tag activity in case the game deleted the gamer tag
                    if not mpGamerTags[player] or mpGamerTags[player].ped ~= ped or not IsMpGamerTagActive(mpGamerTags[player].tag) then
                        local nameTag = formatPlayerNameTag(player, templateStr)

                        -- remove any existing tag
                        if mpGamerTags[player] then
                            RemoveMpGamerTag(mpGamerTags[player].tag)
                        end

                        -- store the new tag
                        mpGamerTags[player] = {
                            tag = CreateFakeMpGamerTag(ped, nameTag, false, false, '', 0),
                            ped = ped,
                            player = player
                        }
                        mpGamerTagsNetId[GetPlayerServerId(player)] = mpGamerTags[player]
                    end

                    -- store the tag in a local
                    local tag = mpGamerTags[player].tag

                    -- should the player be renamed? this is set by events
                    if mpGamerTagSettings[player].rename then
                        SetMpGamerTagName(tag, formatPlayerNameTag(player, templateStr))
                        mpGamerTagSettings[player].rename = nil
                    end

                    -- check distance
                    local distance = #(pedCoords - localCoords)

                    -- show/hide based on nearbyness/line-of-sight
                    -- nearby checks are primarily to prevent a lot of LOS checks
                    if (ShouldShowName(ped, distance, player)) then

                        SetMpGamerTagVisibility(tag, gtComponent.GAMER_NAME, true)
                        SetMpGamerTagVisibility(tag, gtComponent.AUDIO_ICON, NetworkIsPlayerTalking(player))

                        SetMpGamerTagAlpha(tag, gtComponent.AUDIO_ICON, 255)
                        SetMpGamerTagAlpha(tag, gtComponent.healthArmour, 255)

                        -- override settings
                        local settings = mpGamerTagSettings[player]

                        for k, v in pairs(settings.toggles) do
                            SetMpGamerTagVisibility(tag, gtComponent[k], v)
                        end

                        for k, v in pairs(settings.alphas) do
                            SetMpGamerTagAlpha(tag, gtComponent[k], v)
                        end

                        for k, v in pairs(settings.colors) do
                            SetMpGamerTagColour(tag, gtComponent[k], v)
                        end

                        if settings.wantedLevel then
                            SetMpGamerTagWantedLevel(tag, settings.wantedLevel)
                        end

                        if settings.healthColor then
                            SetMpGamerTagHealthBarColour(tag, settings.healthColor)
                        end
                    else
                        SetMpGamerTagVisibility(tag, gtComponent.GAMER_NAME, false)
                        SetMpGamerTagVisibility(tag, gtComponent.healthArmour, false)
                        SetMpGamerTagVisibility(tag, gtComponent.AUDIO_ICON, false)
                    end
                end
            elseif mpGamerTags[player] then
                RemoveMpGamerTag(mpGamerTags[player].tag)

                mpGamerTags[player] = nil
            end
        end
    end
end)

RegisterNetEvent("onPlayerDropped")
AddEventHandler("onPlayerDropped", function(source, name, slot)
    local player = GetPlayerFromServerId(source)
    if player ~= -1 and mpGamerTags[player] then
        -- remove any existing tag
        if mpGamerTags[player] then
            RemoveMpGamerTag(mpGamerTags[player].tag)
        end
        mpGamerTags[player] = nil
    end
end)

RegisterNetEvent("onPlayerJoining")
AddEventHandler("onPlayerJoining", function(source, name, slot)
    local player = GetPlayerFromServerId(source)
    if player == -1 then
        Citizen.Wait(1000)
        player = GetPlayerFromServerId(source)
    end

    if player ~= -1 and mpGamerTags[player] then
        RemoveMpGamerTag(mpGamerTags[player].tag)
        mpGamerTags[player] = nil
    end
end)

local function getSettings(id)
    local i = GetPlayerFromServerId(tonumber(id))

    if not mpGamerTagSettings[i] then
        mpGamerTagSettings[i] = makeSettings()
    end

    return mpGamerTagSettings[i]
end

RegisterNetEvent('playernames:configure')
AddEventHandler('playernames:configure', function(id, key, ...)
    local args = table.pack(...)

    if key == 'tglc' then
        getSettings(id).toggles[args[1]] = args[2]
    elseif key == 'seta' then
        getSettings(id).alphas[args[1]] = args[2]
    elseif key == 'setc' then
        getSettings(id).colors[args[1]] = args[2]
    elseif key == 'setw' then
        getSettings(id).wantedLevel = args[1]
    elseif key == 'sehc' then
        getSettings(id).healthColor = args[1]
    elseif key == 'rnme' then
        getSettings(id).rename = true
    elseif key == 'name' then
        getSettings(id).serverName = args[1]
        getSettings(id).rename = true
    elseif key == 'tpl' then
        for _, v in pairs(mpGamerTagSettings) do
            v.rename = true
        end

        templateStr = args[1]
    end
end)

AddEventHandler('playernames:extendContext', function(i, cb)
    cb('serverName', getSettings(GetPlayerServerId(i)).serverName)
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for _, v in pairs(mpGamerTags) do
            RemoveMpGamerTag(v.tag)
        end
    end
end)

SetTimeout(0, function()
    TriggerServerEvent('playernames:init')
end)
