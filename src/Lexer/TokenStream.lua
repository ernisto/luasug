--// Packages
local types = require("../types.lua")

local Lexer = require("init.lua")
    require("Token.lua")

--// Module
local TokenStream = {}
TokenStream.__index = TokenStream

--// Factory
function Lexer:tokenize()
    
    local diagnostics = {}
    local tokens = {}
    local index = 0
    
    repeat
        local tok = self:scanToken()
        table.insert(tokens, tok)
    until not tok
    
    --// Instance
    local self = setmetatable({ diagnostics = diagnostics, tokens = tokens }, TokenStream)
    
    --// Methods
    function self:report(message: string)
        
        local diagnostic = { message = message, begin = self:pos(), final = (self:peek() or tokens[#tokens]).final }
        table.insert(diagnostics, diagnostic)
    end
    function self:pos()
        
        return (self:peek() or tokens[#tokens]).start
    end
    
    function self:backpoint()
        
        local backIndex = index
        return function()
            
            index = backIndex
            return self
        end
    end
    function self:advance()
        
        index += 1
    end
    
    function self:peek(kind: string?)
        
        local tok = tokens[index]
        if not tok then return end
        if kind and tok.kind ~= kind then return end
        
        return tok
    end
    function self:peekSome(...: string)
        
        local tok = self:peek()
        for _,kind in {...} do
            
            if tok.kind == kind then return tok end
        end
    end
    
    function self:pop(kind: string?)
        
        local tok = self:peek(kind)
        if tok then self:advance() return tok end
    end
    function self:popSome(...: string)
        
        local tok = self:peekSome(...)
        if tok then self:advance() return tok end
    end
    
    --// Edit
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