local gvalue = require("gvalue_connector")

local value

value = gvalue.new()
value:init(gvalue.gint_type)
value:set(12)
print("set value of 12")
print("fetch value:")
print("   ", value:get())

value = gvalue.new()
value:init(gvalue.gstr_type)
value:set("banana")
print("set value of banana")
print("fetch value:")
print("   ", value:get())
