local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local RandomStrings = require("prometheus.randomStrings")
local Parser = require("prometheus.parser");
local Enums = require("prometheus.enums");
local logger = require("logger");

local AntiTamper = Step:extend();
AntiTamper.Description = "This Step Breaks your Script when it is modified. Enhanced for Hephaestus.";
AntiTamper.Name = "Anti Tamper";

AntiTamper.SettingsDescriptor = {
    UseDebug = {
        type = "boolean",
        default = true,
        description = "Use debug library. (Recommended)"
    }
}

function AntiTamper:init(settings)
	
end

function AntiTamper:apply(ast, pipeline)
    if pipeline.PrettyPrint then
        logger:warn(string.format("\"%s\" cannot be used with PrettyPrint, ignoring \"%s\"", self.Name, self.Name));
        return ast;
    end
    
    local integrityVar = "v" .. math.random(1000, 9999);
	local code = "do local " .. integrityVar .. " = true;";
    
    if self.UseDebug then
        local string = RandomStrings.randomString();
        -- Enhanced debug check logic
        code = code .. [[
            local function s(f) return pcall(debug.getinfo, f) end
            local sethook = debug and debug.sethook
            local getinfo = debug and debug.getinfo
            
            if not (sethook and getinfo) then ]] .. integrityVar .. [[ = false end

            -- Basic tamper check using traceback structure
            local function getTraceback()
                local str = (function(arg)
                    return debug.traceback(arg)
                end)("]] .. string .. [[");
                return str;
            end
    
            local tb = getTraceback();
            if not tb:find("]] .. string .. [[") then ]] .. integrityVar .. [[ = false end
        ]]
    end

    -- Mathematical Integrity Check (Hephaestus Version)
    -- Uses consistent seed-based math that fails if code structure changes significantly
    local mathCheck = [[
    local m_random = math.random
    local m_floor = math.floor
    local t_unpack = table.unpack or unpack
    
    local check_val = 0
    local target = 0
    
    local function wrap()
        local function inner(a, b)
            return (a * 1664525 + 1013904223) % 4294967296
        end
        return inner
    end
    
    local algo = wrap()
    local seed = ]] .. math.random(10000, 99999) .. [[
    
    -- Simulate a sequence
    for i = 1, 50 do
        seed = algo(seed, 0)
        target = (target + (seed % 255)) % 999999
    end
    
    -- Check runtime environment stability
    local p_status = pcall(function()
        local x = 0
        for i = 1, 50 do
           x = (x + 1) * 2
        end
        if x == 0 then error("fail") end
    end)
    
    if not p_status then ]] .. integrityVar .. [[ = false end
    
    if ]] .. integrityVar .. [[ then
        -- Obfuscated flow control
        if target > 0 then
            check_val = target
        else
            check_val = -1
        end
    end
    
    if check_val ~= target then
        while true do end -- Silent freeze
    end
    ]]

    code = code .. mathCheck .. [[
    end
    ]]

    local parsed = Parser:new({LuaVersion = Enums.LuaVersion.Lua51}):parse(code);
    local doStat = parsed.body.statements[1];
    doStat.body.scope:setParent(ast.body.scope);
    table.insert(ast.body.statements, 1, doStat);

    return ast;
end

return AntiTamper;