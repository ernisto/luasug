--// Packages
local types = require("../types.lua")
type pos = types.pos

local TokenStream = require("../Lexer/TokenStream.lua")

--// Parser
local Parser = setmetatable({}, TokenStream)
Parser.__index = Parser

function TokenStream:parse()
    
    setmetatable(self, Parser)
    return self
end

--// Nodes
function Parser:expr_params()
    
    local start = self:getPos()
    
    local generics = self:type_params()
    local isValid = true
    local params = {}
    
    if self:popChar("(") then
        
        local param = self:expr_param()
        table.insert(params, param)
        
        while isValid and self:popChar(",") do
            
            param = self:expr_param() or self:report("param expected")
            table.insert(params, param)
            
            isValid = isValid and param and true
        end
        
        local _token = self:popChar(")") or self:report("')' expected")
        isValid = _token and isValid
    else
        
        if not generics then return end
    end
    
    --// Node
    local node = self:node("expr_tuple", start, isValid)
    self.generics = generics
    self.params = params
    
    return node
end
function Parser:expr_param()
    
    local start = self:getPos()
    local isVariadic = self:popOperator("...") or false
    local isValid = true
    
    local name = self:popWord()
    if not name and not isVariadic then return end
    
    local default
    local type
    
    if self:popChar(":") then
        
        type = self:type_expr() or self:report("type_expr expected")
        isValid = type and isValid
    end
    if self:popChar("=") then
        
        default = self:expr() or self:report("expr expected")
        isValid = default and isValid
    end
    
    --// Node
    local node = self:node("type_tuple", start, isValid)
    self.isVariadic = isVariadic
    self.default = default
    self.type = type
    self.name = name
    
    return node
end

function Parser:type_params()
    
    local start = self:getPos()
    local isValid = true
    local params = {}
    
    if self:popChar("<") then
        
        local param = self:type_param()
        table.insert(params, param)
        
        while isValid and self:popChar(",") do
            
            param = self:type_param() or self:report("param expected")
            table.insert(params, param)
            
            isValid = isValid and param and true
        end
        
        local _token = self:popChar(">") or self:report("'>' expected")
        isValid = _token and isValid
    end
    
    --// Node
    local node = self:node("type_tuple", start, isValid)
    self.params = params
    
    return node
end
function Parser:type_param()
    
    local start = self:getPos()
    local isVariadic = self:popOperator("...") or false
    local isValid = true
    
    local name = self:popWord()
    if not name and not isVariadic then return end
    
    local default
    local type
    
    if self:popChar(":") then
        
        type = self:type_expr() or self:report("type_expr expected")
        isValid = type and isValid
    end
    if self:popChar("=") then
        
        default = self:type_expr() or self:report("type_expr expected")
        isValid = default and isValid
    end
    
    --// Node
    local node = self:node("type_tuple", start, isValid)
    self.isVariadic = isVariadic
    self.default = default
    self.type = type
    self.name = name
    
    return node
end
function Parser:type_tuple()
    
    local start = self:getPos()
    if not self:popChar("<") then return end
    
    local isValid = true
    local fields = {}
    
    local field = self:type_tuple_field()
    table.insert(fields, field)
    
    while isValid and self:popChar(",") do
        
        field = self:type() or self:report("type expr expected")
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
function Parser:type_tuple_field()
    
    local rollback = self:rollback()
    local param = self:type_param()
    
    return if param and param.default then param else rollback():type_expr()
end

--// End
return Parser