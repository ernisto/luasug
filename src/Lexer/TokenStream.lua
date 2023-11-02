--// Packages
local Lexer = require("init.lua")
type Lexer = Lexer.Lexer

--// Module
local TokenStream = {}
TokenStream.__index = TokenStream

--// Factory
function Lexer:tokenize(): TokenStream
    
    local tokens = {}
    local index = 0
    
    --// Instance
    local self = setmetatable({}, TokenStream)
    
    --// Methods
    function self:getPos(): pos
    end
    function self:read(): Token
        
        return tokens[index]
    end
    function self:next()
        
        index += 1
    end
    
    function self:setPos(pos: pos)
    end
    function self:insert(init: pos, text: string)
    end
    function self:remove(range: range)
    end
    
    --// End
    return self
end

--// End
return TokenStream