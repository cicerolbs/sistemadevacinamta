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
    dxDrawRectangle(buyBtn.x, buyBtn.y, buyBtn.w, buyBtn.h, tocolor(colors.buy.r, colors.buy.g, colors.buy.b))
    dxDrawText('Comprar - $'..config.shop.price, buyBtn.x, buyBtn.y, buyBtn.x+buyBtn.w, buyBtn.y+buyBtn.h, tocolor(255,255,255), 1.2, font, 'center', 'center')
    dxDrawRectangle(exitBtn.x, exitBtn.y, exitBtn.w, exitBtn.h, tocolor(colors.exit.r, colors.exit.g, colors.exit.b))
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

addEvent('vaccine:effects', true)
addEventHandler('vaccine:effects', root, function(state)
    if state then
        setGameSpeed(config.disease.slowdown)
        setCameraShakeLevel(config.disease.cameraShake)
    else
        setGameSpeed(1)
        setCameraShakeLevel(0)
    end
end)

