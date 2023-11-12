--// Packages
local Node = require("Node.lua")
local Parser = require("init.lua")
    require("Type.lua")
    require("Expr.lua")

--// Nodes
function Parser:body(...: string)
    
    local enders = {...}
    local start = self:pos()
    
    local isValid = false
    local stats = {}
    
    repeat
        local word = self:peek("word").word
        if word and table.find(enders, word) then isValid = true break end
        
        local stat = self:stat()
        table.insert(stats, stat)
        
    until not stat or stat.kind == "return_stat" or stat.kind == "break_stat" or stat.kind == "continue_stat"
    
    if not isValid then self:report(`'{table.concat(enders, "' or '")}' expected`) end
    
    --// Node
    local node = self:node("body", start, isValid)
    node.stats = stats
    
    return node
end
function Parser:stat()
    
    local regular = self:def_stat()
        or self:final_stat()
        or self:control_stat()
    
    if regular then return regular end
    
    local base = self:expr(1)
    if base.kind == "callment" or base.kind == "method_callment" then
        
        return base
    else
        
        return self:assignment(base) or self:report("'=' expected")
    end
end
function Parser:assignment(base)
    
    local start = self:pos()
    local operator = self:popOperator(nil, true)
    if not operator then return end
    
    local value = self:expr() or self:report("expr expected")
    
    --// Node
    local node = self:node("assignment")
    node.operator = operator
    node.value = value
    node.base = base
    
    return node
end

function Parser:final_stat()

    return self:return_stat()
        or self:continue_stat()
        or self:break_stat()
end
function Parser:return_stat()
    
    local start = self:pos()
    if not self:popWord("return") then return end
    
    local isValid = true
    local result = self:expr()
    local results = {}
    
    while result and self:popChar(",") do
        
        result = self:expr() or self:report("expr expected")
        table.insert(results, result)
        
        isValid = result and isValid
    end
    
    --// Node
    local node = self:node("return_stat", start, isValid)
    node.results = results
    
    return node
end
function Parser:break_stat()
    
    local start = self:pos()
    if not self:popWord("break") then return end
    
    local label = self:popWord()
    
    --// Node
    local node = self:node("break_stat", start, true)
    node.label = label
    
    return node
end
function Parser:continue_stat()
    
    local start = self:pos()
    if not self:popWord("continue") then return end
    
    local label = self:popWord()
    
    --// Node
    local node = self:node("continue_stat", start, true)
    node.label = label
    
    return node
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
function Parser:def_stat()
    
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
    local params = self:expr_tuple_def() or self:report("'(' expected")
    local body = self:body("end") self:popWord("end")
    
    --// Node
    local node = self:node("function_def", ctx.start, name and body and params and true)
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
    local body = self:body("end") self:popWord("end")
    
    --// Node
    local node = self:node("method_def", ctx.start, name and _tok1 and type and _tok2 and true)
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
    node.name = name
    
    return node
end
function Parser:type_def(ctx)
    
    if not self:popWord("type") then return end
    
    local name = self:popWord() or self:report("identifier expected")
    local generics = self:type_tuple_def()
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
    
    local binding = self:expr_field_def() or self:report("identifier expected")
    local bindings = {binding}
    
    while self:popChar(",") do
        
        binding = self:expr_field_def() or self:report("identifier expected")
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

function Parser:control_stat()
    
    return self:do_stat()
        or self:if_stat()
        or self:while_stat()
        or self:repeat_stat()
        or self:fornum_stat()
        or self:foreach_stat()
end
function Parser:do_stat()
    
    local start = self:pos()
    if not self:popWord("do") then return end
    
    local body = self:body("end") self:popWord("end")
    
    --// Node
    local node = self:node("do_stat", start, true)
    node.body = body
    
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
        local body = self:body("elseif", "else", "end")
        
        table.insert(clauses, { clause = clause, body = body })
        isValid = isValid and clause and _token and body and true
        
    until not self:popWord("elseif")
    
    local elseBody = if self:popWord("else") then self:body("else") else nil
    self:popWord("end")
    
    --// Node
    local node = self:node("if", start, isValid)
    node.elseBody = elseBody
    node.clauses = clauses
    
    return node
end
function Parser:while_stat()
    
    local start = self:pos()
    if not self:popWord("while") then return end
    
    local isValid = true
    local label
    
    if self:popChar(":") then
        
        label = self:popWord() or self:report("identifier expected")
        isValid = label and isValid
    end
    
    local clause = self:expr() or self:report("expr expected")
    local _tok1 = self:popWord("do") or self:report("'do' expected")
    
    local body = self:body("end") self:popWord("end")
    
    --// Node
    local node = self:node("while_stat", start, clause and _tok1 and isValid)
    node.clause = clause
    node.label = label
    node.body = body
    
    return node
end
function Parser:repeat_stat()
    
    local start = self:pos()
    if not self:popWord("repeat") then return end
    
    local isValid = true
    local clause
    local label
    
    if self:popChar(":") then
        
        label = self:popWord() or self:report("identifier expected")
        isValid = label and isValid
    end
    
    local body = self:body("until", "end")
    local elseBody
    
    if self:popWord("until") then
        
        clause = self:expr() or self:report("expr expected")
        isValid = clause and isValid
        
        if self:popWord("else") then
            
            elseBody = self:body("end")
            isValid = self:popWord("end") and true
        end
        
    elseif not self:popWord("end") then
        
        self:report("'end' or 'until' expected")
        isValid = false
    end
    
    --// Node
    local node = self:node("repeat_stat", start, isValid)
    node.elseBody = elseBody
    node.clause = clause
    node.label = label
    node.body = body
    
    return node
end
function Parser:fornum_stat()
    
    local rollback = self:backpoint()
    local start = self:pos()
    if not self:popWord("for") then return end
    
    local isValid = true
    local label
    
    if self:popChar(":") then
        
        label = self:popWord() or self:report("identifier expected")
        isValid = label and isValid
    end
    
    local binding = self:expr_field_def() or self:report("identifier expected")
    if not self:popOperator("=", true) then rollback() return end
    
    local begin = self:expr() or self:report("expr expected")
    local sep1 = self:popChar(",") or self:report("',' expected")
    local final = self:expr() or self:report("expr expected")
    local sep2 = self:popChar(",")
    local step = if sep2 then self:expr() or self:report("expr expected") else nil
    
    local _tok2 = self:popWord("do") or self:report("'do' expected")
    local body = self:body("end") self:popWord("end")
    
    --// Node
    local node = self:node("fornum_stat", start, binding and begin and sep1 and final and (not sep2 or step) and isValid)
    node.binding = binding
    node.label = label
    node.begin = begin
    node.final = final
    node.step = step
    node.body = body
    
    return node
end
function Parser:foreach_stat()
    
    local start = self:pos()
    if not self:popWord("for") then return end
    
    local isValid = true
    local label
    
    if self:popChar(":") then
        
        label = self:popWord() or self:report("identifier expected")
        isValid = label and isValid
    end
    
    local binding = self:expr_field_def() or self:report("identifier expected")
    local bindings = {binding}
    
    while self:popChar(",") do
        
        binding = self:expr_field_def() or self:report("identifier expected")
        table.insert(bindings, binding)
        
        isValid = binding and isValid
    end
    
    local _tok1 = self:popWord("in") or self:report("'in' expected")
    local param = self:expr() or self:report("expr expected")
    local params = {param}
    
    while self:popChar(",") do
        
        param = self:expr_field_def() or self:report("identifier expected")
        table.insert(params, param)
        
        isValid = param and isValid
    end
    
    local _tok2 = self:popWord("do") or self:report("'do' expected")
    local body = self:body("end") self:popWord("end")
    
    --// Node
    local node = self:node("foreach_stat", start, binding and param and _tok1 and _tok2 and isValid)
    node.bindings = bindings
    node.params = params
    node.label = label
    node.body = body
    
    return node
end

--// End
return Parser