--// Packages
local Parser = require("./Parser/init.lua")
local Lexer = require("./Lexer/init.lua")

--// Run
local tokenStream = Lexer.tokenize([[
local a = 10
]])
local ast = Parser.parse(tokenStream)

print(ast)