--// Packages
local types = require("types.lua")
type pos = types.pos

local TokenStream = require("../Lexer/Token.lua")
type TokenStream = TokenStream.TokenStream

--// Module
local Parser = {}
Parser.__index = Parser

--// Factory
function TokenStream:parse()
    
    local self = setmetatable({}, Parser)
    
    return self
end

--// End
return Parser