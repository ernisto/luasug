--// Packages
local types = require("../types.lua")
type pos = types.pos

local TokenStream = require("../Lexer/TokenStream.lua")

--// Parser
local Parser = setmetatable({}, TokenStream)
Parser.__index = Parser

function TokenStream:parse()
    
    setmetatable(self, Parser)
    local lastComment
    
    --// Methods
    function self:popChar(char: string?)
        
        local tok = self:peek("char")
        if not tok then return end
        if char and tok.char ~= char then return end
        
        self:advance()
        return tok
    end
    function self:popWord(word: string?)
        
        local tok = self:peek("word")
        if not tok then return end
        if word and tok.word ~= word then return end
        
        self:advance()
        return tok.word
    end
    function self:popOperator(operator: string?, isAssignment: boolean?)
        
        isAssignment = isAssignment or false
        
        local tok = self:peek("operator")
        if not tok then return end
        if operator and tok.operator ~= operator then return end
        if tok.isAssignment ~= isAssignment then return end
        
        self:advance()
        return tok
    end
    function self:popNumber()
        
        return self:popSome("dec_num", "hex_num", "bin_num")
    end
    function self:popString()
        
        return self:popSome("simple_str", "block_str")
    end
    
    function self:getLastComment()
        
        return lastComment
    end
    
    --// Override
    local advanceTokenStream = self.advance
    function self:advance()
        
        advanceTokenStream(self)
        
        local comment = self:pop("comment") -- recursive :advance()
        if comment then lastComment = comment end
    end
    
    --// End
    return self
end

--// End
return Parser