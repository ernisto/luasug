--// Packages
local types = require("../types.lua")

local Lexer = require("init.lua")
    require("Token.lua")

--// Module
local TokenStream = {}
TokenStream.__index = TokenStream

--// Factory
function Lexer:tokenize()
    
    local lexer = self
    local diagnostics = {}
    local tokens = {}
    local index = 1
    
    repeat
        local tok = self:scanToken()
        table.insert(tokens, tok)
    until not tok
    
    --// Instance
    local self = setmetatable({ diagnostics = diagnostics, tokens = tokens }, TokenStream)
    
    local Diagnostic = {}
    Diagnostic.__index = Diagnostic
    
    function Diagnostic:printError(showTraceback: boolean?)
        
        local fullLine = lexer:sub(self.begin.absolute - self.begin.column + 1, self.final.absolute)
        print(
            fullLine..'\n'
            ..string.rep(" ", self.begin.column - 2)
            ..string.rep("^", self.final.absolute - self.begin.absolute + 1)
            .." "..self.message
        )
        if showTraceback then print(self.traceback) end
    end
    
    --// Methods
    function self:printTokens()
        
        local formatedTokens = {}
        
        for index, token in tokens do
            
            formatedTokens[index] = tostring(token)
        end
        
        return "[\n\t"..table.concat(formatedTokens, ",\n\t").."\n]"
    end
    
    function self:report(message: string)
        
        local badTok = self:peek() or tokens[#tokens]
        local diagnostic = setmetatable({ traceback = debug.traceback("", 2):sub(2), message = `{message}, got {badTok}`, begin = badTok.start, final = badTok.final }, Diagnostic)
        table.insert(diagnostics, diagnostic)
    end
    function self:pos(offset: number?)
        
        if offset == -1 then
            
            local lastTok = tokens[index-1] or tokens[1]
            return lastTok.final
        else
            
            local tok = (self:peek() or tokens[#tokens])
            return tok.start
        end
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
        if not tok then return end
        
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