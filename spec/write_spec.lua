-- test image writers

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

say:set("assertion.almost_equal.positive", 
    "Expected %s to almost equal %s")
say:set("assertion.almost_equal.negative", 
    "Expected %s to not almost equal %s")
assert:register("assertion", "almost_equal", almost_equal, 
    "assertion.almost_equal.positive", 
    "assertion.almost_equal.negative")

describe("test image write to file", function()
    vips = require("vips")
    -- vips.log.enable(true)

    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)
    local tmp_png_filename = "/tmp/x.png"
    local tmp_jpg_filename = "/tmp/x.jpg"

    teardown(function()
        os.remove(tmp_png_filename)
        os.remove(tmp_jpg_filename)
    end)

    it("can save and then load a png", function()
        im:write_to_file(tmp_png_filename)
        local im2 = vips.Image.new_from_file(tmp_png_filename)

        assert.are.equal(im:width(), im2:width())
        assert.are.equal(im:height(), im2:height())
        assert.are.equal(im:avg(), im2:avg())
    end)

    it("can save and then load a jpg with an option", function()
        im:write_to_file(tmp_jpg_filename, {Q = 90})
        local im2 = vips.Image.new_from_file(tmp_jpg_filename)

        assert.are.equal(im:width(), im2:width())
        assert.are.equal(im:height(), im2:height())
        assert.are.almost_equal(im:avg(), im2:avg())
    end)

end)

describe("test image from buffer", function()
    vips = require("vips")
    -- vips.log.enable(true)

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

    it("can write a jpeg to buffer with an option", function()
        local im = vips.Image.new_from_file("images/Gugg_coloured.jpg")
        local buf = im:write_to_buffer(".jpg")
        local buf2 = im:write_to_buffer(".jpg", {Q = 100})

        assert.is.True(#buf2 > #buf)
    end)

end)
