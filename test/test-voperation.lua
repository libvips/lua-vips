local voperation = require("voperation_connector")

local result = voperation.call("black", 100, 200, {bands = 3})
print("  result =", result)

print("")
print("get height:")
local height = result:object():get("height")
print("height = ", height)
