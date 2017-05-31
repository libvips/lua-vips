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

describe("test convenience functions", function()
    vips = require("vips")
    -- vips.log.enable(true)

    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    it("can join images bandwise", function ()
        local im2 = im:bandjoin({im + 1, im + 2})

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 3)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 3.5)
        assert.are.equal(im2:extract_band(2):avg(), 4.5)

    end)

    it("can join constants to images bandwise", function ()
        local im2 = im:bandjoin(255)

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 2)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 255)

    end)

    it("can join images and constants bandwise", function ()
        local im2 = im:bandjoin({im + 1, 255, im + 2})

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 4)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 3.5)
        assert.are.equal(im2:extract_band(2):avg(), 255)
        assert.are.equal(im2:extract_band(3):avg(), 4.5)

    end)

    it("can join images and array constants bandwise", function ()
        local im2 = im:bandjoin({im + 1, {255, 128}})

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 4)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)
        assert.are.equal(im2:extract_band(1):avg(), 3.5)
        assert.are.equal(im2:extract_band(2):avg(), 255)
        assert.are.equal(im2:extract_band(3):avg(), 128)

    end)

    it("can call bandrank", function ()
        local im2 = im:bandrank(im + 1, {index = 0})

        assert.are.equal(im2:width(), 4)
        assert.are.equal(im2:height(), 1)
        assert.are.equal(im2:bands(), 1)
        assert.are.equal(im2:extract_band(0):avg(), 2.5)

    end)

    it("can call bandsplit", function ()
        local bands = im:bandjoin({im + 1, {255, 128}}):bandsplit()

        assert.are.equal(#bands, 4)
        assert.are.equal(bands[1]:width(), 4)
        assert.are.equal(bands[1]:height(), 1)
        assert.are.equal(bands[1]:bands(), 1)

    end)

    it("can call ifthenelse with an image and two constants", function ()
        local result = im:more(2):ifthenelse(1, 2)

        assert.are.equal(result:width(), 4)
        assert.are.equal(result:height(), 1)
        assert.are.equal(result:bands(), 1)
        assert.are.equal(result:avg(), 6 / 4)

    end)

    it("can call ifthenelse with two images and one constant", function ()
        local result = im:more(2):ifthenelse(im + 3, 2)

        assert.are.equal(result:width(), 4)
        assert.are.equal(result:height(), 1)
        assert.are.equal(result:bands(), 1)
        assert.are.equal(result:avg(), 17 / 4)

    end)

end)

