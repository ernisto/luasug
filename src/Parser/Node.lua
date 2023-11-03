--// Packages
local types = require("../types.lua")
type pos = types.pos

local Parser = require("init.lua")

--// Module
local Node = {}
Node.__index = Node

--// Factory
function Parser:node(kind: string, start: pos, isValid: boolean)
    
    local node = setmetatable({
        final = self:getPos(),
        isValid = isValid,
        start = start,
        kind = kind,
        root = nil,
    }, Node)
    
    --// End
    return node
end

--// Methods
function Node:receive(visitor)
    
    visitor:visitNode(self)
end

--// End
return Node