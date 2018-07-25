-- Pre-load the vips module
require "vips"

local assert = require "luassert.assert"
local say = require "say"

-- TODO: Wait for https://github.com/Olivine-Labs/luassert/issues/148
-- Meanwhile, we're applying patch #150 here.

-- Pre-load the ffi module, such that it becomes part of the environment
-- and Busted will not try to GC and reload it. The ffi is not suited
-- for that and will occasionally segfault if done so.
local ffi = require "ffi"

-- Patch ffi.cdef to only be called once with each definition, as it
-- will error on re-registering.
local old_cdef = ffi.cdef
local exists = {}
ffi.cdef = function(def)
    if exists[def] then
        return
    end
    exists[def] = true
    return old_cdef(def)
end

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