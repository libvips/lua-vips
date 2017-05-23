-- simple logging

local logging_on = false

local log
log = {
    enable = function(on)
        logging_on = on
    end,

    msg = function(...)
        if logging_on then
            print(unpack{...})
        end
    end,

    msg_r = function(t)
        local log_r_cache = {}
        local function sub_log_r(t, indent)
            if (log_r_cache[tostring(t)]) then
                log.msg(indent .. "*" .. tostring(t))
            else
                log_r_cache[tostring(t)] = true
                if type(t) == "table" then
                    for pos, val in pairs(t) do
                        if type(val) == "table" then
                            log.msg(indent .. 
                                "[" .. pos .. "] => " ..  tostring(t) .. " {")
                            sub_log_r(val, indent .. 
                                string.rep(" ", string.len(pos) + 8))
                            log.msg(indent .. 
                                string.rep(" ", string.len(pos) + 6) .. "}")
                        elseif type(val) == "string" then
                            log.msg(indent .. "[".. pos .. '] => "' .. 
                                val .. '"')
                        else
                            log.msg(indent .. "[" .. pos .. "] => " .. 
                                tostring(val))
                        end
                    end
                else
                    log.msg(indent .. tostring(t))
                end
            end
        end
        if type(t) == "table" then
            log.msg(tostring(t) .. " {")
            sub_log_r(t, "  ")
            log.msg("}")
        else
            sub_log_r(t, "  ")
        end
        log.msg()
    end

}

return log

