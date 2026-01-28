local bit = require("prometheus.bit").bit
local floor = math.floor

local PRNG = {}
PRNG.__index = PRNG

-- Helper function for unsigned 32-bit multiplication
local function dmul(a, b)
    -- Ensure inputs are treated as unsigned 32-bit integers
    if a < 0 then a = a + 4294967296 end
    if b < 0 then b = b + 4294967296 end

    local ah = floor(a / 65536)
    local al = a % 65536
    local bh = floor(b / 65536)
    local bl = b % 65536
    
    -- Calculate middle term, modulo 65536 to keep it within 16 bits
    -- This effectively handles the lower 16 bits of the high-word product
    local h = (ah * bl + al * bh) % 65536
    
    -- Combine results and ensure 32-bit unsigned wrapping
    return (h * 65536 + al * bl) % 4294967296
end

local function hashString(str)
    local h = 2166136261
    for i = 1, #str do
        h = bit.bxor(h, string.byte(str, i))
        if h < 0 then h = h + 4294967296 end -- Normalize to unsigned
        h = dmul(h, 16777619)
    end
    return h
end

function PRNG:new(seed)
    local self = setmetatable({}, PRNG)
    if type(seed) == "string" then
        self.state = hashString(seed)
    else
        self.state = (seed or os.time()) % 4294967296
    end
    return self
end

function PRNG:next()
    local z = (self.state + 0x9E3779B9) % 4294967296
    self.state = z
    
    local r = bit.rshift(z, 15)
    z = bit.bxor(z, r)
    if z < 0 then z = z + 4294967296 end -- Normalize
    
    z = dmul(z, 0x85EBCA6B)
    
    r = bit.rshift(z, 13)
    z = bit.bxor(z, r)
    if z < 0 then z = z + 4294967296 end -- Normalize
    
    z = dmul(z, 0xC2B2AE35)
    
    r = bit.rshift(z, 16)
    z = bit.bxor(z, r)
    if z < 0 then z = z + 4294967296 end -- Normalize
    
    -- Result is strictly in [0, 1) because z < 2^32
    return z / 4294967296
end

function PRNG:random(a, b)
    local r = self:next()
    if not a then
        return r
    elseif not b then
        return floor(r * a) + 1
    else
        return floor(r * (b - a + 1)) + a
    end
end

return PRNG