-- test cache control

require 'busted.runner'()

describe("cache control", function()
    vips = require("vips")
    --vips.log.enable(true)

    it("can set number of operations to cache", function()
        local max = vips.get_max()

        vips.set_max(10)
        assert.are.equal(vips.get_max(), 10)
        vips.set_max(max)
    end)

    it("can limit the number of operations to cache by open files", function()
        local max = vips.get_max_files()

        vips.set_max_files(10)
        assert.are.equal(vips.get_max_files(), 10)
        vips.set_max_files(max)
    end)

    it("can limit the number of operations to cache by memory", function()
        local max = vips.get_max_mem()

        vips.set_max_mem(10)
        assert.are.equal(vips.get_max_mem(), 10)
        vips.set_max_mem(max)
    end)

end)
