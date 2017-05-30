vips = require "vips"

-- uncomment for very chatty output
-- vips.log.enable(true)

image1 = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
print()
--image2 = vips.Image.text("Hello <i>World!</i>", {dpi = 300})
--print()

image1 = vips.Image.new_from_array({1, 2, 3, 4}, 8, 9)


print("writing to x.png ...")
--image1:invert()
image1:write_to_file("x.png")

image1 = nil
image2 = nil
collectgarbage()
print("all done!")

-- success with cache hit
--
-- before construct:
-- 1 objects alive:
-- 0) VipsText (0x55e0b5836830), count=1
-- VipsText (text), make a text image, text text="Hello <i>World!</i>" dpi=300 -
--
-- after construct:
-- 2 objects alive:
-- 0) VipsImage (0x55e0b5838020), count=2
-- VipsImage (image), image class, 311x58 uchar, 1 band, b-w
-- 1) VipsText (0x55e0b5836830), count=4
-- VipsText (text), make a text image, text out=((VipsImage*) 0x55e0b5838020)
-- text="Hello <i>World!</i>" font="sans 12" dpi=300 -
--
-- cache miss ...
-- after post-construct realignment:
--
-- 2 objects alive:
-- 0) VipsImage (0x55e0b5838020), count=1
-- VipsImage (image), image class, 311x58 uchar, 1 band, b-w
-- 1) VipsText (0x55e0b5836830), count=3
-- VipsText (text), make a text image, text out=((VipsImage*) 0x55e0b5838020)
-- text="Hello <i>World!</i>" font="sans 12" dpi=300 -
--
-- at end of call:
-- 2 objects alive:
-- 0) VipsText (0x55fb33fee830), count=2
-- VipsText (text), make a text image, text out=((VipsImage*) 0x55fb33ff0020)
-- text="Hello <i>World!</i>" font="sans 12" dpi=300 -
-- 1) VipsImage (0x55fb33ff0020), count=2
-- VipsImage (image), image class, 311x58 uchar, 1 band, b-w
--
-- references held
--  - cache holds a ref to vipstext
--  - output image holds ref to text
--  - we hold ref to output image
--  - cache text also holds ref to output image

-- failure with cache miss 
--
-- before construct:
-- k
