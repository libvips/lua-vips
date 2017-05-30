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

end)

