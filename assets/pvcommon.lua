local math = require "math"
local os = require "os"

math.randomseed(os.time())

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local Video = {}
function Video:new(o)
  o = o or {}

  o.loaded = false
  o.vid = nil

  setmetatable(o, self)
  self.__index = self
  return o
end

function Video:start()
  if not self.loaded then
    self:load()
  end
  self.vid:start()
  self.vid:target(0, 0, WIDTH, HEIGHT)
  self.vid:layer(-1)
end

function Video:stop()
  self.vid:layer(-5)
  self.vid:target(0, 2000, 0, 2000)
  self.vid:stop()
  self.vid:dispose()
  self.loaded = false
end

function Video:draw()
  if self.vid:state() == "finished" then
    -- This only happens for intermissions.
    return self.nextname
  else
    return self.name
  end
end

function Video:status()
  local vid_state = self.vid and self.vid:state()
  print(string.format("Video %s, loaded=%s, vid=%s, state=%s, next=%s (%s)",
    self.name, self.loaded, dump(self.vid), vid_state, self.nextname, dump(self.nextnames)))
end

function Video:ready()
  return self.loaded and (self.vid:state() == "paused" or self.vid:state() == "loaded")
end

function Video:choose_next()
  self.nextname = self.nextnames[math.random(#self.nextnames)]
end

local Looper = Video:new()
function Looper:load()
  print(string.format("Loading %s", self.name))
  self.looped = true
  self.vid = resource.load_video{file=self.file; audio=true; looped=true; paused=true; raw=true}
  if self.config.video_rotation > 0 then
    self.vid:rotate(self.config.video_rotation)
  end
  self.loaded = true
  self:choose_next()
end

local Intermission = Video:new()
function Intermission:load()
  print(string.format("Loading %s", self.name))
  self.looped = false
  self.vid = resource.load_video{file=self.file; audio=true; looped=false; paused=true; raw=true}
  if self.config.video_rotation > 0 then
    self.vid:rotate(self.config.video_rotation)
  end
  self.loaded = true
  self:choose_next()
end

return {
  Looper = Looper,
  Intermission = Intermission,
}
