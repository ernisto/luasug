--// Packages
local Lexer = require("init.lua")
type Lexer = Lexer.Lexer

--// Module
local TokenStream = {}
TokenStream.__index = TokenStream

--// Factory
function Lexer:tokenize(): TokenStream
    
    local tokens = {}
    local index = 0

    --// Tokenize
    repeat
        --// Digit
        if self:checkDigit() or (self:checkChar(".") and self:checkDigit()) then
            table.insert(tokens, self:scanDigit())

            continue
        end

        --// Identifier
        if self:checkAlpha() then
            table.insert(tokens, self:scanIdentifier())

            continue
        end

        --// String
        if self:checkChar("\"") or self:checkChar("'") then
            table.insert(tokens, self:scanString())

            continue
        end

        --// Operator
        if self:checkOperator() then
            table.insert(tokens, self:scanOperator())

            continue
        end

        --// Flag Comment
        if self:checkSequence("--[[") then
            self:next(4)

            while not self:checkSequence("]]") do
                self:next()
            end

            self:next(2)

            continue
        end

        --// Skip
        if self:checkSkip() then
            self:next()

            continue
        end

        --// Char
        table.insert(tokens, self:scanChar())

    until not self:next()
    
    --// Instance
    local self = setmetatable({}, TokenStream)
    
    --// Methods
    function self:getPos(): pos
    end
    function self:read(): Token
        
        return tokens[index]
    end
    function self:next()
        
        index += 1
    end
    
    function self:setPos(pos: pos)
    end
    function self:insert(init: pos, text: string)
    end
    function self:remove(range: range)
    end
    
    --// End
    return self
end

--// End
return TokenStream