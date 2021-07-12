local vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

local main_filename = "images/Gugg_coloured.jpg"
local watermark_filename = "images/PNG_transparency_demonstration_1.png"

local main = vips.Image.new_from_file(main_filename)
local watermark = vips.Image.new_from_file(watermark_filename)

-- scale the alpha down to 30% transparency
watermark = watermark * { 1, 1, 1, 0.3 }

-- composite onto the base image at the top left
local result = main:composite(watermark, "over", { x = 10, y = 10 })

print("writing x.jpg ...")
result:write_to_file("x.jpg")

