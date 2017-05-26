-- test image new/load/etc.

require 'busted.runner'()

describe("test gvalue", function()
    vips = require("vips")
    -- vips.log.enable(true)

    it("can set/get an int-valued gvalue", function()
        local value = vips.gvalue.new()
        value:init(vips.gvalue.gint_type)
        value:set(12)
        assert.are.equal(value:get(), 12)
    end)

    it("can set/get a string-valued gvalue", function()
        local value = vips.gvalue.new()
        value:init(vips.gvalue.gstr_type)
        value:set("banana")
        assert.are.equal(value:get(), "banana")
    end)

end)
