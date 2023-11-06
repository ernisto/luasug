--// Packages
local Parser = require("init.lua")
local Node = require("Node.lua")

--// Nodes
function Parser:expr(maxLevel: number?)
    
    maxLevel = maxLevel or 99
    
    local base = if maxLevel >= 3 then self:prefix() or self:atom() else self:atom()
    if not base then return end
    
    if maxLevel < 4 then return base end
    
    repeat
        local op = self:biop(maxLevel)
        
    until false

    return base
end

function Parser:expr_tuple_def()
    
    local start = self:pos()
    local generics = self:type_tuple_def()
    local isValid = true
    local fields = {}
    
    if self:popChar("(") then
        
        local field = self:expr_field_def()
        table.insert(fields, field)
        
        while isValid and self:popChar(",") do
            
            field = self:expr_field_def() or self:report("field expected")
            table.insert(fields, field)
            
            isValid = isValid and field and true
        end
        
        local _token = self:popChar(")") or self:report("')' expected")
        isValid = _token and isValid
    else
        
        if not generics then return end
    end
    
    --// Node
    local node = self:node("expr_tuple_def", start, isValid)
    self.generics = generics
    self.fields = fields
    
    return node
end
function Parser:expr_field_def()
    
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
        
        default = self:expr() or self:report("expr expected")
        isValid = default and isValid
    end
    
    --// Node
    local node = self:node("expr_field_def", start, isValid)
    self.isVariadic = isVariadic
    self.default = default
    self.type = type
    self.name = name
    
    return node
end
function Parser:expr_tuple()
    
    local start = self:pos()
    local generics = self:type_tuple()
    
    if not self:popChar("(") then return end
    
    local isValid = true
    local fields = {}
    
    local field = self:expr_field()
    table.insert(fields, field)
    
    while isValid and self:popChar(",") do
        
        field = self:expr() or self:report("expr expected")
        table.insert(fields, field)
        
        isValid = isValid and field and true
    end
    
    local _token = self:popChar(")") or self:report("')' expected")
    isValid = _token and isValid
    
    --// Node
    local node = self:node("expr_tuple", start, isValid)
    self.generics = generics
    self.fields = fields
    
    return node
end
function Parser:expr_field()
    
    local rollback = self:rollback()
    local param = self:expr_field_def()
    
    return if param and param.default then param else rollback():expr()
end

function Parser:atom()
    
    return self:null()
        or self:number()
        or self:string()
        or self:boolean()
        or self:var_read()
        or self:expr_tuple()
end
function Parser:null()
    
    local start = self:pos()
    if not self:popWord("nil") then return end
    
    --// Node
    local node = self:node("null", start, true)
    return node
end
function Parser:number()
    
    local number = self:popNumber()
    if not number then return end
    
    --// Node
    local node = self:node("number", number.start, true)
    node.decimal = number.decimal or 0
    node.fractional = number.fractional or 0
    node.exponent = number.exponent or 0
    node.type = number.type
    node.value = (node.decimal + node.fractional)*10^node.exponent
    
    return node
end
function Parser:string()
    
    local content = self:popString()
    if not content then return end
    
    --// Node
    local node = self:node("string", content.start, true)
    node.content = content
    
    return node
end
function Parser:boolean()
    
    local word = self:popWord("true") or self:popWord("false")
    if not word then return end
    
    --// Node
    local node = self:node("boolean", word.start, true)
    node.value = word == "true"
    
    return node
end
function Parser:var_read()
    
    local name = self:popWord()
    if not name then return end
    
    --// Node
    local node = self:node("var_read", name.start, true)
    node.name = name
    
    return node
end

function Parser:prefix()
    
    return self:unpack_op()
        or self:len_op()
        or self:not_op()
        or self:unm_op()
end
function Parser:unpack_op() -- TODO
end
function Parser:len_op()    -- TODO
end
function Parser:not_op()    -- TODO
end
function Parser:unm_op()    -- TODO
end

function Parser:suffix(base)
    
    return self:prop_read(base)
        or self:index_read(base)
        or self:callment(base)
        or self:method_callment(base)
        or self:type_check(base)
end
function Parser:prop_read(base)
    
    local start = self:pos()
    if not self:popChar(".") then return end
    
    local name = self:popIdentifier()
    
    --// End
    local node = self:node("prop_read", start, name and true)
    node.name = name
    node.base = base
    
    return node
end
function Parser:index_read(base)
    
    local start = self:pos()
    if not self:popChar("[") then return end
    
    local index = self:expr() or self:report("expr expected")
    local _token = self:popChar("]") or self:report("']' expected")
    
    --// End
    local node = self:node("index_read", start, index and _token and true)
    node.index = index
    node.base = base
    
    return node
end
function Parser:callment(base)
    
    local params = self:expr_tuple()
    if not params then return end
    
    --// End
    local node = self:node("callment", params.start, true)
    node.params = params
    node.base = base
    
    return node
end
function Parser:method_callment(base)
    
    local start = self:pos()
    if not self:popChar(":") then return end
    
    local index = self:popIdentifier() or self:report("identifier expected")
    local params = self:expr_tuple() or self:report("'(' expected")
    
    --// End
    local node = self:node("method_callment", start, index and params and true)
    node.params = params
    node.index = index
    node.base = base
    
    return node
end
function Parser:type_check(base)
    
    local start = self:pos()
    if not self:popKeyword("is") then return end
    
    local type = self:type_expr() or self:report("type_expr expected")
    
    --// End
    local node = self:node("type_check", start, type and true)
    node.type = type
    node.base = base
    
    return node
end

function Parser:mid(base)
    
    return self:or_op(base)
        or self:and_op(base)
        or self:eq_op(base) or self:ne_op(base) or self:lt_op(base) or self:gt_op(base) or self:le(base) or self:ge(base)
        
        -- or self:concat_op(base)
        -- or self:add_op(base) or self:sub_op(base)
        -- or self:mul_op(base) or self:div_op(base) or self:fdiv_op(base) or self:mod_op(base)
        -- or self:un_op(base)
        -- or self:pow_op(base)
end
function Parser:or_op(base)
    
    local start = self:pos()
    if not self:popKeyword("or") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:and_op(base)
    
    local start = self:pos()
    if not self:popKeyword("and") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("and_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:eq_op(base)
    
    local start = self:pos()
    if not self:popOperator("==") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("eq_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:ne_op(base)
    
    local start = self:pos()
    if not self:popOperator("~=") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("ne_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end

function Parser:lt_op(base)
    
    local start = self:pos()
    if not self:popChar("<") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("lt_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:le_op(base)
    
    local start = self:pos()
    if not self:popOperator("<=") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("le_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:gt_op(base)
    
    local start = self:pos()
    if not self:popChar(">") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("gt_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:ge_op(base)
    
    local start = self:pos()
    if not self:popOperator(">=") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("ge_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end

function Parser:add_op(base)
    
    local start = self:pos()
    if not self:popChar("+") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("add_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:mul_op(base)
    
    local start = self:pos()
    if not self:popChar("+") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("mul_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end

--// End
return Parser