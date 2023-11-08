--// Packages
local Lexer = require("Lexer/init.lua")
    require("Parser/init.lua")
        require("Parser/Stat.lua")

--// Run
local lexer = Lexer.new([[local a = 10]])
local tokenStream = lexer:tokenize()
local parser = tokenStream:parse()
local ast = parser:body()

print(ast)