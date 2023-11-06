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
        
        local tok = self:pop("char")
        if not tok then return end
        if char and tok.char ~= char then return end
        
        self:advance()
        return tok
    end
    function self:popWord(word: string?)
        
        local tok = self:pop("word")
        if not tok then return end
        if word and tok.word ~= word then return end
        
        self:advance()
        return word
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
        
        repeat
            advanceTokenStream(self)
            
            local comment = self:pop("comment")
            if comment then lastComment = comment end
            
        until not comment
    end
    
    --// End
    return self
end

--// Nodes
function Parser:type_tuple_def()
    
    local start = self:pos()
    if not self:popChar("<") then return end
    
    local field = self:type_field_def()
    local fields = {field}
    local isValid = true
    
    while self:popChar(",") do
        
        field = self:type_field_def() or self:report("field expected")
        isValid = isValid and field and true
        table.insert(fields, field)
    end
    
    local _token = self:popChar(">") or self:report("'>' expected")
    isValid = _token and isValid
    
    --// Node
    local node = self:node("type_tuple_def", start, isValid)
    self.fields = fields
    
    return node
end
function Parser:type_field_def()
    
    local start = self:pos()
    local isVariadic = self:popOperator("...") ~= nil
    local isValid = true
    
    local name = self:popWord()
    if not name and not isVariadic then return end
    
    local default
    local type
    
    if self:popChar(":") then
        
        type = self:type_expr()
    end
    if self:popChar("=") then
        
        default = self:type_expr() or self:report("type expected")
        isValid = default and isValid
    end
    
    --// Node
    local node = self:node("type_field_def", start, isValid)
    self.isVariadic = isVariadic
    self.default = default
    self.type = type
    self.name = name
    
    return node
end
function Parser:type_tuple()
    
    local start = self:pos()
    if not self:popChar("<") then return end
    
    local isValid = true
    local fields = {}
    
    local field = self:type_field()
    table.insert(fields, field)
    
    while isValid and self:popChar(",") do
        
        field = self:type_field() or self:report("field or expr expected")
        table.insert(fields, field)
        
        isValid = isValid and field and true
    end
    
    local _token = self:popChar(">") or self:report("'>' expected")
    isValid = _token and isValid
    
    --// Node
    local node = self:node("type_tuple", start, isValid)
    self.fields = fields
    
    return node
end
function Parser:type_field()
    
    local rollback = self:rollback()
    local field = self:type_field_def()
    
    return if field and field.default then field else rollback():type_expr()
end

--// End
return Parser