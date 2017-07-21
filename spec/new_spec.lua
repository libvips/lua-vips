-- test image new/load/etc.

require 'busted.runner'()

say = require("say")

local function almost_equal(state, arguments)
    local has_key = false
    local threshold = arguments[3] or 0.001

    if type(arguments[1]) ~= "number" or type(arguments[2]) ~= "number" then
        return false
    end

    return math.abs(arguments[1] - arguments[2]) < threshold
end

say:set("assertion.almost_equal.positive", "Expected %s to almost equal %s")
say:set("assertion.almost_equal.negative", "Expected %s to not almost equal %s")
assert:register("assertion", "almost_equal", almost_equal, 
    "assertion.almost_equal.positive", 
    "assertion.almost_equal.negative")

describe("test image creation", function()
    vips = require("vips")
    -- vips.log.enable(true)

    describe("test image from array", function()

        it("can make an image from a 1D array", function()
            local array = {1, 2, 3, 4}
            local im = vips.Image.new_from_array(array)

            assert.are.equal(im:width(), 4)
            assert.are.equal(im:height(), 1)
            assert.are.equal(im:get("scale"), 1)
            assert.are.equal(im:get("offset"), 0)
            assert.are.equal(im:avg(), 2.5)
        end)

        it("can make an image from a 2D array", function()
            local array = {{1, 2}, {3, 4}}
            local im = vips.Image.new_from_array(array)

            assert.are.equal(im:width(), 2)
            assert.are.equal(im:height(), 2)
            assert.are.equal(im:get("scale"), 1)
            assert.are.equal(im:get("offset"), 0)
            assert.are.equal(im:avg(), 2.5)
        end)

        it("can set scale and offset on an array", function()
            local array = {{1, 2}, {3, 4}}
            local im = vips.Image.new_from_array(array, 12, 3)

            assert.are.equal(im:width(), 2)
            assert.are.equal(im:height(), 2)
            assert.are.equal(im:get("scale"), 12)
            assert.are.equal(im:get("offset"), 3)
            assert.are.equal(im:avg(), 2.5)
        end)

    end)

    describe("test image from file", function()
            
        it("can load a jpeg from a file", function()
            local im = vips.Image.new_from_file("images/Gugg_coloured.jpg")

            assert.are.equal(im:width(), 972)
            assert.are.equal(im:height(), 1296)
            assert.are.almost_equal(im:avg(), 113.96)
        end)

        it("can subsample a jpeg from a file", function()
            local im = vips.Image.new_from_file("images/Gugg_coloured.jpg",
                {shrink = 2})

            assert.are.equal(im:width(), 486)
            assert.are.equal(im:height(), 648)
            assert.are.almost_equal(im:avg(), 113.979)
        end)

        it("can subsample a jpeg from a file, shrink in filename", function()
            local im = vips.Image.new_from_file(
                "images/Gugg_coloured.jpg[shrink=2]")

            assert.are.equal(im:width(), 486)
            assert.are.equal(im:height(), 648)
            assert.are.almost_equal(im:avg(), 113.979)
        end)

    end)

    describe("test image from buffer", function()

        it("can write a jpeg to buffer", function()
            local im = vips.Image.new_from_file("images/Gugg_coloured.jpg")
            local buf = im:write_to_buffer(".jpg")
            local f = io.open("x.jpg", "w+b")
            f:write(buf)
            f:close()
            local im2 = vips.Image.new_from_file("x.jpg")

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
            -- remove test file
            os.remove("x.jpg")
        end)

        it("can load a jpeg from a buffer", function()
            local im = vips.Image.new_from_file("images/Gugg_coloured.jpg")
            local f = io.open("images/Gugg_coloured.jpg", "rb")
            local buf = f:read("*all")
            f:close()
            local im2 = vips.Image.new_from_buffer(buf)

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
        end)

        it("can load a jpeg from a buffer, options in a table", function()
            local im = vips.Image.new_from_file("images/Gugg_coloured.jpg", 
                {shrink = 2})
            local f = io.open("images/Gugg_coloured.jpg", "rb")
            local buf = f:read("*all")
            f:close()
            local im2 = vips.Image.new_from_buffer(buf, "", {shrink = 2})

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
        end)

        it("can load a jpeg from a buffer, options in a table", function()
            local im = vips.Image.new_from_file("images/Gugg_coloured.jpg",
                {shrink = 2})
            local f = io.open("images/Gugg_coloured.jpg", "rb")
            local buf = f:read("*all")
            f:close()
            local im2 = vips.Image.new_from_buffer(buf, "shrink=2")

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
        end)

    end)

    describe("test vips creators", function()

        it("can call vips_black()", function()
            local im = vips.Image.black(1, 1)

            assert.are.equal(im:width(), 1)
            assert.are.equal(im:height(), 1)
            assert.are.equal(im:bands(), 1)
            assert.are.equal(im:avg(), 0)

        end)

        it("can call operations with - in option names", function()
            local im = vips.Image.perlin(100, 100, {cell_size = 10})

            assert.are.equal(im:width(), 100)
            assert.are.equal(im:height(), 100)
            assert.are.equal(im:bands(), 1)
        end)

    end)

    describe("test image from image", function()
        local im = vips.Image.new_from_file("images/Gugg_coloured.jpg")

        it("can make a one-band constant image", function()
            local im2 = im:new_from_image(12)

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:interpretation(), im2:interpretation())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), 12)

        end)

        it("can make a many-band constant image", function()
            local im2 = im:new_from_image({1, 2, 3, 4})

            assert.are.equal(im:width(), im2:width())
            assert.are.equal(im:height(), im2:height())
            assert.are.equal(im:format(), im2:format())
            assert.are.equal(im:interpretation(), im2:interpretation())
            assert.are.equal(im:xres(), im2:xres())
            assert.are.equal(im:yres(), im2:yres())
            assert.are.equal(im2:bands(), 4)
            assert.are.equal(im2:avg(), 2.5)

        end)

    end)

end)
