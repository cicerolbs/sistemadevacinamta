local config = loadfile('config.lua')()
local diseaseTimers = {}
local pendingOffers = {}

local function isSAMU(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then return false end
    return isObjectInACLGroup('user.' .. getAccountName(account), aclGetGroup(config.aclGroup))
end

local function getPlayerByID(id)
    id = tonumber(id)
    if not id then return nil end
    for _,p in ipairs(getElementsByType('player')) do
        if tonumber(getElementData(p, 'id')) == id then
            return p
        end
    end
    return nil
end

local function startDisease(player)
    if not isElement(player) then return end
    if getElementData(player, 'vaccine.protected') then return end
    setElementData(player, 'vaccine.sick', true)
    triggerClientEvent(player, 'vaccine:effects', resourceRoot, true)
    local interval = config.disease.healthInterval * 60000
    diseaseTimers[player] = setTimer(function()
        if isElement(player) and getElementData(player, 'vaccine.sick') then
            local health = getElementHealth(player)
            setElementHealth(player, math.max(health - config.disease.healthAmount, 0))
        end
    end, interval, 0)
end

local function scheduleDisease(player)
    if not isElement(player) then return end
    local delay = config.disease.startMinutes * 60000
    setTimer(startDisease, delay, 1, player)
end

local function giveProtection(player, minutes)
    if diseaseTimers[player] and isTimer(diseaseTimers[player]) then
        killTimer(diseaseTimers[player])
        diseaseTimers[player] = nil
    end
    setElementData(player, 'vaccine.sick', false)
    triggerClientEvent(player, 'vaccine:effects', resourceRoot, false)
    setElementData(player, 'vaccine.protected', true)
    setTimer(function()
        if isElement(player) then
            setElementData(player, 'vaccine.protected', false)
            scheduleDisease(player)
        end
    end, minutes * 60000, 1)
end

addEventHandler('onResourceStart', resourceRoot, function()
    for _,p in ipairs(getElementsByType('player')) do
        scheduleDisease(p)
    end
end)

addEventHandler('onPlayerJoin', root, function()
    scheduleDisease(source)
end)

addCommandHandler('vacina', function(player, cmd, id)
    if not isSAMU(player) then
        exports['[HS]Notify_System']:notify(player, 'Você não tem permissão.', 'error')
        return
    end
    local target = getPlayerByID(id)
    if not target then
        exports['[HS]Notify_System']:notify(player, 'Jogador não encontrado.', 'error')
        return
    end
    local x1,y1,z1 = getElementPosition(player)
    local x2,y2,z2 = getElementPosition(target)
    local dist = getDistanceBetweenPoints3D(x1,y1,z1,x2,y2,z2)
    if dist < 1 or dist > 4 then
        exports['[HS]Notify_System']:notify(player, 'Fique entre 1m e 4m do jogador.', 'error')
        return
    end
    pendingOffers[target] = {from = player}
    exports['[HS]Notify_System']:notify(target, 'Uma vacina está sendo oferecida. Use /aceitar.', 'info')
    exports['[HS]Notify_System']:notify(player, 'Oferta enviada.', 'success')
    setTimer(function() pendingOffers[target] = nil end, config.vaccination.offerTimeout, 1)
end)

addCommandHandler('aceitar', function(player)
    local offer = pendingOffers[player]
    if not offer then
        exports['[HS]Notify_System']:notify(player, 'Nenhuma oferta de vacina.', 'error')
        return
    end
    pendingOffers[player] = nil
    local price = config.vaccination.price
    if getPlayerMoney(player) < price then
        exports['[HS]Notify_System']:notify(player, 'Dinheiro insuficiente.', 'error')
        return
    end
    takePlayerMoney(player, price)
    givePlayerMoney(offer.from, price)
    exports['[HS]Notify_System']:notify(player, 'Vacina aplicada.', 'success')
    exports['[HS]Notify_System']:notify(offer.from, 'Você aplicou a vacina.', 'success')
    giveProtection(player, config.vaccination.protectionMinutes)
end)

-- Shop marker
do
    local pos = config.shop.position
    local marker = createMarker(pos.x, pos.y, pos.z - 1, 'cylinder', 1.5, 0,255,0,150)
    addEventHandler('onMarkerHit', marker, function(player)
        if getElementType(player) ~= 'player' then return end
        triggerClientEvent(player, 'vaccine:showShop', resourceRoot)
    end)
end

addEvent('vaccine:buy', true)
addEventHandler('vaccine:buy', root, function()
    local price = config.shop.price
    if getPlayerMoney(client) < price then
        exports['[HS]Notify_System']:notify(client, 'Dinheiro insuficiente.', 'error')
        return
    end
    takePlayerMoney(client, price)
    exports['[HS]Notify_System']:notify(client, 'Vacina comprada.', 'success')
    giveProtection(client, config.shop.protectionHours * 60)
end)

