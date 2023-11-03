--// Packages
local types = require("../types.lua")
type range = types.range

local Lexer = require("init.lua")

--// Module
local Token = {}
Token.__index = Token

--// Factory
function Lexer:newToken(kind: string, size: number)
    return {
        kind = kind,
        start = self:pos(),
        final = self:pos() + size
    }
end
export type Token = {
    kind: string,
    start: number,
    final: number
}

--// Tokens

--+ --// Digit
export type Digit = Token & {
    integral: number?,
    fractional: number?,
    exponent: number?,
}

function Lexer:scanDigit()
    local integral = ""
    local fractional = ""
    local exponential = ""
    local size = 0

    if not self:checkChar(".") then
        self:next()
        size += 1

        repeat
            integral ..= self:pop()
            size += 1
        until not self:exists() or not self:checkDigit()
    end

    if self:checkChar(".") then
        self:next()
        size += 1

        repeat
            fractional ..= self:pop()
            size += 1
        until not self:exists() or not Lexer.checkDigit()
    end

    if self:checkChar("e") then
        self:next()
        size += 1

        repeat
            exponential ..= self:pop()
            size += 1
        until not self:exists() or not self:checkDigit()
    end

    local token = self:newToken("digit", size)
    token.integral = integral
    token.fractional = fractional
    token.exponent = exponential

    return token
end


--+ --// Identifier
export type Identifier = Token & {
    name: string
}

function Lexer:scanIdentifier()
    local name = ""

    repeat
        name ..= self:pop()
    until not self:exists() or not (self:scanAlpha() or self:scanChar("_"))

    local token = self:newToken("identifier", #name)
    token.name = name

    return token
end

--+ --// String
export type String = Token & {
    text: string
}

function Lexer:scanString()
    local initOperator = self:pop()
    local value = ""

    repeat
        if self:checkChar("\\") then
            local result, skip = self:checkEscape()

            value ..= result
            self:next(skip)
        else
            value ..= self:pop()
        end
    until self:checkChar(initOperator)

    local token = self:newToken("string", #value)
    token.text = value

    return token
end

--+ --// Operator
export type Operator = Token & {
    operator: string
}

function Lexer:scanOperator()
    local operator = self:checkOperator()

    self:next(#operator)

    local token = self:newToken("operator", #operator)
    token.operator = operator

    return token
end

--+ --// Char
export type Char = Token & {
    char: string
}

function Lexer:scanChar()
    local char = self:pop()

    local token = self:checkToken("char", 1)
    token.char = char

    return token
end



--// End
return Token