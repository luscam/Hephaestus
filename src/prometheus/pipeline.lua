local config = require("config");
local Ast    = require("prometheus.ast");
local Enums  = require("prometheus.enums");
local util = require("prometheus.util");
local Parser = require("prometheus.parser");
local Unparser = require("prometheus.unparser");
local logger = require("logger");
local PRNG = require("prometheus.prng");

local NameGenerators = require("prometheus.namegenerators");
local Steps = require("prometheus.steps");

local lookupify = util.lookupify;
local LuaVersion = Enums.LuaVersion;
local AstKind = Ast.AstKind;

local isWindows = package and package.config and type(package.config) == "string" and package.config:sub(1,1) == "\\";
local function gettime()
	if isWindows then
		return os.clock();
	else
		return os.time();
	end
end

local Pipeline = {
	NameGenerators = NameGenerators;
	Steps = Steps;
	DefaultSettings = {
		LuaVersion = LuaVersion.LuaU;
		PrettyPrint = false;
		Seed = 0;
        SecretKey = "HephaestusDefaultKey"; 
		VarNamePrefix = "";
	}
}


function Pipeline:new(settings)
	local luaVersion = settings.luaVersion or settings.LuaVersion or Pipeline.DefaultSettings.LuaVersion;
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion 
			.. "\" is not recognised by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end
	
	local prettyPrint = settings.PrettyPrint or Pipeline.DefaultSettings.PrettyPrint;
	local prefix = settings.VarNamePrefix or Pipeline.DefaultSettings.VarNamePrefix;
	local seed = settings.Seed or 0;
    local secretKey = settings.SecretKey or Pipeline.DefaultSettings.SecretKey;
	
	local pipeline = {
		LuaVersion = luaVersion;
		PrettyPrint = prettyPrint;
		VarNamePrefix = prefix;
		Seed = seed;
        SecretKey = secretKey;
		parser = Parser:new({
			LuaVersion = luaVersion;
		});
		unparser = Unparser:new({
			LuaVersion = luaVersion;
			PrettyPrint = prettyPrint;
			Highlight = settings.Highlight;
		});
		namegenerator = Pipeline.NameGenerators.MangledShuffled;
		conventions = conventions;
		steps = {};
	}
	
	setmetatable(pipeline, self);
	self.__index = self;
	
	return pipeline;
end

function Pipeline:fromConfig(config)
	config = config or {};
	local pipeline = Pipeline:new({
		LuaVersion    = config.LuaVersion or LuaVersion.Lua51;
		PrettyPrint   = config.PrettyPrint or false;
		VarNamePrefix = config.VarNamePrefix or "";
		Seed          = config.Seed or 0;
        SecretKey     = config.SecretKey;
	});

	pipeline:setNameGenerator(config.NameGenerator or "MangledShuffled")

	local steps = config.Steps or {};
	for i, step in ipairs(steps) do
		if type(step.Name) ~= "string" then
			logger:error("Step.Name must be a String");
		end
		local constructor = pipeline.Steps[step.Name];
		if not constructor then
			logger:error(string.format("The Step \"%s\" was not found!", step.Name));
		end
		pipeline:addStep(constructor:new(step.Settings or {}));
	end

	return pipeline;
end

function Pipeline:addStep(step)
	table.insert(self.steps, step);
end

function Pipeline:resetSteps(step)
	self.steps = {};
end

function Pipeline:getSteps()
	return self.steps;
end

function Pipeline:setOption(name, value)
	assert(false, "TODO");
	if(Pipeline.DefaultSettings[name] ~= nil) then
		
	else
		logger:error(string.format("\"%s\" is not a valid setting"));
	end
end

function Pipeline:setLuaVersion(luaVersion)
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion 
			.. "\" is not recognised by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end
	
	self.parser = Parser:new({
		luaVersion = luaVersion;
	});
	self.unparser = Unparser:new({
		luaVersion = luaVersion;
	});
	self.conventions = conventions;
end

function Pipeline:getLuaVersion()
	return self.luaVersion;
end

function Pipeline:setNameGenerator(nameGenerator)
	if(type(nameGenerator) == "string") then
		nameGenerator = Pipeline.NameGenerators[nameGenerator];
	end
	
	if(type(nameGenerator) == "function" or type(nameGenerator) == "table") then
		self.namegenerator = nameGenerator;
		return;
	else
		logger:error("The Argument to Pipeline:setNameGenerator must be a valid NameGenerator function or function name e.g: \"mangled\"")
	end
end

function Pipeline:apply(code, filename)
	local startTime = gettime();
	filename = filename or "Anonymus Script";
	logger:info(string.format("Applying Obfuscation Pipeline to %s ...", filename));
	
    local finalSeed = self.SecretKey
    if self.Seed ~= 0 then
        finalSeed = finalSeed .. tostring(self.Seed)
    else
        finalSeed = finalSeed .. tostring(os.time())
    end

    logger:info("Initializing Secure Hephaestus PRNG with provided Secret Key...");
    local securePrng = PRNG:new(finalSeed)

    local originalRandom = math.random
    local originalRandomSeed = math.randomseed

    -- Safer hook for math.random to emulate standard Lua behavior precisely
    math.random = function(a, b)
        if a and b then
            return securePrng:random(a, b)
        elseif a then
            return securePrng:random(1, a)
        else
            return securePrng:next()
        end
    end
    
    math.randomseed = function(s)
        securePrng = PRNG:new(s)
    end

    local status, result = pcall(function()
        logger:info("Parsing ...");
        local parserStartTime = gettime();

        local sourceLen = string.len(code);
        local ast = self.parser:parse(code);

        local parserTimeDiff = gettime() - parserStartTime;
        logger:info(string.format("Parsing Done in %.2f seconds", parserTimeDiff));
        
        for i, step in ipairs(self.steps) do
            local stepStartTime = gettime();
            logger:info(string.format("Applying Step \"%s\" ...", step.Name or "Unnamed"));
            local newAst = step:apply(ast, self);
            if type(newAst) == "table" then
                ast = newAst;
            end
            logger:info(string.format("Step \"%s\" Done in %.2f seconds", step.Name or "Unnamed", gettime() - stepStartTime));
        end
        
        self:renameVariables(ast);
        
        code = self:unparse(ast);
        
        local timeDiff = gettime() - startTime;
        logger:info(string.format("Obfuscation Done in %.2f seconds", timeDiff));
        
        logger:info(string.format("Generated Code size is %.2f%% of the Source Code size", (string.len(code) / sourceLen)*100))
        return code
    end)

    math.random = originalRandom
    math.randomseed = originalRandomSeed

    if not status then
        error(result)
    end
	
	return result;
end

function Pipeline:unparse(ast)
	local startTime = gettime();
	logger:info("Generating Code ...");
	
	local unparsed = self.unparser:unparse(ast);
	
	local timeDiff = gettime() - startTime;
	logger:info(string.format("Code Generation Done in %.2f seconds", timeDiff));
	
	return unparsed;
end

function Pipeline:renameVariables(ast)
	local startTime = gettime();
	logger:info("Renaming Variables ...");
	
	
	local generatorFunction = self.namegenerator or Pipeline.NameGenerators.mangled;
	if(type(generatorFunction) == "table") then
		if (type(generatorFunction.prepare) == "function") then
			generatorFunction.prepare(ast);
		end
		generatorFunction = generatorFunction.generateName;
	end
	
	if not self.unparser:isValidIdentifier(self.VarNamePrefix) and #self.VarNamePrefix ~= 0 then
		logger:error(string.format("The Prefix \"%s\" is not a valid Identifier in %s", self.VarNamePrefix, self.LuaVersion));
	end

	local globalScope = ast.globalScope;
	globalScope:renameVariables({
		Keywords = self.conventions.Keywords;
		generateName = generatorFunction;
		prefix = self.VarNamePrefix;
	});
	
	local timeDiff = gettime() - startTime;
	logger:info(string.format("Renaming Done in %.2f seconds", timeDiff));
end

return Pipeline;