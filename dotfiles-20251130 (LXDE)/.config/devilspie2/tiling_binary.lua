#!/usr/bin/env lua
-- Tiling binario estilo Hyprland sobre Openbox
-- Uso: lua tiling.lua <screen_w> <screen_h> <gap> <border>

local screen_w = tonumber(arg[1])
local screen_h = tonumber(arg[2])
local gap = tonumber(arg[3])
local border = tonumber(arg[4])

-- Obtener lista de ventanas
local windows = {}
for line in io.popen("wmctrl -l | awk '{print $1}'"):lines() do
  table.insert(windows, line)
end

-- Dividir binariamente el espacio
local function tile_binary(wins, x, y, w, h, depth)
  if #wins == 0 then return end
  if #wins == 1 then
    local xid = wins[1]
    local gx = math.floor(x + gap)
    local gy = math.floor(y + gap)
    local gw = math.floor(w - gap * 2 - border)
    local gh = math.floor(h - gap * 2 - border)
    os.execute(string.format("wmctrl -i -r %s -e 0,%d,%d,%d,%d", xid, gx, gy, gw, gh))
    return
  end

  local half = math.floor(#wins / 2)
  local split_horizontal = (depth % 2 == 0)

  if split_horizontal then
    local w1 = math.floor(w / 2)
    tile_binary({table.unpack(wins, 1, half)}, x, y, w1, h, depth + 1)
    tile_binary({table.unpack(wins, half + 1)}, x + w1, y, w - w1, h, depth + 1)
  else
    local h1 = math.floor(h / 2)
    tile_binary({table.unpack(wins, 1, half)}, x, y, w, h1, depth + 1)
    tile_binary({table.unpack(wins, half + 1)}, x, y + h1, w, h - h1, depth + 1)
  end
end

tile_binary(windows, 0, 0, screen_w, screen_h, 0)
