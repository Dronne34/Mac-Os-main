-- Auto-tiling 60/40 + focus highlight
local wf = hs.window.filter
local drawing = hs.drawing
local spaces = hs.spaces

local highlight = {
  rect = nil,
  winId = nil,
  padding = 0,
  corner = 10,
  color = {red=0.2, green=0.6, blue=1.0, alpha=0.9},
  stroke = 2,
  shadow = false,
}
local highlightEnabled = true

local function hideHighlight()
  if highlight.rect then
    highlight.rect:delete()
    highlight.rect = nil
  end
  highlight.winId = nil
end

local function showHighlight(win)
  if not highlightEnabled then
    return hideHighlight()
  end
  if not win then return hideHighlight() end
  if not win:isStandard() or not win:isVisible() or win:isMinimized() then
    return hideHighlight()
  end
  local f = win:frame()
  local rect = {
    x = f.x - highlight.padding,
    y = f.y - highlight.padding,
    w = f.w + highlight.padding * 2,
    h = f.h + highlight.padding * 2
  }

  hideHighlight()
  highlight.rect = drawing.rectangle(rect)
  highlight.rect:setStrokeColor(highlight.color)
  highlight.rect:setFill(false)
  highlight.rect:setStrokeWidth(highlight.stroke)
  highlight.rect:setRoundedRectRadii(highlight.corner, highlight.corner)
  highlight.rect:setLevel(drawing.windowLevels.status)
  highlight.rect:setAlpha(1.0)
  highlight.rect:show()
  highlight.winId = win:id()
end

local function hasStandardVisibleWindows()
  local wins = hs.window.visibleWindows()
  for _, w in ipairs(wins) do
    if w:isStandard() and w:isVisible() and not w:isMinimized() then
      return true
    end
  end
  return false
end

local function spaceHasStandardWindows(spaceId)
  local wins = hs.window.allWindows()
  for _, w in ipairs(wins) do
    if w:isStandard() and not w:isMinimized() then
      local winSpaces = hs.spaces.windowSpaces(w)
      if winSpaces then
        for _, s in ipairs(winSpaces) do
          if s == spaceId then
            return true
          end
        end
      end
    end
  end
  return false
end

local function currentSpaceHasVisibleStandardWindows()
  local current = hs.spaces.focusedSpace()
  if not current then return false end
  local wins = hs.window.visibleWindows()
  for _, w in ipairs(wins) do
    if w:isStandard() and w:isVisible() and not w:isMinimized() then
      local winSpaces = hs.spaces.windowSpaces(w)
      if winSpaces then
        for _, s in ipairs(winSpaces) do
          if s == current then
            return true
          end
        end
      end
    end
  end
  return false
end

local function currentSpaceHasFullScreenWindow()
  local current = hs.spaces.focusedSpace()
  if not current then return false end
  local wins = hs.window.allWindows()
  for _, w in ipairs(wins) do
    if w:isFullScreen() then
      local winSpaces = hs.spaces.windowSpaces(w)
      if winSpaces then
        for _, s in ipairs(winSpaces) do
          if s == current then
            return true
          end
        end
      end
    end
  end
  return false
end
local debug = false
local gapH = 15
local gapV = 15
local outer = 10
local splitOffset = 0
local splitStep = 20
local refreshHighlight
local tileTwoWindows
local floatingApps = {
  ["System Settings"] = true,
  ["Activity Monitor"] = true,
  ["Finder"] = true,
}

local function isFloating(win)
  local app = win and win:application()
  local name = app and app:name()
  return name and floatingApps[name] or false
end

local function centerFloating(win)
  if not win or not isFloating(win) then return end
  win:centerOnScreen()
end

local function space2ForMainScreen()
  local main = hs.screen.mainScreen()
  if not main then return nil end
  local uuid = main:getUUID()
  local map = spaces.allSpaces()
  local list = map and map[uuid] or nil
  if not list or #list < 2 then return nil end
  return list[2]
end

local function space3ForMainScreen()
  local main = hs.screen.mainScreen()
  if not main then return nil end
  local uuid = main:getUUID()
  local map = spaces.allSpaces()
  local list = map and map[uuid] or nil
  if not list or #list < 3 then return nil end
  return list[3]
end

local function launchOnCurrentSpace(bundleId)
  local app = hs.application.get(bundleId)
  if app then
    hs.task.new("/usr/bin/open", nil, {"-b", bundleId, "-n"}):start()
  else
    hs.application.launchOrFocusByBundleID(bundleId)
  end
end


hs.hotkey.bind({"ctrl", "alt"}, "f", function()
  hs.application.launchOrFocusByBundleID("com.apple.finder")
end)

hs.hotkey.bind({"ctrl", "alt"}, "v", function()
  hs.task.new("/usr/bin/open", nil, {"-n", "/Applications/Visual Studio Code.app"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "y", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/usr/bin/open", nil, {"-na", "alacritty", "--args", "-e", "yazi", home .. "/"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "s", function()
  hs.application.launchOrFocusByBundleID("com.apple.Safari")
end)

hs.hotkey.bind({"ctrl"}, "return", function()
  hs.task.new("/usr/bin/open", nil, {"-n", "/Applications/Alacritty.app"}):start()
end)

hs.hotkey.bind({"alt"}, "return", function()
  hs.task.new("/usr/bin/open", nil, {"-na", "kitty.app"}):start()
end)

local function snapFocusedHalf(side)
  local win = hs.window.focusedWindow()
  if not win or not win:isStandard() then return end
  local screen = win:screen()
  if not screen then return end
  local f = screen:frame()
  local halfW = f.w / 2
  if side == "left" then
    win:setFrame(hs.geometry.rect(f.x, f.y, halfW, f.h))
  else
    win:setFrame(hs.geometry.rect(f.x + halfW, f.y, halfW, f.h))
  end
end

hs.hotkey.bind({"ctrl", "alt"}, "h", function()
  snapFocusedHalf("left")
end)

hs.hotkey.bind({"ctrl", "alt"}, "l", function()
  snapFocusedHalf("right")
end)

hs.hotkey.bind({"ctrl", "alt"}, "c", function()
  hs.task.new("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome", nil, {"--profile-directory=Default"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "r", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/bin/bash", nil, {"-c", home .. "/bin/set_random_wallpaper.sh"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "n", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/bin/bash", nil, {"-c", home .. "/bin/kitty_three"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "p", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/bin/bash", nil, {"-c", home .. "/bin/lofi-beats"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "b", function()
  highlightEnabled = not highlightEnabled
  if not highlightEnabled then
    hideHighlight()
    hs.alert.show("Border dezactivat", 0.7)
  else
    refreshHighlight()
    hs.alert.show("Border activat", 0.7)
  end
end)

hs.hotkey.bind({"ctrl", "alt"}, "m", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/bin/bash", nil, {"-c", home .. "/bin/music-art"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "q", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/bin/bash", nil, {"-c", home .. "/bin/system.sh"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "t", function()
  local home = os.getenv("HOME") or "~"
  hs.task.new("/bin/bash", nil, {"-c", home .. "/bin/rds-url"}):start()
end)

hs.hotkey.bind({"ctrl", "alt"}, "-", function()
  splitOffset = splitOffset + splitStep
  tileTwoWindows()
  refreshHighlight()
end)

hs.hotkey.bind({"ctrl", "alt"}, "=", function()
  splitOffset = splitOffset - splitStep
  tileTwoWindows()
  refreshHighlight()
end)

local function gotoSpaceOnMain(index)
  local main = hs.screen.mainScreen()
  if not main then return end
  local uuid = main:getUUID()
  local map = spaces.allSpaces()
  local list = map and map[uuid] or nil
  if not list or not list[index] then return end
  spaces.gotoSpace(list[index])
end

hs.hotkey.bind({"cmd"}, "q", function()
  local app = hs.application.frontmostApplication()
  if app then
    app:kill()
  end
end)

local lastActiveSpace = nil
local prevActiveSpace = nil
local lastNonEmptySpace = nil
local lastSpaceChangeAt = 0

local function updateLastActiveSpace()
  local win = hs.window.focusedWindow()
  if not win or not win:isStandard() or not win:isVisible() or win:isMinimized() then
    return
  end
  local spacesForWin = hs.spaces.windowSpaces(win)
  local space = spacesForWin and spacesForWin[1] or hs.spaces.focusedSpace()
  if space then
    if lastActiveSpace and lastActiveSpace ~= space then
      prevActiveSpace = lastActiveSpace
    end
    lastActiveSpace = space
    lastNonEmptySpace = space
  end
end

local function allSpacesList()
  local map = hs.spaces.allSpaces()
  local list = {}
  if not map then return list end
  for _, spacesList in pairs(map) do
    for _, s in ipairs(spacesList) do
      table.insert(list, s)
    end
  end
  return list
end

local function findFallbackSpace(current)
  if prevActiveSpace and prevActiveSpace ~= current then
    return prevActiveSpace
  end
  if lastNonEmptySpace and lastNonEmptySpace ~= current and spaceHasStandardWindows(lastNonEmptySpace) then
    return lastNonEmptySpace
  end
  if lastActiveSpace and lastActiveSpace ~= current and spaceHasStandardWindows(lastActiveSpace) then
    return lastActiveSpace
  end
  for _, s in ipairs(allSpacesList()) do
    if s ~= current and spaceHasStandardWindows(s) then
      return s
    end
  end
  return nil
end

local function maybeSwitchToOccupiedSpace()
  if (hs.timer.secondsSinceEpoch() - lastSpaceChangeAt) < 1.0 then
    return
  end
  if currentSpaceHasFullScreenWindow() then
    return
  end
  local current = hs.spaces.focusedSpace()
  if not current then return end
  if currentSpaceHasVisibleStandardWindows() then return end
  local target = findFallbackSpace(current)
  if target and target ~= current then
    hs.spaces.gotoSpace(target)
  end
end

local function scheduleSwitchIfEmpty()
  hs.timer.doAfter(0.2, maybeSwitchToOccupiedSpace)
  hs.timer.doAfter(0.6, maybeSwitchToOccupiedSpace)
end

hs.hotkey.bind({"cmd", "alt"}, "g", function()
  local current = hs.spaces.focusedSpace()
  local target = findFallbackSpace(current)
  local curHas = current and currentSpaceHasVisibleStandardWindows() or false
  hs.printf(
    "space-debug current=%s currentHas=%s target=%s lastActive=%s prevActive=%s lastNonEmpty=%s",
    tostring(current),
    tostring(curHas),
    tostring(target),
    tostring(lastActiveSpace),
    tostring(prevActiveSpace),
    tostring(lastNonEmptySpace)
  )
  if target and current and target ~= current then
    hs.spaces.gotoSpace(target)
  end
end)

refreshHighlight = function()
  if not highlightEnabled then
    return hideHighlight()
  end
  if hs.application.frontmostApplication() and hs.application.frontmostApplication():name() == "Dock" then
    return hideHighlight()
  end
  if not hasStandardVisibleWindows() then
    return hideHighlight()
  end
  local win = hs.window.focusedWindow()
  if not win or not win:isStandard() or not win:isVisible() or win:isMinimized() then
    return hideHighlight()
  end
  local space = hs.spaces.focusedSpace()
  local winSpaces = hs.spaces.windowSpaces(win)
  if space and winSpaces then
    local ok = false
    for _, s in ipairs(winSpaces) do
      if s == space then
        ok = true
        break
      end
    end
    if not ok then
      return hideHighlight()
    end
  end
  showHighlight(win)
end

tileTwoWindows = function()
  local wins = hs.window.visibleWindows()
  if #wins == 0 then
    hideHighlight()
    return
  end
  if not hasStandardVisibleWindows() then
    hideHighlight()
    return
  end

  if hs.application.frontmostApplication() and hs.application.frontmostApplication():name() == "Dock" then
    hideHighlight()
    return
  end

  local focused = hs.window.focusedWindow()
  local screen = focused and focused:screen() or wins[1]:screen()

  local filtered = {}
  for _, w in ipairs(wins) do
    if w:isStandard() and w:isVisible() and not w:isMinimized() and w:screen() == screen and not isFloating(w) then
      table.insert(filtered, w)
    end
  end
  if #filtered == 0 then
    hideHighlight()
    return
  end

  local f = screen:frame()
  local usable = hs.geometry.rect(
    f.x + outer,
    f.y + outer,
    f.w - outer * 2,
    f.h - outer * 2
  )
  if #filtered == 1 then
    filtered[1]:setFrame(usable)
    return
  end
  if #filtered ~= 2 then
    if debug then
      hs.printf("tileTwoWindows: %d windows on screen", #filtered)
    end
    return
  end

  local minW = 200
  local totalW = usable.w - gapH
  local leftW = (totalW / 2) + splitOffset
  if leftW < minW then
    leftW = minW
  elseif leftW > (totalW - minW) then
    leftW = totalW - minW
  end
  local rightW = totalW - leftW
  local rightX = usable.x + leftW + gapH
  local left = hs.geometry.rect(usable.x, usable.y, leftW, usable.h)
  local right = hs.geometry.rect(rightX, usable.y, rightW, usable.h)

  -- Keep positions stable: leftmost stays left, rightmost stays right.
  table.sort(filtered, function(a, b)
    return a:frame().x < b:frame().x
  end)
  filtered[1]:setFrame(left)
  filtered[2]:setFrame(right)
end

local updateTimer = nil
local function requestUpdate()
  if updateTimer then
    updateTimer:stop()
  end
  updateTimer = hs.timer.doAfter(0.02, function()
    updateLastActiveSpace()
    centerFloating(hs.window.focusedWindow())
    tileTwoWindows()
    refreshHighlight()
    scheduleSwitchIfEmpty()
  end)
end

if spaces.watcher then
  local spacesWatcher = spaces.watcher.new(function()
    lastSpaceChangeAt = hs.timer.secondsSinceEpoch()
    hideHighlight()
    local main = hs.screen.mainScreen()
    if main then
      local uuid = main:getUUID()
      local map = spaces.allSpaces()
      local list = map and map[uuid] or nil
      local current = hs.spaces.focusedSpace()
      if list and current then
        for i, s in ipairs(list) do
          if s == current then
            hs.alert.closeAll()
            hs.alert.show("Desktop " .. tostring(i), 0.7)
            break
          end
        end
      end
    end
    requestUpdate()
  end)
  spacesWatcher:start()
end

wf.default:subscribe(wf.windowCreated, requestUpdate)
wf.default:subscribe(wf.windowFocused, requestUpdate)
wf.default:subscribe(wf.windowMoved, requestUpdate)
if wf.windowResized then
  wf.default:subscribe(wf.windowResized, requestUpdate)
end
if wf.windowUnfocused then
  wf.default:subscribe(wf.windowUnfocused, requestUpdate)
end
if wf.windowDestroyed then
  wf.default:subscribe(wf.windowDestroyed, requestUpdate)
end
if wf.windowHidden then
  wf.default:subscribe(wf.windowHidden, requestUpdate)
end
if wf.windowMinimized then
  wf.default:subscribe(wf.windowMinimized, requestUpdate)
end

-- Kitty auto-move disabled; use hotkey instead.

hs.timer.doEvery(1.0, function()
  if highlight.winId and not hs.window.get(highlight.winId) then
    hideHighlight()
  end
end)

local appWatcher = hs.application.watcher.new(function(_, eventType, _)
  if eventType == hs.application.watcher.terminated then
    scheduleSwitchIfEmpty()
  end
end)
appWatcher:start()

requestUpdate()
