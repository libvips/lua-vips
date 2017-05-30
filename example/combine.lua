local vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

local main = vips.Image.new_from_file("images/Gugg_coloured.jpg")
local sub = vips.Image.new_from_file("images/watermark.png")
local x, y, width, height = 100, 100, sub:width(), sub:height()

-- extract related area from main image
local extract = main:crop(x, y, width, height)

-- get rgb channels from watermark image
local rgb = sub:extract_band(0, {n = 3}) 

-- get alpha channel from watermark image
local mask = sub:extract_band(3) 

-- use ifthenelse to combine extracted image with sub respecting the 
-- alpha channel
local composite = mask:ifthenelse(rgb, extract, {blend = true})

-- insert composite back in to main image on related area
local combined = main:insert(composite, x, y)

print("writing x.jpg ...")
combined:write_to_file("x.jpg")

