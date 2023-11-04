--// Packages
local Lexer = require("Lexer/init.lua")
    require("Parser/init.lua")
        require("Parser/Stat.lua")

--// Run
local a = Lexer.new("10"):scanDecNumber()
print(a)

local lexer = Lexer.new([[
local a = 10
]])
local tokenStream = lexer:tokenize()
print(tokenStream.tokens)

local parser = tokenStream:parse()
local ast = parser:body()

print(ast)