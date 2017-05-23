-- manage VipsOperation
-- lookup and call operations

local ffi = require "ffi"
local bit = require "bit"
local band = bit.band

local log = require "vips/log"
local gvalue = require "vips/gvalue"
local vobject = require "vips/object"

local vips = ffi.load("vips")

ffi.cdef[[
    typedef struct _VipsOperation {
        VipsObject parent_instance;

        // opaque
    } VipsOperation;

    VipsOperation* vips_operation_new (const char* name);

    typedef void *(*VipsArgumentMapFn) (VipsOperation* object, 
        GParamSpec* pspec,
        VipsArgumentClass* argument_class,
        VipsArgumentInstance* argument_instance, 
        void* a, void* b);

    void* vips_argument_map (VipsOperation* object,
        VipsArgumentMapFn fn, void* a, void* b);

    VipsOperation* vips_cache_operation_build (VipsOperation* operation);
    void vips_object_unref_outputs (VipsOperation *operation);

]]

local REQUIRED = 1
local CONSTRUCT = 2
local SET_ONCE = 4
local SET_ALWAYS = 8
local INPUT = 16
local OUTPUT = 32
local DEPRECATED = 64
local MODIFY = 128

local voperation
local voperation_mt = {
    __index = {
        argumentmap_typeof = ffi.typeof("VipsArgumentMapFn"),

        -- cast to an object
        object = function(self)
            return ffi.cast(vobject.typeof, self)
        end,

        get = function(self, name)
            return self:object():get(name)
        end,

        set = function(self, name, value)
            return self:object():set(name, value)
        end,

        -- this is slow ... call as little as possible
        getargs = function(self)
            local args = {}
            local cb = ffi.cast(voperation.argumentmap_typeof,
                function(self, pspec, argument_class, argument_instance, a, b)
                    table.insert(args, 
                        {name = ffi.string(pspec.name), 
                         flags = tonumber(argument_class.flags)
                        }
                    )
                end
            )
            vips.vips_argument_map(self, cb, nil, nil )
            cb:free()

            return args
        end,

        call = function(name, ...)
            local call_args = {...}

            local operation = vips.vips_operation_new(name)
            if operation == nil then
                print("no such operation", vobject.get_error())
                return
            end
            operation:object():new()

            local arguments = operation:getargs()

            log.msg(name, "needs:")
            log.msg_r(arguments)

            log.msg("passed:")
            log.msg_r(call_args)

            local n = 0
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, INPUT) ~= 0 and 
                    band(flags, REQUIRED) ~= 0 and 
                    band(flags, DEPRECATED) == 0 then
                    n = n + 1
                    if not operation:set(arguments[i].name, call_args[n]) then
                        return
                    end
                end
            end

            local last_arg
            if #call_args == n then 
                last_arg = nil
            elseif #call_args == n + 1 then
                last_arg = call_args[#call_args]
                if type(last_arg) ~= "table" then
                    error("final argument is not a table")
                end
            else
                log.msg("#call_args =", #call_args)
                log.msg("n =", n)
                error("wrong number of arguments to " .. name)
            end

            if last_arg then
                for k, v in pairs(last_arg) do
                    if not operation:set(k, v) then
                        return
                    end
                end
            end

            log.msg("constructing ...")
            local operation2 = vips.vips_cache_operation_build(operation);
            if operation2 == nil then
                vips.vips_object_unref_outputs(operation)
                print("build error", vobject.get_error())
                return nil
            end
            operation = operation2

            log.msg("getting output ...")
            result = {}
            n = 1
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and 
                    band(flags, REQUIRED) ~= 0 and 
                    band(flags, DEPRECATED) == 0 then
                    result[n] = operation:get(arguments[i].name)
                    n = n + 1
                end
            end

            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and 
                    band(flags, REQUIRED) == 0 and 
                    band(flags, DEPRECATED) == 0 then
                    result[n] = operation:get(arguments[i].name)
                    n = n + 1
                end
            end

            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and 
                    band(flags, DEPRECATED) ~= 0 then
                    result[n] = operation:get(arguments[i].name)
                    n = n + 1
                end
            end

            return unpack(result)
        end,

    }
}

voperation = ffi.metatype("VipsOperation", voperation_mt)
return voperation

