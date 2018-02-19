local vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

local main_filename = "images/Gugg_coloured.jpg"
local watermark_filename = "images/PNG_transparency_demonstration_1.png"

local main = vips.Image.new_from_file(main_filename)
local watermark = vips.Image.new_from_file(watermark_filename)
local left, top, width, height = 100, 100, watermark:width(), watermark:height()

-- extract related area from main image
local base = main:crop(left, top, width, height)

-- composite the two areas using the PDF "over" mode
local composite = base:composite(watermark, "over")

-- the result will have an alpha, and our base image does not .. we must flatten
-- out the alpha before we can insert it back into a plain RGB JPG image
composite = composite:flatten()

-- insert composite back in to main image on related area
local combined = main:insert(composite, left, top)

print("writing x.jpg ...")
combined:write_to_file("x.jpg")

