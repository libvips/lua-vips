-- simple logging

local logging_enabled = false

local type = type
local print = print
local pairs = pairs
local unpack = unpack or table.unpack
local tostring = tostring
local str_rep = string.rep

local log = {}
log = {
    enable = function(on)
        logging_enabled = on
    end,

    msg = function(...)
        if logging_enabled then
            print(unpack { ... })
        end
    end,

    prettyprint_table = function(p, table)
        local p_r_cache = {}
        local function sub_p_r(t, indent)
            if (p_r_cache[tostring(t)]) then
                p(indent .. "*" .. tostring(t))
            else
                p_r_cache[tostring(t)] = true
                if type(t) == "table" then
                    for pos, val in pairs(t) do
                        if type(val) == "table" then
                            p(indent ..
                                    "[" .. pos .. "] => " .. tostring(t) .. " {")
                            local length = type(pos) == "string" and #pos or pos
                            sub_p_r(val, indent .. str_rep(" ", length + 8))
                            p(indent .. str_rep(" ", length + 6) .. "}")
                        elseif type(val) == "string" then
                            p(indent .. "[" .. pos .. '] => "' ..
                                    val .. '"')
                        else
                            p(indent .. "[" .. pos .. "] => " ..
                                    tostring(val))
                        end
                    end
                else
                    p(indent .. tostring(t))
                end
            end
        end

        if type(table) == "table" then
            p(tostring(table) .. " {")
            sub_p_r(table, "  ")
            p("}")
        else
            sub_p_r(table, "  ")
        end
        p()
    end,

    msg_r = function(t)
        if logging_enabled then
            log.prettyprint_table(log.msg, t)
        end
    end,

    print_r = function(t)
        if logging_enabled then
            log.prettyprint_table(print, t)
        end
    end
}

return log
