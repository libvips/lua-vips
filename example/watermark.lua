#!/usr/bin/luajit

-- add a simple text watermark to an image
--    ./watermark.lua ~/pics/IMG_0073.JPG x.jpg "Hello <i>world!</i>"

local vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

local im = vips.Image.new_from_file(arg[1], {access = "sequential"})

-- make the text mask
local text = vips.Image.text(arg[3],
    {width = 200, dpi = 200, align = "centre", font = "sans bold"})
text = text:rotate(-45)
-- make the text transparent
text = (text * 0.3):cast("uchar")
text = text:gravity("centre", 200, 200)
-- this block of pixels will be reused many times ... make a copy
text = text:copy_memory()
text = text:replicate(1 + im:width() // text:width(),
    1 + im:height() // text:height())
text = text:crop(0, 0, im:width(), im:height())

-- we make a constant colour image and attach the text mask as the alpha
local overlay =
    text:new_from_image({255, 128, 128}):copy{interpretation = "srgb"}
overlay = overlay:bandjoin(text)

-- overlay the text
im = im:composite(overlay, "over")

im:write_to_file(arg[2])
