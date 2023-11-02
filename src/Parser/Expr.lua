--// Packages
local Parser = require("init.lua")
local Node = require("Node.lua")
type Node = Node.Node

--// Nodes
function Parser:expr()
end
function Parser:biop()
end
function Parser:atom()
end

--// End
return Parser