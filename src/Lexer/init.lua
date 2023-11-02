--// Packages
local types = require("../types.lua")
type range = types.range
type pos = types.pos

local Token = require("Token.lua")
type Token = Token.Token

--// Module
local Lexer = {}
Lexer.__index = Lexer

--// Function
function Lexer.new(source: string)
    
    local self = setmetatable({}, Lexer)
    
    local chars = source:split()
    local index = 0
    
    function self:scan()
    end
    
    --// End
    return self
end

--// End
return Lexer