local overlay
local keypad
local keypadEvent
local keypadMousePos = { x = 0.5, y = 0.5 }
local keypadTicks = 0

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

  removeEvent(keypadEvent)

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
  keypadEvent = nil
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

function isActive()
  return g_mouse.isPressed(MouseLeftButton)
end

function onKeypadTouchPress(widget, pos, button)
  if button ~= MouseLeftButton then return false end

  keypadTicks = 0
  keypadMousePos = {
    x = (pos.x - widget:getPosition().x) / widget:getWidth(),
    y = (pos.y - widget:getPosition().y) / widget:getHeight()
  }
  executeWalk()
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

  keypadMousePos = {
    x = (pos.x - widget:getPosition().x) / widget:getWidth(),
    y = (pos.y - widget:getPosition().y) / widget:getHeight()
  }
  executeWalk()
  removeEvent(keypadEvent)

  keypad.pointer:setMarginTop(0)
  keypad.pointer:setMarginLeft(0)
  return true
end

function executeWalk()
  removeEvent(keypadEvent)
  keypadEvent = nil

  if not modules.game_walking or not g_mouse.isPressed(MouseLeftButton) then
    keypad.pointer:setMarginTop(0)
    keypad.pointer:setMarginLeft(0)
    return
  end

  keypadEvent = scheduleEvent(executeWalk, 20)
  keypadMousePos.x = math.min(1, math.max(0, keypadMousePos.x))
  keypadMousePos.y = math.min(1, math.max(0, keypadMousePos.y))

  local angle = math.atan2(keypadMousePos.x - 0.5, keypadMousePos.y - 0.5)
  local maxTop = math.abs(math.cos(angle)) * 75
  local marginTop = math.max(-maxTop, math.min(maxTop, (keypadMousePos.y - 0.5) * 150))
  local maxLeft = math.abs(math.sin(angle)) * 75
  local marginLeft = math.max(-maxLeft, math.min(maxLeft, (keypadMousePos.x - 0.5) * 150))
  keypad.pointer:setMarginTop(marginTop)
  keypad.pointer:setMarginLeft(marginLeft)

  local dir
  if keypadMousePos.y < 0.3 and keypadMousePos.x < 0.3 then
    dir = Directions.NorthWest
  elseif keypadMousePos.y < 0.3 and keypadMousePos.x > 0.7 then
    dir = Directions.NorthEast
  elseif keypadMousePos.y > 0.7 and keypadMousePos.x < 0.3 then
    dir = Directions.SouthWest
  elseif keypadMousePos.y > 0.7 and keypadMousePos.x > 0.7 then
    dir = Directions.SouthEast
  end

  if not dir and (math.abs(keypadMousePos.y - 0.5) > 0.1 or math.abs(keypadMousePos.x - 0.5) > 0.1) then
    if math.abs(keypadMousePos.y - 0.5) > math.abs(keypadMousePos.x - 0.5) then
      if keypadMousePos.y < 0.5 then
        dir = Directions.North
      else
        dir = Directions.South
      end
    else
      if keypadMousePos.x < 0.5 then
        dir = Directions.West
      else
        dir = Directions.East
      end
    end
  end

  if dir then
    modules.game_walking.walk(dir, keypadTicks)
    if keypadTicks == 0 then
      keypadTicks = 100
    end
  end
end

function getPanel()
  return keypad
end
