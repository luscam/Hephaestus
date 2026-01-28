local util = require("prometheus.util");

local Hephaestus = {};

-- Prefixes that look professional and organized
local prefixes = {
    "v",   "var", "val",  -- Variables
    "p",   "param",       -- Parameters
    "hw",  "sys",         -- System/Hardware feel
    "idx", "ptr",         -- Pointers/Indices
    "dat", "buf",         -- Data
    "x",   "y",   "z",    -- Math
    "f",   "fn",          -- Functions
    "tbl", "arr",         -- Tables
}

local usedNames = {}

function Hephaestus.generateName(id, scope, originalName)
    local maxRetries = 100
    
    -- Try to generate a unique name
    for i = 1, maxRetries do
        local prefix = prefixes[math.random(1, #prefixes)]
        local number = math.random(10, 9999)
        local name = prefix .. tostring(number)
        
        -- Check if this specific name string has been used in this scope or globally tracked
        -- Note: scope:renameVariables handles scope collision, but we want visual uniqueness
        if not usedNames[name] then
            usedNames[name] = true
            return name
        end
    end
    
    -- Fallback if collision hell happens (rare)
    return "v" .. tostring(id) .. "_" .. tostring(math.random(1000, 9999))
end

-- Reset tracker when pipeline starts
function Hephaestus.prepare(ast)
    usedNames = {}
end

return Hephaestus;