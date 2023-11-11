--// Packages
local Node = require("Node.lua")
local Parser = require("init.lua")
    require("Expr.lua")

--// Nodes
function Parser:body()
    
    local start = self:pos()
    local stats = {}
    
    repeat
        local stat = self:stat()
        table.insert(stats, stat)
        
    until not stat
    
    --// Node
    local node = self:node("body", start, true)
    node.stats = stats
    
    return node
end

function Parser:stat()
    
    return self:def()
        or self:if_stat()
end
function Parser:decorator()
    
    local start = self:pos()
    if not self:popChar("@") then return end
    
    local expr = self:expr(1) or self:report("expr expected")
    
    --// Node
    local node = self:node("decorator", start, expr and true)
    node.origin = expr
    
    return node
end
function Parser:def()
    
    local start = self:pos()
    local comment = self:getLastComment()
    local decorators = {}
    
    repeat
        local decorator = self:decorator()
        table.insert(decorators, decorator)
        
    until not decorator
    
    local level = self:popWord("local") or self:popWord("export")
    local ctx = { level = level, decorators = decorators, about = comment and comment.content, start = start }
    
    return self:function_def(ctx)
        or self:method_def(ctx)
        or self:signal_def(ctx)
        or self:type_def(ctx)
        or self:var_def(ctx)
end

function Parser:function_def(ctx)
    
    if not self:popWord("function") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    local params = self:expr_tuple_def() or self:report("params expected")
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
function Parser:method_def(ctx)
    
    if not self:popWord("method") then return end
    
    local _tok1 = self:popChar("(") or self:report("'(' expected")
    local target = self:type_expr() or self:report("type expected")
    local _tok2 = self:popChar(")") or self:report("')' expected")
    
    local name = self:popWord() or self:report("identifier expected")
    local params = self:expr_tuple_def() or self:report("params expected")
    local body = self:body()
    local _tok3 = self:popWord("end") or self:report("'end' expected")
    
    --// Node
    local node = self:node("type_def", ctx.start, name and _tok1 and type and _tok2 and _tok3 and true)
    node.decorators = ctx.decorators
    node.about = ctx.about
    node.level = ctx.level
    node.params = params
    node.target = target
    node.body = body
    node.name = name
    
    return node
end
function Parser:signal_def(ctx)
    
    if not self:popWord("signal") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    local params = self:expr_tuple_def() or self:report("params expected")
    
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
    
    local binding = self:expr_field() or self:report("identifier expected")
    local bindings = {binding}
    
    while self:popChar(",") do
        
        binding = self:expr_field() or self:report("identifier expected")
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
    
    local start = self:pos()
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