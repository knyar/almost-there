local json = require "json"
local pvcommon = require "pvcommon"

local config = json.decode(resource.load_file "config.json")

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
node.alias "looper"

local surface
local distance = 9000
local visitors = false
local videos = {}

local function switch_video(name)
  if not videos[name] then
    print("ERROR: invalid video name: " .. name)
    return
  end
  print("Switching to: " .. name)

  local prev = surface

  videos[name]:start()
  surface = videos[name]
  local nextname = videos[name].nextname

  if prev ~= nil and prev.name == nextname and prev.looped then
    -- Going back to the same looped video, no need to reload it.
    prev:choose_next()
    return
  end

  if prev ~= nil and prev.loaded then
    prev:stop()
  end

  print("Preloading: " .. nextname)
  videos[nextname]:load()
end

local function reload_videos()
  surface = resource.create_colored_texture(0, 0, 0, 0)
  for videoname, video in pairs(videos) do
    if video.loaded then
      video:stop()
    end
  end

  videos.loop = pvcommon.Looper:new{name="loop", file=config.loop.asset_name, nextnames={"intermission_1", "intermission_2"}, config=config};
  videos.intermission_1 = pvcommon.Intermission:new{name="intermission_1", file=config.intermission_1.asset_name, nextnames={"loop"}, config=config};
  videos.intermission_2 = pvcommon.Intermission:new{name="intermission_2", file=config.intermission_2.asset_name, nextnames={"loop"}, config=config};

  switch_video("loop")
end

local function detect_visitors()
  if distance < config.trigger_distance and not visitors then
    print("Got visitors!")
    visitors = true
    return true
  elseif distance >= config.trigger_distance and visitors then
    print("Visitors left :(")
    visitors = false
    return false
  end
  return nil
end

util.data_mapper{
  ["distance"] = function(message)
    message = message:gsub('\n$', '')
    distance = tonumber(message)
  end;
  -- echo root/debug: | nc -u -w 1 127.0.0.1 4444
  ["debug"] = function(message)
    print(string.format("Current video: %s, distance=%d (%d), visitors=%s",
      surface.name, distance, config.trigger_distance, tostring(visitors)))
    for videoname, video in pairs(videos) do
      video:status()
    end
  end;
}

util.file_watch("config.json", function(content)
  config = json.decode(content)
  reload_videos()
end)

util.file_watch("pvcommon.lua", function(content)
  pvcommon = require "pvcommon"
  reload_videos()
end)

function node.render()
  local detected = detect_visitors()
  local switch_to = nil
  local nextvideo = surface:draw()
  if nextvideo ~= surface.name then
    switch_to = nextvideo
  end
  if surface.name == "loop" and detected == true then
    switch_to = surface.nextname
  end
  if switch_to ~= nil and videos[switch_to]:ready() then
    switch_video(switch_to)
  end
end
