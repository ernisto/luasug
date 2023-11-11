--// Packages
local Node = require("Node.lua")

local Parser = require("init.lua")
    require("Type.lua")

--// Nodes
function Parser:expr_tuple_def()
    
    local start = self:pos()
    local generics = self:type_tuple_def()
    local isValid = true
    local fields = {}
    
    if not self:popChar("(") then return end
    
    local field = self:expr_field_def()
    table.insert(fields, field)
    
    while isValid and self:popChar(",") do
        
        field = self:expr_field_def() or self:report("field expected")
        table.insert(fields, field)
        
        isValid = field and isValid
    end
    
    local _token = self:popChar(")") or self:report("')' expected")
    isValid = _token and isValid
    
    --// Node
    local node = self:node("expr_tuple_def", start, isValid)
    node.generics = generics
    node.fields = fields or error("cavalo")
    
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
    if self:popOperator("=", true) then
        
        default = self:expr() or self:report("expr expected")
        isValid = default and isValid
    end
    
    --// Node
    local node = self:node("expr_field_def", start, isValid)
    node.isVariadic = isVariadic
    node.default = default
    node.type = type
    node.name = name
    
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
    node.generics = generics
    node.fields = fields
    
    return node
end
function Parser:expr_field()
    
    local rollback = self:backpoint()
    local param = self:expr_field_def()
    
    return if param and param.default then param else rollback():expr()
end
function Parser:expr(maxLevel: number?)
    
    maxLevel = maxLevel or 11
    
    local base = self:prefix(maxLevel) or self:atom()
    if not base then return end
    
    repeat
        local op = self:suffix(base, maxLevel)
        if op then base = op end
        
    until not op
    
    repeat
        local op = self:mid(base, maxLevel)
        if op then base = op end
        
    until not op
    
    return base
end

function Parser:atom()
    
    return self:null()
        or self:func()
        or self:bool()
        or self:array()
        or self:table()
        or self:number()
        or self:string()
        or self:var_read()
        or self:arrow_func()
        or self:expr_tuple()
end
function Parser:null()
    
    local start = self:pos()
    if not self:popWord("nil") then return end
    
    --// Node
    local node = self:node("null", start, true)
    return node
end
function Parser:bool()
    
    local start = self:pos()
    local word = self:popWord("true") or self:popWord("false")
    if not word then return end
    
    --// Node
    local node = self:node("bool", start, true)
    node.value = word == "true"
    
    return node
end
function Parser:number()
    
    local number = self:popNumber()
    if not number then return end
    
    --// Node
    local node = self:node("number", number.start, true)
    node.value = tonumber(number.rawContent, number.radix)
    node.integral = tonumber(number.integral)
    node.fractional = tonumber(number.fractional)
    node.exponent = tonumber(number.exponent)
    node.type = number.type
    
    return node
end
function Parser:string()
    
    local str = self:popString()
    if not str then return end
    
    --// Node
    local node = self:node("string", str.start, true)
    node.content = str.content
    
    return node
end
function Parser:table() -- TODO
end
function Parser:array()
    
    local start = self:pos()
    if not self:popChar("[") then return end
    
    local value = self:expr()
    local values = {value}
    local isValid = true
    
    while isValid and self:popChar(",") do
        
        value = self:expr() or self:report("expr expected")
        table.insert(values, value)
        
        isValid = value and isValid
    end
    
    local _tok = self:popChar("]") or self:report("']' expected")
    isValid = _tok and isValid
    
    --// Node
    local node = self:node("array", start, isValid)
    node.values = values
    
    return node
end
function Parser:func()
    
    local start = self:pos()
    if not self:popWord("function") then return end
    
    local params = self:expr_tuple_def()
    local resultType
    
    if self:popOperator("->") then
        
        resultType = self:type_expr()
    end
    local body = self:body()
    local _tok = self:popWord("end") or self:report("'end' expected")
    
    --// Node
    local node = self:node("func", start, params and _tok and true)
    node.resultType = resultType
    node.params = params
    node.body = body
    
    return node
end
function Parser:arrow_func()
    
    local start = self:pos()
    local params = self:expr_tuple_def()
    if not params then return end
    
    if not self:popOperator("=>") then return end
    local result = self:expr()
    
    --// Node
    local node = self:node("arrow_func", start, params and true)
    node.result = result
    node.params = params
    
    return node
end
function Parser:var_read()
    
    local start = self:pos()
    
    local name = self:popWord()
    if not name then return end
    
    --// Node
    local node = self:node("var_read", start, true)
    node.name = name
    
    return node
end

function Parser:suffix(base, maxLevel: number)
    
    return maxLevel >= 1 and (self:prop_read(base) or self:index_read(base) or self:callment(base) or self:method_callment(base))
end
function Parser:prop_read(base)
    
    local start = self:pos()
    if not self:popChar(".") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    
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
    
    local start = self:pos()
    local params = self:expr_tuple()
    if not params then return end
    
    --// End
    local node = self:node("callment", start, true)
    node.params = params
    node.base = base
    
    return node
end
function Parser:method_callment(base)
    
    local start = self:pos()
    if not self:popChar(":") then return end
    
    local index = self:popWord() or self:report("identifier expected")
    local params = self:expr_tuple() or self:report("'(' expected")
    
    --// End
    local node = self:node("method_callment", start, index and params and true)
    node.params = params
    node.index = index
    node.base = base
    
    return node
end

function Parser:prefix(maxLevel: number)
    
    return maxLevel >= 2 and(self:unpack_op() or self:len_op())
        or maxLevel >= 4 and(self:unm_op() or self:not_op())
end
function Parser:unpack_op() -- TODO
end
function Parser:len_op()    -- TODO
end
function Parser:not_op()    -- TODO

    local start = self:pos()
    local word = self:popWord("not")
    if not word then return end

    --// Node
    local node = self:node("not_op", start, true)
    node.base = self:expr() or self:report("expr expected")

    return node
end
function Parser:unm_op()    -- TODO
end

function Parser:mid(base, maxLevel: number)
    
    return maxLevel >= 3 and self:pow_op(base)  -- right associative op idk bcuz
        or maxLevel > 5 and(self:mul_op(base) or self:div_op(base) or self:fdiv_op(base) or self:mod_op(base))
        or maxLevel > 6 and(self:add_op(base) or self:sub_op(base))
        or maxLevel >= 7 and self:concat_op(base)  -- right associative op idk bcuz
        or maxLevel > 8 and(self:eq_op(base) or self:ne_op(base) or self:lt_op(base) or self:gt_op(base) or self:le_op(base) or self:ge_op(base))
        or maxLevel > 9 and self:and_op(base)
        or maxLevel > 10 and self:or_op(base)
end
function Parser:pow_op(base)
    
    local start = self:pos()
    if not self:popOperator("^") then return end
    
    local operand = self:expr(3) or self:report("expr expected")
    
    --// Node
    local node = self:node("pow_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:mul_op(base)
    
    local start = self:pos()
    if not self:popOperator("*") then return end
    
    local operand = self:expr(5) or self:report("expr expected")
    
    --// End
    local node = self:node("mul_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:div_op(base)
    
    local start = self:pos()
    if not self:popOperator("/") then return end
    
    local operand = self:expr(5) or self:report("expr expected")
    
    --// Node
    local node = self:node("div_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:fdiv_op(base)
    
    local start = self:pos()
    if not self:popOperator("//") then return end
    
    local operand = self:expr(5) or self:report("expr expected")
    
    --// Node
    local node = self:node("fdiv_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:mod_op(base)
    
    local start = self:pos()
    if not self:popOperator("%") then return end
    
    local operand = self:expr(5) or self:report("expr expected")
    
    --// Node
    local node = self:node("mod_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:add_op(base)
    
    local start = self:pos()
    if not self:popOperator("+") then return end
    
    local operand = self:expr(6) or self:report("expr expected")
    
    --// End
    local node = self:node("add_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:sub_op(base)
    
    local start = self:pos()
    if not self:popOperator("-") then return end
    
    local operand = self:expr(6) or self:report("expr expected")
    
    --// Node
    local node = self:node("sub_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:concat_op(base)
    
    local start = self:pos()
    if not self:popOperator("..") then return end
    
    local operand = self:expr(7) or self:report("expr expected")
    
    --// Node
    local node = self:node("concat_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:eq_op(base)
    
    local start = self:pos()
    if not self:popOperator("==") then return end
    
    local operand = self:expr(8) or self:report("expr expected")
    
    --// End
    local node = self:node("eq_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:ne_op(base)
    
    local start = self:pos()
    if not self:popOperator("~=") then return end
    
    local operand = self:expr(8) or self:report("expr expected")
    
    --// End
    local node = self:node("ne_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:lt_op(base)
    
    local start = self:pos()
    if not self:popChar("<") then return end
    
    local operand = self:expr(8) or self:report("expr expected")
    
    --// End
    local node = self:node("lt_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:le_op(base)
    
    local start = self:pos()
    if not self:popOperator("<=") then return end
    
    local operand = self:expr(8) or self:report("expr expected")
    
    --// End
    local node = self:node("le_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:gt_op(base)
    
    local start = self:pos()
    if not self:popChar(">") then return end
    
    local operand = self:expr(8) or self:report("expr expected")
    
    --// End
    local node = self:node("gt_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:ge_op(base)
    
    local start = self:pos()
    if not self:popOperator(">=") then return end
    
    local operand = self:expr(8) or self:report("expr expected")
    
    --// End
    local node = self:node("ge_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:and_op(base)
    
    local start = self:pos()
    if not self:popWord("and") then return end
    
    local operand = self:expr(9) or self:report("expr expected")
    
    --// End
    local node = self:node("and_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end
function Parser:or_op(base)
    
    local start = self:pos()
    if not self:popWord("or") then return end
    
    local operand = self:expr(10) or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, operand and true)
    node.operand = operand
    node.base = base
    
    return node
end

--// End
return Parser