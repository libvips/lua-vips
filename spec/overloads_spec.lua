-- test image new/load/etc.

require 'busted.runner'()

-- apply an operation pairwise to two tables
local function map2(op, a, b)
    assert.are.equal(#a, #b)

    local result = {}
    for i = 1, #a do
        result[i] = op(a[i], b[i])
    end

    return result
end

-- find the average of a table
local function avg(a)
    local sum = 0
    for i = 1, #a do
        sum = sum + a[i]
    end

    return sum / #a
end

local function test_operator(name, im, vop, lop)
    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    describe("test " .. name, function()

        it("can " .. name .. " image and single constant", function ()
            local im2 = vop(im, 12)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), lop(12, im:avg()))
        end)

        it("can " .. name .. " image and single constant, reversed", function ()
            local im2 = vop(12, im)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), lop(im:avg(), 12))
        end)

        it("can " .. name .. " an image and an array constant", function()
            local im2 = vop(im, {12, 13, 14})

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 3)
            assert.are.equal(im2:avg(), lop(im:avg(), 13))
        end)

        it("can " .. name .. " two images", function()
            local im2 = vop(im, im)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.equal(im2:avg(), avg(map2(lop, array, array)))
        end)

    end)

end

describe("test overloads", function()
    vips = require("vips")
    -- vips.log.enable(true)

    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    test_operator("add", im,
        function(a, b)
            return vips.Image.mt.__add(a, b)
        end,
        function(a, b)
            return a + b
        end
    )

    test_operator("mul", im,
        function(a, b)
            return vips.Image.mt.__mul(a, b)
        end,
        function(a, b)
            return a * b
        end
    )

end)
