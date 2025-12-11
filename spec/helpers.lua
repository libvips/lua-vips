-- Pre-load the vips module
require "vips"

local assert = require "luassert.assert"
local say = require "say"

local function almost_equal(_, arguments)
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