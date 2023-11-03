--// Packages
local types = require("../types.lua")
type range = types.range
type pos = types.pos

local Token = require("Token.lua")
type Token = Token.Token

--// Module
local Lexer = {}
Lexer.__index = Lexer

--// Function
function Lexer.new(source: string)
    
    local self = setmetatable({}, Lexer)
    
    local chars = source:split()
    local index = 0

    function self:pos(): number
        return index
    end

    function self:next(skip: number): boolean
        index += skip or 1

        if index > #chars then
            return false
        end

        return true
    end

    function self:pop(): string
        index += 1
        return chars[index - 1]
    end

    function self:exists(): boolean
        return chars[index] ~= nil
    end
    
    function self:checkChar(objChar: string): boolean
        return chars[index] == objChar
    end

    function self:checkSequence(sequence: string): boolean
        local sequenceChars = sequence:split("")
    
        for i=index, #sequence do
            if chars[i] ~= sequenceChars[i - index + 1] then
                return false
            end
        end
    
        return true
    end

    function self:checkAlpha(): boolean
        return chars[index]:lower() ~= chars[index]:upper()
    end

    function self:checkDigit(): boolean
        return typeof(tonumber(chars[index])) == "number"
    end

    function self:checkEscape(): (string, number)
        return ({
            ["a"] = "\a",
            ["b"] = "\b",
            ["f"] = "\f",
            ["n"] = "\n",
            ["r"] = "\r",
            ["t"] = "\t",
            ["v"] = "\v",
            ["\""] = "\"",
            ["\\"] = "\\",
            ["'"] = "'",
        })[chars[index]] or chars[index], 1
    end
    
    function self:checkSkip(): boolean
        local list = {
            ["a"] = "\a",
            ["b"] = "\b",
            ["f"] = "\f",
            ["n"] = "\n",
            ["r"] = "\r",
            ["t"] = "\t",
            ["v"] = "\v",
        }
    
        return not not list[chars[index]]
    end

    function self:checkOperator(): string?
        local operators = {
            "+", "-", "*", "/", "^", "%", ">", "<", "==", "~=", ">=",
            "<=", "=>", "->", "+=", "-=", "*=", "/=", "^=", "%="
        }

        return operators [
            table.find(operators, chars[index]) 
            or table.find(operators, chars[index]..chars[index+1])
        ]
    end
    
    --// End
    return self
end

--// End
return Lexer