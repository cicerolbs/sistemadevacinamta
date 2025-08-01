local config = CONFIG
local diseaseDamageTimers = {}
local diseaseStartTimers = {}
local protectionTimers = {}
local pendingOffers = {}

local db = dbConnect('sqlite', 'vaccines.db')
dbExec(db, 'CREATE TABLE IF NOT EXISTS vaccines (serial TEXT PRIMARY KEY, vaccine_expires INTEGER, sick INTEGER, disease_time INTEGER)')

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

local function savePlayerData(player, protectedUntil, sick, diseaseTime)
    local serial = getPlayerSerial(player)
    if not serial then return end
    local prot = protectedUntil or (getElementData(player, 'vaccine.protectedUntil') or 0)
    local sickVal = sick ~= nil and (sick and 1 or 0) or (getElementData(player, 'vaccine.sick') and 1 or 0)
    local diseaseVal = diseaseTime or (getElementData(player, 'vaccine.nextDisease') or 0)
    dbExec(db, 'INSERT OR REPLACE INTO vaccines (serial, vaccine_expires, sick, disease_time) VALUES (?,?,?,?)', serial, prot, sickVal, diseaseVal)
end

local function startDisease(player)
    if not isElement(player) then return end
    if getElementData(player, 'vaccine.protected') then return end
    if diseaseStartTimers[player] and isTimer(diseaseStartTimers[player]) then
        killTimer(diseaseStartTimers[player])
        diseaseStartTimers[player] = nil
    end
    setElementData(player, 'vaccine.sick', true)
    savePlayerData(player, 0, true, 0)
    exports['[HS]Notify_System']:notify(player, 'Você está doente! Procure um SAMU ou vá ao hospital para vacinar-se.', 'warning')
    triggerClientEvent(player, 'vaccine:effects', resourceRoot, true)
    local interval = config.disease.healthInterval * 60000
    diseaseDamageTimers[player] = setTimer(function()
        if isElement(player) and getElementData(player, 'vaccine.sick') then
            local health = getElementHealth(player)
            setElementHealth(player, math.max(health - config.disease.healthAmount, 0))
        end
    end, interval, 0)
end

local function scheduleDisease(player, delay)
    if not isElement(player) then return end
    if diseaseStartTimers[player] and isTimer(diseaseStartTimers[player]) then
        killTimer(diseaseStartTimers[player])
    end
    local d = delay or config.disease.startMinutes
    local delayMs = d * 60000
    diseaseStartTimers[player] = setTimer(startDisease, delayMs, 1, player)
    local nextTime = getRealTime().timestamp + d * 60
    setElementData(player, 'vaccine.sick', false)
    setElementData(player, 'vaccine.nextDisease', nextTime)
    savePlayerData(player, nil, false, nextTime)
end

local function giveProtection(player, minutes)
    if diseaseDamageTimers[player] and isTimer(diseaseDamageTimers[player]) then
        killTimer(diseaseDamageTimers[player])
        diseaseDamageTimers[player] = nil
    end
    if diseaseStartTimers[player] and isTimer(diseaseStartTimers[player]) then
        killTimer(diseaseStartTimers[player])
        diseaseStartTimers[player] = nil
    end
    if protectionTimers[player] and isTimer(protectionTimers[player]) then
        killTimer(protectionTimers[player])
    end
    setElementData(player, 'vaccine.sick', false)
    triggerClientEvent(player, 'vaccine:effects', resourceRoot, false)
    local expires = getRealTime().timestamp + minutes * 60
    setElementData(player, 'vaccine.protected', true)
    setElementData(player, 'vaccine.protectedUntil', expires)
    savePlayerData(player, expires, false, 0)
    protectionTimers[player] = setTimer(function()
        if isElement(player) then
            setElementData(player, 'vaccine.protected', false)
            setElementData(player, 'vaccine.protectedUntil', 0)
            savePlayerData(player, 0, false, 0)
            scheduleDisease(player)
        end
    end, minutes * 60000, 1)
end

local function loadPlayerData(player)
    local serial = getPlayerSerial(player)
    dbQuery(function(qh)
        local result = dbPoll(qh, 0)
        local now = getRealTime().timestamp
        if result and result[1] then
            local data = result[1]
            if data.vaccine_expires and data.vaccine_expires > now then
                local remaining = (data.vaccine_expires - now) / 60
                giveProtection(player, remaining)
            elseif data.sick == 1 then
                startDisease(player)
            elseif data.disease_time and data.disease_time > now then
                local delay = (data.disease_time - now) / 60
                scheduleDisease(player, delay)
            else
                scheduleDisease(player)
            end
        else
            scheduleDisease(player)
        end
    end, db, 'SELECT vaccine_expires, sick, disease_time FROM vaccines WHERE serial=?', serial)
end

addEventHandler('onResourceStart', resourceRoot, function()
    for _,p in ipairs(getElementsByType('player')) do
        loadPlayerData(p)
    end
end)

addEventHandler('onPlayerJoin', root, function()
    loadPlayerData(source)
end)

addEventHandler('onPlayerQuit', root, function()
    savePlayerData(source)
end)

addCommandHandler(config.vaccination.command, function(player, cmd, id)
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
    local c = config.shop.markerColor
    local marker = createMarker(pos.x, pos.y, pos.z - 1, 'cylinder', 1.5, c.r, c.g, c.b, c.a)
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

-- Console commands
addCommandHandler(config.commands.reset, function(player, cmd, id)
    if player and getElementType(player) == 'player' then
        local account = getPlayerAccount(player)
        if not account or isGuestAccount(account) or not isObjectInACLGroup('user.'..getAccountName(account), aclGetGroup(config.commands.acl)) then
            exports['[HS]Notify_System']:notify(player, 'Você não tem permissão.', 'error')
            return
        end
    end
    local target = getPlayerByID(id)
    if not target then
        outputConsole('Jogador não encontrado.')
        return
    end
    setElementData(target, 'vaccine.protected', false)
    setElementData(target, 'vaccine.protectedUntil', 0)
    savePlayerData(target, 0, false, 0)
    exports['[HS]Notify_System']:notify(target, 'Sua proteção contra doenças foi removida.', 'error')
    scheduleDisease(target)
    outputConsole('Vacina de '..getPlayerName(target)..' resetada.')
end)

addCommandHandler(config.commands.set, function(player, cmd, id, hours)
    if player and getElementType(player) == 'player' then
        local account = getPlayerAccount(player)
        if not account or isGuestAccount(account) or not isObjectInACLGroup('user.'..getAccountName(account), aclGetGroup(config.commands.acl)) then
            exports['[HS]Notify_System']:notify(player, 'Você não tem permissão.', 'error')
            return
        end
    end
    local target = getPlayerByID(id)
    local hrs = tonumber(hours)
    if not target or not hrs then
        outputConsole('Uso: '..cmd..' <id> <horas>')
        return
    end
    giveProtection(target, hrs * 60)
    exports['[HS]Notify_System']:notify(target, 'Você recebeu proteção contra doenças por '..hrs..'h.', 'success')
    outputConsole('Vacina aplicada a '..getPlayerName(target)..' por '..hrs..' horas.')
end)

