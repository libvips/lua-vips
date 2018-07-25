-- simple logging

local logging_on = false

local log = {}
log = {
    enable = function(on)
        logging_on = on
    end,

    msg = function(...)
        if logging_on then
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
                            sub_p_r(val, indent ..
                                    string.rep(" ", string.len(pos) + 8))
                            p(indent ..
                                    string.rep(" ", string.len(pos) + 6) .. "}")
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
        log.prettyprint_table(log.msg, t)
    end,

    print_r = function(t)
        log.prettyprint_table(print, t)
    end
}

return log
