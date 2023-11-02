--// Packages
local types = require("../types.lua")
type range = types.range

local Lexer = require("init.lua")

--// Module
local Token = {}
Token.__index = Token

--// Factory
function Lexer:token()
end
export type Token = {
    range: range,
    kind: string,
}

--// Tokens
function Lexer:digit()
end
export type Digit = Token & {
    integral: number?,
    fractional: number?,
    exponent: number?,
}

function Lexer:identifier()
end
export type Identifier = Token & {
    name: string
}

--// End
return Token