local vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

local main = vips.Image.new_from_file("../spec/images/Gugg_coloured.jpg")
local sub = vips.Image.new_from_file("../spec//images/watermark.png")
local x, y, width, height = 100, 100, sub:width(), sub:height()

-- extract related area from main image
local extract = vips.Image.extract_area(main, x, y, width, height)
-- get alpha channel from sub image
local filter = sub:extract_band(3) -- get alpha channel
-- create options table with blend option
local options = {}
options['blend'] = true
-- use ifthenelse to combine extracted image with sub respecting the alpha channel
local composite = vips.Image.ifthenelse(filter, sub, extract, options)
-- insert composite into main image on related area
local combined = vips.Image.insert(main, composite, x, y)
combined:write_to_file("combined.png")

