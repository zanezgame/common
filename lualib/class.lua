--
-- $id: class.lua O $
--

local type = type
local rawset = rawset
local setmetatable = setmetatable

local trace_count = 0
local tracebacks = setmetatable({}, {__mode = "k"})

local function class(classname, super)
    local cls = {}

    cls.classname = classname
    cls.class = cls
    cls.__index = cls

    if super then
        -- copy super method 
        for key, value in pairs(super) do
            if type(value) == "function" and key ~= "ctor" then
                cls[key] = value
            end
        end
        
        cls.super = super
    end

    function cls.new(...)
        local self = setmetatable({}, cls)
        local function create(cls, ...)
            if cls.super then
                create(cls.super, ...)
            end
            if cls.ctor then
                cls.ctor(self, ...)
            end
        end
        create(cls, ...)
        
        -- debug
        trace_count = trace_count + 1
        tracebacks[self] = trace_count

        return self
    end

    return cls
end

return class
