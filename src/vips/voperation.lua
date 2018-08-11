-- manage VipsOperation
-- lookup and call operations

local ffi = require "ffi"
local bit = require "bit"
local band = bit.band

local verror = require "vips/verror"
local log = require "vips/log"
local gvalue = require "vips/gvalue"
local vobject = require "vips/vobject"
local Image = require "vips/Image"

local vips_lib = ffi.load(ffi.os == "Windows" and "libvips-42.dll" or "vips")

local REQUIRED = 1
local CONSTRUCT = 2 -- luacheck: ignore
local SET_ONCE = 4 -- luacheck: ignore
local SET_ALWAYS = 8 -- luacheck: ignore
local INPUT = 16
local OUTPUT = 32
local DEPRECATED = 64
local MODIFY = 128

local function map(fn, array)
    local new_array = {}

    for i, v in ipairs(array) do
        new_array[i] = fn(v)
    end

    return new_array
end

-- find in order, and recurse
local function find_order(fn, array)
    for i = 1, #array do
        if fn(array[i]) then
            return array[i]
        elseif type(array[i]) == "table" then
            local result = find_order(fn, array[i])

            if result then
                return result
            end
        end
    end

    return nil
end

local voperation = {}
local voperation_mt = {
    __index = {
        argumentmap_typeof = ffi.typeof("VipsArgumentMapFn"),

        -- cast to a vobject ... this will create a new cdata object, but won't
        -- change any VipsObject reference counts, nor add a finalizer
        vobject = function(self)
            return ffi.cast(vobject.typeof, self)
        end,

        -- but for new() we can't do self:vobject():new() since that would
        -- attach the unref callback to the cdata object made by the vobject()
        -- cast, not to this voperation
        new = function(self)
            return vobject.new(self)
        end,

        set = function(self, name, flags, match_image, value)
            -- if the object wants an image and we have a constant, imageize it
            --
            -- if the object wants an image array, imageize any constants in the
            -- array
            if match_image then
                local gtype = self:vobject():get_typeof(name)

                if gtype == gvalue.image_type then
                    value = match_image:imageize(value)
                elseif gtype == gvalue.array_image_type then
                    value = map(function(x)
                        return match_image:imageize(x)
                    end, value)
                end
            end

            -- MODIFY args need to be copied before they are set
            if band(flags, MODIFY) ~= 0 then
                log.msg("copying MODIFY arg", name)
                -- make sure we have a unique copy
                value = value:copy():copy_memory()
            end

            return self:vobject():set(name, value)
        end,

        -- this is slow ... call as little as possible
        getargs = function(self)
            local args = {}
            local cb = ffi.cast(voperation.argumentmap_typeof,
                function(_, pspec, argument_class, _, _, _)
                    local name = ffi.string(pspec.name)

                    -- libvips uses "-" to separate parts of arg names, but we
                    -- need "_" for lua
                    name = string.gsub(name, "-", "_")

                    table.insert(args, {
                        name = name,
                        flags = tonumber(argument_class.flags)
                    })
                end)
            vips_lib.vips_argument_map(self, cb, nil, nil)
            cb:free()

            return args
        end,

        -- string_options is any optional args coded as a string, perhaps
        -- "[strip,tile=true]"
        call = function(name, string_options, ...)
            local call_args = { ... }

            local vop = vips_lib.vips_operation_new(name)
            if vop == nil then
                error("no such operation\n" .. verror.get())
            end
            vop:new()

            local arguments = vop:getargs()

            log.msg("calling operation:", name)
            log.msg("passed:")
            log.msg_r(call_args)

            -- count required input args
            local n_required = 0
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, INPUT) ~= 0 and
                        band(flags, REQUIRED) ~= 0 and
                        band(flags, DEPRECATED) == 0 then
                    n_required = n_required + 1
                end
            end

            -- so we should have been passed n_required, or n_required + 1 if
            -- there's a table of options at the end
            local last_arg
            if #call_args == n_required then
                last_arg = nil
            elseif #call_args == n_required + 1 then
                last_arg = call_args[#call_args]
                if type(last_arg) ~= "table" then
                    error("unable to call " .. name .. ": " .. #call_args ..
                            " arguments given, " .. n_required ..
                            ", but final argument is not a table")
                end
            else
                error("unable to call " .. name .. ": " .. #call_args ..
                        " arguments given, but " .. n_required .. " required")
            end

            -- the first image argument is the thing we expand constants to
            -- match ... look inside tables for images, since we may be passing
            -- an array of image as a single param
            local match_image = find_order(function(x)
                if Image.is_Image(x) then
                    return x
                else
                    return nil
                end
            end, call_args)

            -- set any string options before any args so they can't be
            -- overridden
            if vips_lib.vips_object_set_from_string(vop:vobject(),
                string_options) ~= 0 then
                error("unable to call " .. name .. "\n" .. verror.get())
            end

            local n = 0
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, INPUT) ~= 0 and
                        band(flags, REQUIRED) ~= 0 and
                        band(flags, DEPRECATED) == 0 then
                    n = n + 1

                    if not vop:set(arguments[i].name, flags,
                        match_image, call_args[n]) then
                        error("unable to call " .. name .. "\n" .. verror.get())
                    end
                end
            end

            if last_arg then
                local args_by_name = {}
                for i = 1, #arguments do
                    args_by_name[arguments[i].name] = arguments[i].flags
                end

                for k, v in pairs(last_arg) do
                    if not vop:set(k, args_by_name[k], match_image, v) then
                        error("unable to call " .. name .. "\n" ..
                                verror.get())
                    end
                end
            end

            local vop2 = vips_lib.vips_cache_operation_build(vop)
            if vop2 == nil then
                error("unable to call " .. name .. "\n" .. verror.get())
            end
            vop2:new()
            vop = vop2

            local result = {}
            local vob = vop:vobject()
            n = 1
            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and
                        band(flags, REQUIRED) ~= 0 and
                        band(flags, DEPRECATED) == 0 then
                    result[n] = vob:get(arguments[i].name)
                    n = n + 1
                end

                -- MODIFY input args are returned .. this will get the copy we
                -- made above
                if band(flags, INPUT) ~= 0 and
                        band(flags, MODIFY) ~= 0 then
                    result[n] = vob:get(arguments[i].name)
                    n = n + 1
                end
            end

            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and
                        band(flags, REQUIRED) == 0 and
                        band(flags, DEPRECATED) == 0 then
                    result[n] = vob:get(arguments[i].name)
                    n = n + 1
                end
            end

            for i = 1, #arguments do
                local flags = arguments[i].flags

                if band(flags, OUTPUT) ~= 0 and
                        band(flags, DEPRECATED) ~= 0 then
                    result[n] = vob:get(arguments[i].name)
                    n = n + 1
                end
            end

            vips_lib.vips_object_unref_outputs(vop)

            return unpack(result)
        end
    }
}

voperation = ffi.metatype("VipsOperation", voperation_mt)
return voperation
