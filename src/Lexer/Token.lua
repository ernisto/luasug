--// Packages
local types = require("../types.lua")
type pos = types.pos

local Lexer = require("init.lua")

--// Module
local Token = {}
Token.__index = Token

--// Factory
function Lexer:newToken(kind: string, start: pos)
    
    local token = setmetatable({
        kind = kind,
        start = start,
        final = self:pos()
    }, Token)
    
    self:skipBlank()
    return token
end

--// Utils
function Lexer:popWord(): string?
    
    local alpha = self:popAlpha() or self:popChar("_")
    if not alpha then return end
    
    local word = ""
    while alpha do
        
        word ..= alpha
        alpha = self:popAlphanum() or self:popChar("_")
    end
    
    return word
end
function Lexer:popBlock(): string?
    
    local rollback = self:backpoint()
    if not self:popChar("[") then return end
    
    local ident = ""
    while self:popChar("=") do ident ..= "=" end
    
    if not self:popChar("[") then rollback(); return end
    return self:popUntil(`]{ident}]`)
end

--// Tokens
function Lexer:scanToken()
    
    return self:scanWord()
        or self:scanBinNumber() or self:scanHexNumber() or self:scanDecNumber()
        or self:scanSimpleString() or self:scanBlockString()
        or self:scanComment()
        or self:scanOperator()
        or self:scanChar()
end
function Lexer:scanChar()
    
    local start = self:pos()
    local char = self:popChar()
    if not char then return end
    
    --// Token
    local token = self:newToken("char", start)
    token.char = char
    
    return token
end
function Lexer:scanWord()
    
    local start = self:pos()
    local word = self:popWord()
    if not word then return end
    
    --// Token
    local token = self:newToken("word", start)
    token.word = word
    
    return token
end
function Lexer:scanComment()
    
    local start = self:pos()
    if not self:popSeq("--") then return end
    
    local content = self:popBlock() or self:popUntil("\n")
    
    --// Token
    local token = self:newToken("comment", start)
    token.content = content
    
    return token
end
function Lexer:scanOperator()
    
    local start = self:pos()
    
    local str = self:peek(2)
    local isAssignment = false
    local op = str:match("[%+%-%*%/%^%%]")
        or str == "//" or str == ".." and str
    
    if op then
        
        self:advance(#op)
        
        if op == ".." and self:popChar(".") then op = "..."
        elseif self:popChar("=") then isAssignment = true end
    else
        
        op = self:popChar("=") or self:popChar(">") or self:popChar("<")
            or str == "->" or str == "=>"
            or str == "==" or str == "~="
            or str == ">=" or str == "<="
        and str
        
        if not op then return end
        
        isAssignment = op == "="
        self:advance(#op)
    end
    
    local token = self:newToken("operator", start)
    token.isAssignment = isAssignment
    token.operator = op
    
    return token
end

function Lexer:scanDecNumber()
    
    local start = self:pos()
    
    local fractional = ""
    local integral = ""
    local exponent = ""
    
    local sign = if self:popChar("-") then -1 elseif self:popChar("+") then 1 else 1
    local exponentSign
    
    local digit = self:popDigit()
    while digit do
        
        integral ..= digit
        
        while self:popChar("_") do end
        digit = self:popDigit()
    end
    
    while self:popChar("_") do end
    if self:popChar(".") then
        
        while self:popChar("_") do end
        digit = self:popDigit()
        
        while digit do
            
            fractional ..= digit
            
            while self:popChar("_") do end
            digit = self:popDigit()
        end
    end
    if #integral == 0 then return end
    
    while self:popChar("_") do end
    if self:popChar("e") then
        
        exponentSign = if self:popChar("-") then -1 elseif self:popChar("+") then 1 else 1
        
        while self:popChar("_") do end
        digit = self:popDigit()
        
        while digit do
            
            exponent ..= digit
            
            while self:popChar("_") do end
            digit = self:popDigit()
        end
    end
    
    local type = self:popWord()
    
    --// Token
    local token = self:newToken("dec_num", start)
    token.fractional = tonumber(fractional)
    token.exponent = tonumber(exponent)
    token.integral = tonumber(integral)
    token.exponentSign = exponentSign
    token.sign = sign
    token.type = type
    token.radix = 10
    
    return token
end
function Lexer:scanBinNumber()
    
    local start = self:pos()
    if not self:popSeq("0b") then return end
    
    local integral = ""
    
    local digit = self:popDigit(2)
    while digit do
        
        integral ..= digit
        
        while self:popChar("_") do end
        digit = self:popDigit(2)
    end
    
    local token = self:newToken("bin_num", start)
    token.integral = tonumber(integral, 2)
    
    return token
end
function Lexer:scanHexNumber()
    
    local start = self:pos()
    if not self:popSeq("0x") then return end
    
    local integral = ""
    
    local digit = self:popDigit(16)
    while digit do
        
        integral ..= digit
        
        while self:popChar("_") do end
        digit = self:popDigit(16)
    end
    
    local token = self:newToken("hex_num", start)
    token.integral = tonumber(integral, 16)
    
    return token
end

function Lexer:scanSimpleString()
    
    local start = self:pos()
    
    local beg = self:popChar("'") or self:popChar('"')
    if not beg then return end
    
    local content = ""
    
    repeat
        local char = self:popChar()
        if not char then break end
        
        content ..= char
        
    until char == beg
    
    local token = self:newToken("simple_str", start)
    token.content = content
    token.beg = beg
    
    return token
end
function Lexer:scanBlockString()
    
    local start = self:pos()
    local content = self:popBlock()
    if not content then return end
    
    --// Token
    local token = self:newToken("block_str", start)
    token.content = content
    
    return token
end

function Lexer:scanInterpBegString()    --TODO
end
function Lexer:scanInterpMidString()    --TODO
end
function Lexer:scanInterpEndString()    --TODO
end

--// End
return Token