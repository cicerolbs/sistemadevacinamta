local config = CONFIG
local showPanel = false
local sx, sy = guiGetScreenSize()
local panelX, panelY = config.shop.panel.x * sx, config.shop.panel.y * sy
local panelW, panelH = 400, 260
local font = 'default-bold'
local colors = config.shop.buttonColors
local buyBtn = {x = panelX + 50, y = panelY + 160, w = panelW - 100, h = 40}
local exitBtn = {x = panelX + 50, y = panelY + 210, w = panelW - 100, h = 40}

local drawPanel, clickPanel, keyPanel

local function isCursorOver(btn)
    local cx, cy = getCursorPosition()
    if not cx or not cy then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= btn.x and cx <= btn.x + btn.w and cy >= btn.y and cy <= btn.y + btn.h
end

local function closePanel()
    showPanel = false
    showCursor(false)
    removeEventHandler('onClientRender', root, drawPanel)
    removeEventHandler('onClientClick', root, clickPanel)
    removeEventHandler('onClientKey', root, keyPanel)
end

function drawPanel()
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(0,0,0,200))
    dxDrawText('Hospital - Vacinas', panelX, panelY+20, panelX+panelW, panelY+60, tocolor(255,255,255), 1.2, font, 'center', 'top')
    dxDrawText('Comprar proteção por '..config.shop.protectionHours..'h', panelX, panelY+80, panelX+panelW, panelY+120, tocolor(255,255,255), 1, font, 'center', 'top')
    local bCol = colors.buy
    if isCursorOver(buyBtn) then
        bCol = {r = math.min(bCol.r + 40, 255), g = math.min(bCol.g + 40, 255), b = math.min(bCol.b + 40, 255)}
    end
    dxDrawRectangle(buyBtn.x, buyBtn.y, buyBtn.w, buyBtn.h, tocolor(bCol.r, bCol.g, bCol.b))
    dxDrawText('Comprar - $'..config.shop.price, buyBtn.x, buyBtn.y, buyBtn.x+buyBtn.w, buyBtn.y+buyBtn.h, tocolor(255,255,255), 1.2, font, 'center', 'center')
    local eCol = colors.exit
    if isCursorOver(exitBtn) then
        eCol = {r = math.min(eCol.r + 40, 255), g = math.min(eCol.g + 40, 255), b = math.min(eCol.b + 40, 255)}
    end
    dxDrawRectangle(exitBtn.x, exitBtn.y, exitBtn.w, exitBtn.h, tocolor(eCol.r, eCol.g, eCol.b))
    dxDrawText('Sair', exitBtn.x, exitBtn.y, exitBtn.x+exitBtn.w, exitBtn.y+exitBtn.h, tocolor(255,255,255), 1.2, font, 'center', 'center')
end

function clickPanel(btn, state)
    if btn == 'left' and state == 'up' and showPanel then
        local x, y = getCursorPosition()
        x, y = x * sx, y * sy
        if x >= buyBtn.x and x <= buyBtn.x+buyBtn.w and y >= buyBtn.y and y <= buyBtn.y+buyBtn.h then
            triggerServerEvent('vaccine:buy', localPlayer)
            closePanel()
        elseif x >= exitBtn.x and x <= exitBtn.x+exitBtn.w and y >= exitBtn.y and y <= exitBtn.y+exitBtn.h then
            closePanel()
        end
    end
end

function keyPanel(btn, press)
    if btn == 'backspace' and press and showPanel then
        closePanel()
    end
end

addEvent('vaccine:showShop', true)
addEventHandler('vaccine:showShop', root, function()
    showPanel = true
    showCursor(true)
    addEventHandler('onClientRender', root, drawPanel)
    addEventHandler('onClientClick', root, clickPanel)
    addEventHandler('onClientKey', root, keyPanel)
end)

local effectTimer

addEvent('vaccine:effects', true)
addEventHandler('vaccine:effects', root, function(state)
    if state then
        if isTimer(effectTimer) then killTimer(effectTimer) end
        effectTimer = setTimer(function()
            if not isElement(localPlayer) then return end
            local hp = getElementHealth(localPlayer)
            if hp < 40 then
                setGameSpeed(config.disease.slowdown)
                setCameraShakeLevel(config.disease.cameraShake)
            else
                setGameSpeed(1)
                setCameraShakeLevel(0)
            end
        end, 500, 0)
    else
        if isTimer(effectTimer) then
            killTimer(effectTimer)
            effectTimer = nil
        end
        setGameSpeed(1)
        setCameraShakeLevel(0)
    end
end)

