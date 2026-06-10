local overlay
local keypad
local keypadUpdateEvent
local keypadMousePos = { x = 0.5, y = 0.5 }
local firstStep = true
local moveListener
local releaseListener

function init()
  if not g_platform.isMobile() then return end

  overlay = g_ui.displayUI('joystick')
  keypad = overlay.keypad

  connect(keypad, {
    onMousePress = onKeypadTouchPress,
    onMouseRelease = onKeypadTouchRelease,
    onMouseMove = onKeypadTouchMove
  })

  connect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })
end

function terminate()
  if not g_platform.isMobile() then return end

  removeEvent(keypadUpdateEvent)

  disconnect(keypad, {
    onMousePress = onKeypadTouchPress,
    onMouseRelease = onKeypadTouchRelease,
    onMouseMove = onKeypadTouchMove
  })

  disconnect(g_game, {
    onGameStart = onGameStart,
    onGameEnd = onGameEnd
  })

  overlay:destroy()
  overlay = nil
  keypadUpdateEvent = nil
end

function hide()
  overlay:hide()
end

function show()
  overlay:show()
end

function onGameStart()
  keypad:raise()
  keypad:show()
end

function onGameEnd()
  keypad:hide()
end

function addOnJoystickMoveListener(callback)
  moveListener = callback
end

function addOnJoystickReleaseListener(callback)
  releaseListener = callback
end

function getDirection()
  return resolveDirection(keypadMousePos.x, keypadMousePos.y)
end

function isActive()
  return g_mouse.isPressed(MouseLeftButton)
end

function onKeypadTouchPress(widget, pos, button)
  if button ~= MouseLeftButton then return false end

  keypadMousePos = {
    x = (pos.x - widget:getPosition().x) / widget:getWidth(),
    y = (pos.y - widget:getPosition().y) / widget:getHeight()
  }

  firstStep = true
  tryWalk()

  return true
end

function onKeypadTouchMove(widget, pos, offset)
  keypadMousePos = {
    x = (pos.x - widget:getPosition().x) / widget:getWidth(),
    y = (pos.y - widget:getPosition().y) / widget:getHeight()
  }

  return true
end

function onKeypadTouchRelease(widget, pos, button)
  if button ~= MouseLeftButton then return false end

  removeEvent(keypadUpdateEvent)
  keypadUpdateEvent = nil
  firstStep = true

  if releaseListener then
    releaseListener()
  end

  keypad.pointer:setMarginTop(0)
  keypad.pointer:setMarginLeft(0)

  return true
end

function resolveDirection(x, y)
  x = math.min(1, math.max(0, x))
  y = math.min(1, math.max(0, y))

  local dir

  if y < 0.3 and x < 0.3 then
    dir = Directions.NorthWest
  elseif y < 0.3 and x > 0.7 then
    dir = Directions.NorthEast
  elseif y > 0.7 and x < 0.3 then
    dir = Directions.SouthWest
  elseif y > 0.7 and x > 0.7 then
    dir = Directions.SouthEast
  end

  if not dir and (math.abs(y - 0.5) > 0.2 or math.abs(x - 0.5) > 0.2) then
    if math.abs(y - 0.5) > math.abs(x - 0.5) then
      if y < 0.5 then
        dir = Directions.North
      else
        dir = Directions.South
      end
    else
      if x < 0.5 then
        dir = Directions.West
      else
        dir = Directions.East
      end
    end
  end

  return dir
end

function updatePointer()
  local x = math.min(1, math.max(0, keypadMousePos.x))
  local y = math.min(1, math.max(0, keypadMousePos.y))
  local angle = math.atan2(x - 0.5, y - 0.5)
  local maxTop = math.abs(math.cos(angle)) * 75
  local marginTop = math.max(-maxTop, math.min(maxTop, (y - 0.5) * 150))
  local maxLeft = math.abs(math.sin(angle)) * 75
  local marginLeft = math.max(-maxLeft, math.min(maxLeft, (x - 0.5) * 150))
  keypad.pointer:setMarginTop(marginTop)
  keypad.pointer:setMarginLeft(marginLeft)
end

local function refreshPointer()
  removeEvent(keypadUpdateEvent)
  if not g_mouse.isPressed(MouseLeftButton) then
    keypad.pointer:setMarginTop(0)
    keypad.pointer:setMarginLeft(0)
    return
  end
  updatePointer()
  keypadUpdateEvent = scheduleEvent(refreshPointer, 20)
end

function tryWalk()
  if not g_mouse.isPressed(MouseLeftButton) then
    return
  end

  updatePointer()

  local dir = resolveDirection(keypadMousePos.x, keypadMousePos.y)
  if dir and moveListener and firstStep then
    moveListener(dir, true)
    firstStep = false
  end

  removeEvent(keypadUpdateEvent)
  keypadUpdateEvent = scheduleEvent(refreshPointer, 20)
end

function getPanel()
  return keypad
end
