-- test all operator overloads

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

-- make a table of x repeated n times
local function replicate(x, n)
    local result = {}

    for i = 1, n do
        result[i] = x
    end

    return result
end

-- apply an operation to a nested table, or to a number
local function map(op, a)
    local result

    if type(a) == "table" then
        result = {}
        for i = 1, #a do
            result[i] = map(op, a[i])
        end
    else
        result = op(a)
    end

    return result
end

-- apply an operation pairwise to two nested tables, or to a table and a number,
-- or to two numbers
local function map2(op, a, b)
    if type(a) == "table" and type(b) == "table" then
        assert.are.equal(#a, #b)
    end

    local result
    if type(a) == "table" or type(b) == "table" then
        if type(a) ~= "table" then
            a = replicate(a, #b)
        end

        if type(b) ~= "table" then
            b = replicate(b, #a)
        end

        result = {}
        for i = 1, #a do
            result[i] = map2(op, a[i], b[i])
        end
    else
        result = op(a, b)
    end

    return result
end

-- find the sum and number of elements in a nested table
local function sum(a)
    local total = 0
    local n = 0

    if type(a) == "table" then
        for i = 1, #a do
            local new_total
            local new_n

            new_total, new_n = sum(a[i])

            total = total + new_total
            n = n + new_n
        end
    else
        total = a
        n = 1
    end

    return total, n
end

-- find the average of a nested table
local function avg(a)
    local total
    local n

    total, n = sum(a)

    return total / n
end

local function test_binary(name, vop, lop)
    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    describe(name, function()

        it("can " .. name .. " image and single constant", function ()
            local im2 = vop(im, 12)
            local a2 = map2(lop, array, 12)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

        it("can " .. name .. " image and single constant, reversed", function ()
            local im2 = vop(12, im)
            local a2 = map2(lop, 12, array)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

        it("can " .. name .. " an image and an array", function()
            local array_constant = {12, 13, 14}
            local im2 = vop(im, array_constant)
            local a2 = map2(lop, array, replicate(array_constant, #array))

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 3)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

        it("can " .. name .. " an image and an array, reversed", function()
            local array_constant = {12, 13, 14}
            local im2 = vop(array_constant, im)
            local a2 = map2(lop, replicate(array_constant, #array), array)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 3)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

        it("can " .. name .. " two images", function()
            local im2 = vop(im, im)
            local a2 = map2(lop, array, array)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

    end)

end

local function test_binary_noreverse(name, vop, lop)
    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    describe(name, function()

        it("can " .. name .. " image and single constant", function ()
            local im2 = vop(im, 12)
            local a2 = map2(lop, array, 12)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

        it("can " .. name .. " an image and an array", function()
            local im2 = vop(im, {12, 13, 14})
            local a2 = map2(lop, array, 13)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 3)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

        it("can " .. name .. " two images", function()
            local im2 = vop(im, im)
            local a2 = map2(lop, array, array)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

    end)

end

local function test_unary(name, vop, lop)
    local array = {1, 2, 3, 4}
    local im = vips.Image.new_from_array(array)

    describe(name, function()
        it("can " .. name .. " an image", function()
            local im2 = vop(im)
            local a2 = map(lop, array)

            assert.are.equal(im2:width(), 4)
            assert.are.equal(im2:height(), 1)
            assert.are.equal(im2:bands(), 1)
            assert.are.almost_equal(im2:avg(), avg(a2))
        end)

    end)
end

describe("test overload", function()
    vips = require("vips")
    -- vips.log.enable(true)

    test_binary("add", 
        function(a, b)
            return vips.Image.mt.__add(a, b)
        end,
        function(a, b)
            return a + b
        end
    )

    test_binary("sub", 
        function(a, b)
            return vips.Image.mt.__sub(a, b)
        end,
        function(a, b)
            return a - b
        end
    )

    test_binary("mul", 
        function(a, b)
            return vips.Image.mt.__mul(a, b)
        end,
        function(a, b)
            return a * b
        end
    )

    test_binary("div", 
        function(a, b)
            return vips.Image.mt.__div(a, b)
        end,
        function(a, b)
            return a / b
        end
    )

    test_binary_noreverse("mod", 
        function(a, b)
            return vips.Image.mt.__mod(a, b)
        end,
        function(a, b)
            return a % b
        end
    )

    test_binary("pow", 
        function(a, b)
            return vips.Image.mt.__pow(a, b)
        end,
        function(a, b)
            return a ^ b
        end
    )

    test_unary("unm", 
        function(a)
            return vips.Image.mt.__unm(a)
        end,
        function(a)
            return -a
        end
    )

    test_binary("less", 
        function(a, b)
            return vips.Image.mt.__lt(a, b)
        end,
        function(a, b)
            if a < b then
                return 255
            else
                return 0
            end
        end
    )

    test_binary("more", 
        function(a, b)
            return vips.Image.mt.__lt(b, a)
        end,
        function(a, b)
            if a > b then
                return 255
            else
                return 0
            end
        end
    )

    test_binary("lesseq", 
        function(a, b)
            return vips.Image.mt.__le(a, b)
        end,
        function(a, b)
            if a <= b then
                return 255
            else
                return 0
            end
        end
    )

    test_binary("moreeq", 
        function(a, b)
            return vips.Image.mt.__le(b, a)
        end,
        function(a, b)
            if a >= b then
                return 255
            else
                return 0
            end
        end
    )

end)
