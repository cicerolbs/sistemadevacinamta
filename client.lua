local config = CONFIG
local showPanel = false
local sx, sy = guiGetScreenSize()
local panelX, panelY = config.shop.panel.x * sx, config.shop.panel.y * sy
local panelW, panelH = 400, 250
local font = 'default-bold'

local function drawPanel()
    dxDrawRectangle(panelX, panelY, panelW, panelH, tocolor(0,0,0,200))
    dxDrawText('Hospital - Vacinas', panelX, panelY+20, panelX+panelW, panelY+60, tocolor(255,255,255), 1.2, font, 'center', 'top')
    dxDrawText('Comprar proteção por '..config.shop.protectionHours..'h', panelX, panelY+80, panelX+panelW, panelY+120, tocolor(255,255,255), 1, font, 'center', 'top')
    dxDrawRectangle(panelX+50, panelY+160, panelW-100, 50, tocolor(0,150,0))
    dxDrawText('Comprar - $'..config.shop.price, panelX+50, panelY+160, panelX+panelW-50, panelY+210, tocolor(255,255,255), 1.2, font, 'center', 'center')
end

local function clickPanel(btn, state)
    if btn == 'left' and state == 'up' and showPanel then
        local x, y = getCursorPosition()
        x, y = x * sx, y * sy
        if x >= panelX+50 and x <= panelX+panelW-50 and y >= panelY+160 and y <= panelY+210 then
            triggerServerEvent('vaccine:buy', localPlayer)
            showPanel = false
            showCursor(false)
            removeEventHandler('onClientRender', root, drawPanel)
            removeEventHandler('onClientClick', root, clickPanel)
        end
    end
end

addEvent('vaccine:showShop', true)
addEventHandler('vaccine:showShop', root, function()
    showPanel = true
    showCursor(true)
    addEventHandler('onClientRender', root, drawPanel)
    addEventHandler('onClientClick', root, clickPanel)
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

