local json = require "json"

local config = json.decode(resource.load_file "config.json")

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
node.alias "looper"

local distance = 0
local blur = 0
local prev_blur = 0
local videos = {}

local function reload_videos()
  for videoname, video in pairs(videos) do
    if video.loaded then
      video:stop()
    end
  end

  videos.loop1 = resource.load_video{file=config.default_loop.asset_name; audio=true; looped=true; paused=true; raw=true}
  videos.loop2 = resource.load_video{file=config.default_loop.asset_name; audio=true; looped=true; paused=true; raw=true}

  while (videos.loop1:state() == "loading") do
    print("XXX VIDEO", videos.loop1:state())
  end
  while (videos.loop2:state() == "loading") do
    print("XXX VIDEO", videos.loop1:state())
  end

  videos.loop1:place(0, 0, WIDTH, HEIGHT, config.video_rotation)
  videos.loop1:layer(1)
  videos.loop2:place(0, 0, WIDTH, HEIGHT, config.video_rotation)
  videos.loop2:layer(2)
  videos.loop1:alpha(0.5)
  videos.loop2:alpha(0.5)

  videos.loop1:start()
  videos.loop2:start()

  -- -- videos.loop2:load()

  -- videos.loop1.vid:start()
  -- videos.loop1.vid:place(0, 0, WIDTH, HEIGHT)
  -- videos.loop1.vid:layer(-1)

  -- videos.loop2:start()
end

local function apply_blur()
  if distance > 200 then
    blur = 0
  else
    blur = (1 / distance) * 500
  end

  if blur == prev_blur then
    return
  end

  videos.loop1:place(0, 0, WIDTH+blur, HEIGHT+blur, config.video_rotation)
  videos.loop2:place(0, 0, WIDTH-blur, HEIGHT-blur, config.video_rotation)

  prev_blur = blur
end

util.data_mapper{
  ["distance"] = function(message)
    message = message:gsub('\n$', '')
    distance = tonumber(message)
  end;
  -- echo root/debug: | nc -u -w 1 127.0.0.1 4444
  ["debug"] = function(message)
    for videoname, video in pairs(videos) do
      print(string.format("Video %s, %s, %s", videoname, video:state(), dump(video)))
    end
  end;
}
util.file_watch("config.json", function(content)
  config = json.decode(content)
  reload_videos()
end)

-- reload_videos()
function node.render()
  apply_blur()
end
