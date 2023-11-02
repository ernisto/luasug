--// Packages
local types = require("../types.lua")
type pos = types.pos

local Parser = require("init.lua")

--// Module
local Node = {}
Node.__index = Node

--// Factory
function Parser:node(kind: string, start: pos)
    
    local node = setmetatable({
        final = self:getPos(),
        start = start,
        kind = kind,
    }, Node)
    
    --// End
    return node
end
export type Node = { kind: string, start: pos, final: pos }

--// End
return Node