-- COLE O SCRIPT INTEIRO DE UMA VEZ
-- Gerado automaticamente a partir de script-base.lua + constructions/
-- Não edite constructions/ diretamente: envie construções pelo site.

local AUTH_COMMAND = "login"
local AUTH_PASSWORD = "pice"

local KEY_C = 67
local KEY_SPACE = 32
local KEY_ESC = 27
local KEY_I = 73
local KEY_O = 79
local KEY_M = 77   -- alternar colisão com rato

local SCALE_STEP = 0.10
local MIN_SCALE = 0.20
local MAX_SCALE = 3.00

local PREVIEW_ALPHA = 0.45
local MAP_BACKGROUND = 0x0C0C0C

local authorizedPlayers = {}
local selectedConstruction = {}
local previews = {}
local menuVisible = {}

local nextObjectId = 1000
local nextJointId = 100000

local UI_MAIN = 7000
local UI_STATUS = 7001
local UI_TOGGLE = 7003

local miceCollisionEnabled = true

local function newObjectId()
    nextObjectId = nextObjectId + 1
    return nextObjectId
end

local function newJointId()
    nextJointId = nextJointId + 1
    return nextJointId
end

local function color(hex)
    return tonumber(hex, 16)
end

local function round(n)
    return math.floor(n + 0.5)
end

local function removeObjectSafe(id)
    if id then pcall(tfm.exec.removePhysicObject, id) end
end

local function removeJointSafe(id)
    if id then pcall(tfm.exec.removeJoint, id) end
end

local function blendColor(c1, c2, amount)
    local r1 = math.floor(c1 / 65536) % 256
    local g1 = math.floor(c1 / 256) % 256
    local b1 = c1 % 256

    local r2 = math.floor(c2 / 65536) % 256
    local g2 = math.floor(c2 / 256) % 256
    local b2 = c2 % 256

    local r = math.floor(r1 * amount + r2 * (1 - amount))
    local g = math.floor(g1 * amount + g2 * (1 - amount))
    local b = math.floor(b1 * amount + b2 * (1 - amount))

    return r * 65536 + g * 256 + b
end

-- ============================================================
-- CONSTRUÇÕES (preenchido automaticamente pelo site)
-- ============================================================
local constructions = {}
-- CONSTRUCTIONS_HERE --

for _, construction in pairs(constructions) do
    for _, obj in ipairs(construction.objects) do
        obj.rx = obj.x - construction.anchor.x
        obj.ry = obj.y - construction.anchor.y
    end
    for _, joint in ipairs(construction.joints) do
        joint.r1x = joint.x1 - construction.anchor.x
        joint.r1y = joint.y1 - construction.anchor.y
        joint.r2x = joint.x2 - construction.anchor.x
        joint.r2y = joint.y2 - construction.anchor.y
    end
end

-- ============================================================
-- UI
-- ============================================================
local function updateUI(playerName)
    if not authorizedPlayers[playerName] then return end

    ui.addTextArea(UI_TOGGLE, "<p align='center'><a href='event:toggle_menu'><b>[ 🛠️ Menu ]</b></a></p>", playerName, 10, 35, 90, 25, 0x151515, 0x555555, 0.9, true)

    if menuVisible[playerName] == false then
        ui.removeTextArea(UI_MAIN, playerName)
        return
    end

    if #constructions == 0 then
        ui.addTextArea(UI_MAIN, "<p align='center'><font size='13'>Nenhuma construção carregada ainda.</font></p>", playerName, 10, 70, 240, 60, 0x151515, 0x555555, 0.88, true)
        return
    end

    local selected = selectedConstruction[playerName] or 1
    local construction = constructions[selected]
    if not construction then return end

    local text = "<p align='center'>" ..
                 "<font size='15'><b>CONSTRUCOES</b></font>  " ..
                 "<a href='event:close_menu'><font color='#FF5555' size='12'><b>[ X Fechar ]</b></font></a><br><br>" ..
                 "<font size='13'>" .. tostring(selected) .. " / " .. tostring(#constructions) .. "</font><br>" ..
                 "<font size='14'><b>" .. construction.name .. "</b></font><br><br>"

    local colStatus = miceCollisionEnabled and "ON" or "OFF"
    text = text .. "<font size='11'>Colisão: <b>" .. colStatus .. "</b>  (M para alternar)</font><br><br>"

    if previews[playerName] then
        text = text ..
            "<font color='#55FF55'><b>PREVIEW</b></font><br><br>" ..
            "<font size='11'>Escala: " .. string.format("%.1fx", previews[playerName].scale) .. "</font><br><br>" ..
            "<a href='event:construction_minus'><font size='20'><b>[ - ]</b></font></a>" ..
            "    " ..
            "<a href='event:construction_plus'><font size='20'><b>[ + ]</b></font></a><br><br>" ..
            "<font size='10'>I / O = escala<br>C = trocar construcao<br>Espaco = confirmar<br>Esc = cancelar</font>"
    else
        text = text ..
            "<font size='11'>C = proxima construcao<br>Espaco = iniciar preview</font>"
    end

    ui.addTextArea(UI_MAIN, text, playerName, 10, 70, 240, 340, 0x151515, 0x555555, 0.88, true)
end

-- ============================================================
-- CRIAÇÃO DE OBJETOS/JOINTS
-- ============================================================
local function createObject(obj, x, y, scale, preview)
    local id = newObjectId()
    local objectColor = preview and blendColor(obj.color, MAP_BACKGROUND, PREVIEW_ALPHA) or obj.color

    tfm.exec.addPhysicObject(id, round(x), round(y), {
        type = obj.type,
        width = math.max(1, round(obj.w * scale)),
        height = math.max(1, round(obj.h * scale)),
        color = objectColor,
        miceCollision = preview and false or (obj.miceCollision ~= false and miceCollisionEnabled),
        groundCollision = preview and false or (obj.groundCollision ~= false),
        foreground = obj.foreground == true,
        friction = obj.friction or 0.3,
        restitution = obj.restitution or 0.2,
        angle = obj.angle or 0,
        dynamic = (obj.dynamic == true) and not preview,
        fixedRotation = obj.fixedRotation == true
    })

    return id
end

local function createJointLine(anchorId, joint, anchorX, anchorY, scale, preview)
    local id = newJointId()
    local x1 = anchorX + joint.r1x * scale
    local y1 = anchorY + joint.r1y * scale
    local x2 = anchorX + joint.r2x * scale
    local y2 = anchorY + joint.r2y * scale
    local alpha = preview and ((joint.alpha or 0.9) * PREVIEW_ALPHA) or (joint.alpha or 0.9)

    tfm.exec.addJoint(id, anchorId, anchorId, {
        type = 0,
        point1 = round(x1) .. "," .. round(y1),
        point2 = round(x2) .. "," .. round(y2),
        frequency = 0, damping = 0,
        line = math.max(1, round(joint.line * scale)),
        color = joint.color, alpha = alpha,
        foreground = joint.foreground == true
    })

    return id
end

-- ============================================================
-- PREVIEW E CONFIRMAÇÃO
-- ============================================================
local function clearPreview(playerName)
    local preview = previews[playerName]
    if not preview then return end

    if preview.joints then
        for _, jointId in ipairs(preview.joints) do removeJointSafe(jointId) end
    end
    if preview.objects then
        for _, objectId in ipairs(preview.objects) do removeObjectSafe(objectId) end
    end

    preview.joints = {}
    preview.objects = {}
end

local function createPreview(playerName, x, y)
    local preview = previews[playerName]
    if not preview then return end

    local construction = constructions[preview.construction]
    if not construction then return end

    local scale = preview.scale
    clearPreview(playerName)

    preview.x = x
    preview.y = y

    for _, obj in ipairs(construction.objects) do
        local objectId = createObject(obj, x + obj.rx * scale, y + obj.ry * scale, scale, true)
        table.insert(preview.objects, objectId)
    end

    local anchorId = newObjectId()
    tfm.exec.addPhysicObject(anchorId, round(x), round(y), {
        type = 12, width = 1, height = 1, color = MAP_BACKGROUND,
        miceCollision = false, groundCollision = false, foreground = false
    })
    table.insert(preview.objects, anchorId)

    for _, joint in ipairs(construction.joints) do
        local jointId = createJointLine(anchorId, joint, x, y, scale, true)
        table.insert(preview.joints, jointId)
    end
end

local function startPreview(playerName)
    if not authorizedPlayers[playerName] then return end
    if previews[playerName] then return end
    if #constructions == 0 then return end

    local player = tfm.get.room.playerList[playerName]
    if not player then return end

    previews[playerName] = {
        construction = selectedConstruction[playerName] or 1,
        x = player.x,
        y = player.y,
        scale = 1,
        objects = {},
        joints = {}
    }

    createPreview(playerName, player.x, player.y)
    updateUI(playerName)
end

local function confirmConstruction(playerName)
    local preview = previews[playerName]
    if not preview then return end

    local construction = constructions[preview.construction]
    if not construction then return end

    for _, obj in ipairs(construction.objects) do
        createObject(obj, preview.x + obj.rx * preview.scale, preview.y + obj.ry * preview.scale, preview.scale, false)
    end

    local anchorId = newObjectId()
    tfm.exec.addPhysicObject(anchorId, round(preview.x), round(preview.y), {
        type = 12, width = 1, height = 1, color = MAP_BACKGROUND,
        miceCollision = false, groundCollision = false, foreground = false
    })

    for _, joint in ipairs(construction.joints) do
        createJointLine(anchorId, joint, preview.x, preview.y, preview.scale, false)
    end

    clearPreview(playerName)
    previews[playerName] = nil

    updateUI(playerName)
end

local function cancelPreview(playerName)
    if not previews[playerName] then return end
    clearPreview(playerName)
    previews[playerName] = nil
    updateUI(playerName)
end

local function changeScale(playerName, amount)
    local preview = previews[playerName]
    if not preview then return end

    local newScale = preview.scale + amount
    if newScale < MIN_SCALE then newScale = MIN_SCALE end
    if newScale > MAX_SCALE then newScale = MAX_SCALE end
    newScale = math.floor(newScale * 100 + 0.5) / 100

    preview.scale = newScale
    createPreview(playerName, preview.x, preview.y)
    updateUI(playerName)
end

local function nextConstruction(playerName)
    if not authorizedPlayers[playerName] then return end
    if #constructions == 0 then return end

    local current = selectedConstruction[playerName] or 1
    current = current + 1
    if current > #constructions then current = 1 end

    selectedConstruction[playerName] = current

    local preview = previews[playerName]
    if preview then
        preview.construction = current
        createPreview(playerName, preview.x, preview.y)
    end

    updateUI(playerName)
end

-- ============================================================
-- EVENTOS
-- ============================================================
function eventTextAreaCallback(id, playerName, callback)
    if not authorizedPlayers[playerName] then return end

    if callback == "toggle_menu" then
        menuVisible[playerName] = not menuVisible[playerName]
        updateUI(playerName)
        return
    elseif callback == "close_menu" then
        menuVisible[playerName] = false
        updateUI(playerName)
        return
    end

    if id == UI_MAIN then
        if callback == "construction_plus" then
            changeScale(playerName, SCALE_STEP)
        elseif callback == "construction_minus" then
            changeScale(playerName, -SCALE_STEP)
        end
    end
end

function eventMouse(playerName, x, y)
    if not authorizedPlayers[playerName] then return end
    if previews[playerName] then
        createPreview(playerName, x, y)
        updateUI(playerName)
    end
end

function eventKeyboard(playerName, keyCode, down, xPlayerPosition, yPlayerPosition)
    if not authorizedPlayers[playerName] then return end
    if not down then return end

    if keyCode == KEY_M then
        miceCollisionEnabled = not miceCollisionEnabled
        local status = miceCollisionEnabled and "ON" or "OFF"
        ui.addTextArea(UI_STATUS, "<p align='center'><font color='#55FF55'>Colisão com rato: " .. status .. "</font></p>", playerName, 300, 30, 450, 40, 0x000000, 0x555555, 0.7, true)
        updateUI(playerName)
        return
    end

    if keyCode == KEY_C then
        nextConstruction(playerName)
        return
    end

    if keyCode == KEY_SPACE then
        if previews[playerName] then
            confirmConstruction(playerName)
        else
            startPreview(playerName)
        end
        return
    end

    if keyCode == KEY_ESC then
        cancelPreview(playerName)
        return
    end

    if keyCode == KEY_I then
        changeScale(playerName, SCALE_STEP)
        return
    end

    if keyCode == KEY_O then
        changeScale(playerName, -SCALE_STEP)
        return
    end
end

function eventChatCommand(playerName, command)
    command = string.lower(tostring(command or ""))

    if command == AUTH_COMMAND .. " " .. AUTH_PASSWORD then
        authorizedPlayers[playerName] = true
        selectedConstruction[playerName] = selectedConstruction[playerName] or 1
        menuVisible[playerName] = true

        system.bindMouse(playerName, true)

        tfm.exec.bindKeyboard(playerName, KEY_C, true, true)
        tfm.exec.bindKeyboard(playerName, KEY_SPACE, true, true)
        tfm.exec.bindKeyboard(playerName, KEY_ESC, true, true)
        tfm.exec.bindKeyboard(playerName, KEY_I, true, true)
        tfm.exec.bindKeyboard(playerName, KEY_O, true, true)
        tfm.exec.bindKeyboard(playerName, KEY_M, true, true)

        updateUI(playerName)
        return
    end

    if command == "np random" or command == "!np random" then
        if authorizedPlayers[playerName] then
            tfm.exec.newGame(nil)
            for pn in pairs(authorizedPlayers) do
                if previews[pn] then
                    clearPreview(pn)
                    previews[pn] = nil
                end
                updateUI(pn)
            end
            ui.addTextArea(UI_STATUS, "<p align='center'><font color='#55FF55'>Mapa aleatório carregado!</font></p>", playerName, 300, 30, 450, 40, 0x000000, 0x555555, 0.7, true)
        end
        return
    end
end

function eventNewPlayer(playerName)
    selectedConstruction[playerName] = 1
    menuVisible[playerName] = true
    system.bindMouse(playerName, true)
end

function eventPlayerLeft(playerName)
    clearPreview(playerName)
    previews[playerName] = nil
    authorizedPlayers[playerName] = nil
    selectedConstruction[playerName] = nil
    menuVisible[playerName] = nil
    ui.removeTextArea(UI_STATUS, playerName)
    ui.removeTextArea(UI_TOGGLE, playerName)
end

system.disableChatCommandDisplay(AUTH_COMMAND, true)

tfm.exec.newGame('<C><P L="4000" H="2000" MEDATA=";;;;-0;0:::1-"/><Z><S><S T="12" X="830" Y="387" L="1656" H="26" P="0,0,0.3,0.2,0,0,0,0" o="0C0C0C"/></S><D><DS X="19" Y="359"/></D><O/><L/></Z></C>')

for playerName in pairs(tfm.get.room.playerList) do
    system.bindMouse(playerName, true)
end
