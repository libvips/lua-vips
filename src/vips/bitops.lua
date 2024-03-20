local hasbit, bit = pcall(require, "bit")
local bitops = {}

if hasbit then -- Lua 5.1, 5.2 with luabitop or LuaJIT
    bitops.band = bit.band
elseif (_VERSION == "Lua 5.1" or _VERSION == "Lua 5.2") then
    error("Bit operations missing. Please install 'luabitop'")
else -- Lua >= 5.3
    local band, err = load("return function(a, b) return a & b end")
    if band then
        local ok
        ok, bitops.band = pcall(band)
        if not ok then
            error("Execution error")
        end
    else
        error("Compilation error" .. err)
    end
end

return bitops
