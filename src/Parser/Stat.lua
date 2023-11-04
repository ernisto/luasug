--// Packages
local Node = require("Node.lua")
local Parser = require("init.lua")
    require("Expr.lua")

--// Nodes
function Parser:stat()


end

function Parser:def()
    
    local start = self:getPos()
    local comment = self:getLastComment()
    local decorators = {}
    
    repeat
        local decorator = self:decorator()
        if not decorator then break end
        
        table.insert(decorators, decorator)
    until false
    
    local level = self:popWord("local") or self:popWord("export")
    local ctx = { level = level, decorators = decorators, about = comment.content, start = start }
    
    return self:function_def(ctx)
        or self:method_def(ctx)
        or self:signal_def(ctx)
        or self:type_def(ctx)
        or self:var_def(ctx)
end
function Parser:function_def(ctx)
    
    if not self:popWord("function") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    local params = self:expr_params() or self:report("params expected")
    local body = self:body()
    local _token = self:popWord("end") or self:report("'end' expected")
    
    --// Node
    local node = self:node("type_def", ctx.start, name and _token and true)
    node.decorators = ctx.decorators
    node.about = ctx.about
    node.level = ctx.level
    node.params = params
    node.body = body
    node.name = name
    
    return node
end
function Parser:signal_def(ctx)
    
    if not self:popWord("signal") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    local params = self:expr_params() or self:report("params expected")
    
    --// Node
    local node = self:node("signal_def", ctx.start, name and params and true)
    node.decorators = ctx.decorators
    node.about = ctx.about
    node.level = ctx.level
    node.params = params
    node.type = type
    node.name = name
    
    return node
end
function Parser:type_def(ctx)
    
    if not self:popWord("type") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    local generics = self:type_params()
    local _token = self:popChar("=") or self:report("'=' expected")
    local type = self:type_expr()
    
    --// Node
    local node = self:node("type_def", ctx.start, name and _token and type and true)
    node.decorators = ctx.decorators
    node.generics = generics
    node.about = ctx.about
    node.level = ctx.level
    node.type = type
    node.name = name
    
    return node
end
function Parser:var_def(ctx)
    
    if not ctx.level then return end
    
    local binding = self:expr_param() or self:report("identifier expected")
    local bindings = {binding}
    
    while self:popChar(",") do
        
        binding = self:expr_param() or self:report("identifier expected")
        table.insert(bindings, binding)
    end
    
    --// Node
    local node = self:node("var_def", ctx.start, binding and true)
    node.decorators = ctx.decorators
    node.bindings = bindings
    node.about = ctx.about
    node.level = ctx.level
    
    return node
end

function Parser:if_stat()
    
    local start = self:getPos()
    if not self:popWord("if") then return end
    
    local clauses = {}
    local isValid = true
    
    repeat
        local clause = self:expr() or self:report(`expr expected`)
        local _token = self:popWord("then") or self:report(`'then' expected`)
        local body = self:body() or self:report(`body expected`)
        
        table.insert(clauses, { clause = clause, body = body })
        isValid = isValid and clause and _token and body and true
        
    until not self:popWord("elseif")
    
    local elseBody = if self:popWord("else") then self:body() else nil
    local _token = self:popWord("end") or self:report(`'end' expected`)
    
    --// Node
    local node = self:node("if", start, _token and isValid)
    node.elseBody = elseBody
    node.clauses = clauses
    
    return node
end
function Parser:for_stat()
end
function Parser:while_stat()
end
function Parser:repeat_stat()
end

--// End
return Parser