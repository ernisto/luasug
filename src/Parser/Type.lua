--// Packages
local Parser = require("init.lua")

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
    node.fields = fields
    
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
    if self:popOperator("=", true) then
        
        default = self:type_expr() or self:report("type expected")
        isValid = default and isValid
    end
    
    --// Node
    local node = self:node("type_field_def", start, isValid)
    node.isVariadic = isVariadic
    node.default = default
    node.type = type
    node.name = name
    
    return node
end
function Parser:type_tuple()
    
    local start = self:pos()
    if not self:popChar("<") then return end
    
    local isValid = true
    local fields = {}
    
    local field = self:type_field()
    table.insert(fields, field)
    
    while self:popChar(",") do
        
        field = self:type_field() or self:report("field or expr expected")
        table.insert(fields, field)
        
        isValid = isValid and field and true
    end
    
    local _token = self:popChar(">") or self:report("'>' expected")
    isValid = _token and isValid
    
    --// Node
    local node = self:node("type_tuple", start, isValid)
    node.fields = fields
    
    return node
end
function Parser:type_field()
    
    local rollback = self:backpoint()
    local field = self:type_field_def()
    
    return if field and field.default then field else rollback():type_expr()
end
function Parser:type_expr(maxLevel: number?)
    
    maxLevel = maxLevel or 6
    
    local base = self:type_prefix(maxLevel) or self:type_atom()
    if not base then return end
    
    repeat
        local op = self:type_suffix(base, maxLevel)
        if op then base = op end
        
    until not op
    
    self:type_data(base, maxLevel)
    
    repeat
        local op = self:type_mid(base, maxLevel)
        if op then base = self:type_data(op, maxLevel) end
        
    until not op
    
    return base
end

function Parser:type_data(node, maxLevel: number)
    
    if maxLevel > 3 then
        
        node.generics = self:type_tuple()
    end
    if maxLevel > 3 then
        
        local length, isValid = self:length_params()
        if length then
            
            node.length = if length[2] then { min = length[1], max = length[2] } else { max = length[1] }
            node.isValid = isValid and node.isValid
        end
    end
    if maxLevel > 6 then
        
        node.isOptional = self:popChar("?") ~= nil
    end
    
    return node
end
function Parser:length_params()
    
    if not self:popChar("[") then return end
    
    local param = self:expr()
    local params = {param}
    local isValid = true
    
    while self:popChar(",") do
        
        param = self:expr() or self:report("expr expected")
        table.insert(params, param)
        
        isValid = param and isValid
    end
    
    local _tok = self:popChar("]") or self:report("']' expected")
    
    --// Node
    return params, _tok and isValid
end

function Parser:type_atom()
    
    return self:null()
        or self:table()
        or self:string()
        or self:var_read()
        or self:func_type()
end
function Parser:func_type()
    
    local start = self:pos()
    local params = self:expr_tuple_def()
    if not params then return end
    
    if not self:popOperator("->") then return end
    local result = self:type_expr() or self:expr_tuple_def() or self:report("type expected")
    
    --// Node
    local node = self:node("func_type", start, params and true)
    node.result = result
    node.params = params
    
    return node
end

function Parser:type_suffix(base, maxLevel: number)
    
    return maxLevel >= 1 and self:prop_read(base)
end

function Parser:type_prefix(maxLevel: number)
    
    return maxLevel >= 2 and self:not_type_op()
end
function Parser:not_type_op()
    
    local start = self:pos()
    if not self:popChar("!") then return end
    
    local base = self:type_expr(2) or self:report("type expected")
    
    --// Node
    local node = self:node("not_type_op", start, base and true)
    node.base = base
    
    return node
end

function Parser:type_mid(base, maxLevel: number)
    
    return maxLevel > 5 and self:and_type_op(base)
        or maxLevel > 6 and self:or_type_op(base)
end
function Parser:and_type_op(base)
    
    local start = self:pos()
    if not self:popChar("&") then return end
    
    local operand = self:type_expr(5) or self:report("type expected")
    
    --// Node
    local node = self:node("and_type_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:or_type_op(base)
    
    local start = self:pos()
    if not self:popChar("|") then return end
    
    local operand = self:type_expr(6) or self:report("type expected")
    
    --// Node
    local node = self:node("or_type_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end

--// End
return Parser