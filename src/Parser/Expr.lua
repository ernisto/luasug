--// Packages
local Parser = require("init.lua")
local Node = require("Node.lua")

--// Nodes
function Parser:expr()
    
    local base = self:atom()
    return if base then self:biop(base) else base
end
function Parser:expr_tuple()
    
    local start = self:getPos()
    if not self:popChar("(") then return end
    
    local isValid = true
    local fields = {}
    
    local field = self:expr_tuple_field()
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
    self.fields = fields
    
    return node
end
function Parser:expr_tuple_field()
    
    local rollback = self:rollback()
    local param = self:expr_param()
    
    return if param and param.default then param else rollback():expr()
end

function Parser:atom()
    
    return self:number()
        or self:string()
        or self:boolean()
        or self:read_var()
end
function Parser:null_literal()
    
    local start = self:getPos()
    if not self:popWord("nil") then return end
    
    --// Node
    local node = self:node("null_literal", start, true)
    return node
end
function Parser:number_literal()
    
    local start = self:getPos()
    
    local number = self:popNumber()
    if not number then return end
    
    --// Node
    local node = self:node("number", start, true)
    node.decimal = number.decimal or 0
    node.fractional = number.fractional or 0
    node.exponent = number.exponent or 0
    node.type = number.type
    node.value = (node.decimal + node.fractional)*10^node.exponent
    
    return node
end
function Parser:string_literal()
    
    local start = self:getPos()
    local content = self:popString()
    if not content then return end
    
    --// Node
    local node = self:node("string", start, true)
    node.content = content
    
    return node
end
function Parser:boolean_literal()
    
    local start = self:getPos()
    local word = self:popWord("true") or self:popWord("false")
    if not word then return end
    
    --// Node
    local node = self:node("boolean", start, true)
    node.value = word
    
    return node
end
function Parser:read_var()
    
    local start = self:getPos()
    
    local name = self:popWord()
    if not name then return end
    
    --// Node
    local node = self:node("read_var", start, true)
    node.name = name
    
    return node
end

function Parser:prefix()
    
    return self:len_op()
        or self:not_op()
        or self:unm_op()
end
function Parser:len_op()
end
function Parser:not_op()
end
function Parser:unm_op()
end

function Parser:suffix(base)
    
    return self:read_prop_op(base)
        or self:read_index_op(base)
        or self:call_op(base)
        or self:call_method_op(base)
        or self:type_check_op(base)
end
function Parser:read_prop_op(base)
    
    local start = self:getPos()
    if not self:popChar(".") then return end
    
    local name = self:popIdentifier()
    
    --// End
    local node = self:node("or_op", start, name and true)
    node.name = name
    node.base = base
    
    return node
end
function Parser:read_index_op(base)
    
    local start = self:getPos()
    if not self:popChar("[") then return end
    
    local index = self:expr() or self:report("expr expected")
    local _token = self:popChar("]") or self:report("']' expected")
    
    --// End
    local node = self:node("or_op", start, index and _token and true)
    node.index = index
    node.base = base
    
    return node
end
function Parser:call_op(base)
    
    local start = self:getPos()
    local params = self:expr_send()
    
    --// End
    local node = self:node("or_op", start, true)
    node.params = params
    node.base = base
    
    return node
end
function Parser:call_method_op(base)
    
    local start = self:getPos()
    if not self:popChar(":") then return end
    
    local index = self:popIdentifier() or self:report("identifier expected")
    local params = self:expr_send() or self:report("'(' expected")
    
    --// End
    local node = self:node("or_op", start, index and params and true)
    node.params = params
    node.index = index
    node.base = base
    
    return node
end
function Parser:type_check_op(base)
    
    local start = self:getPos()
    if not self:popKeyword("is") then return end
    
    local type = self:type_expr() or self:report("type_expr expected")
    
    --// End
    local node = self:node("or_op", start, type and true)
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
    
    local start = self:getPos()
    if not self:popKeyword("or") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:and_op(base)
    
    local start = self:getPos()
    if not self:popKeyword("and") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("and_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:eq_op(base)
    
    local start = self:getPos()
    if not self:popOperator("==") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:ne_op(base)
    
    local start = self:getPos()
    if not self:popOperator("~=") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end

function Parser:lt_op(base)
    
    local start = self:getPos()
    if not self:popChar("<") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:le_op(base)
    
    local start = self:getPos()
    if not self:popOperator("<=") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:gt_op(base)
    
    local start = self:getPos()
    if not self:popChar(">") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:ge_op(base)
    
    local start = self:getPos()
    if not self:popOperator(">=") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("or_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end

function Parser:add_op(base)
    
    local start = self:getPos()
    if not self:popChar("+") then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// End
    local node = self:node("add_op", start, value and true)
    node.value = value
    node.base = base
    
    return node
end
function Parser:mul_op(base)
    
    local start = self:getPos()
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