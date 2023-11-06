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
function Lexer:popEscape(): string?
    
    if not self:popChar("\\") then return end
    local escape = self:popChar()
    
    return if escape == "\\" then "\\"
        elseif escape == "t" then "\t"
        elseif escape == "n" then "\n"
        elseif escape == "a" then "\a"
        elseif escape == "b" then "\b"
        elseif escape == "f" then "\f"
        elseif escape == "r" then "\r"
        elseif escape == "v" then "\v"
        else escape
end
function Lexer:popWord(): string?
    
    local alpha = self:popAlpha() or self:popChar("_")
    if not alpha then return end
    
    local word = ""
    while alpha do
        
        word ..= alpha
        alpha = self:popAlpha() or self:popDigit() or self:popChar("_")
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
        isAssignment = self:popChar("=") ~= nil
    else
        
        op = self:popChar("=") or self:popChar(">") or self:popChar("<")
            or str == "->" or str == "=>"
            or str == "==" or str == "~="
            or str == ">=" or str == "<="
        and str
        
        if not op then return end
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
        digit = self:popDigit()
    end
    
    if self:popChar(".") then
        
        digit = self:popDigit()
        while digit do
            
            fractional ..= digit
            digit = self:popDigit()
        end
    end
    if #integral == 0 then return end
    
    if self:popChar("e") then
        
        exponentSign = if self:popChar("-") then -1 elseif self:popChar("+") then 1 else 1
        
        digit = self:popDigit()
        while digit do
            
            exponent ..= digit
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
function Lexer:scanBinNumber()  --TODO
end
function Lexer:scanHexNumber()  --TODO
end

function Lexer:scanSimpleString()
    
    local start = self:pos()
    
    local beg = self:popChar("'") or self:popChar('"')
    if not beg then return end
    
    local content = ""
    
    repeat
        local char = self:popEscape() or self:popChar()
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