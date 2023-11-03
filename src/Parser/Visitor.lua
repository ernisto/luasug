--// Module
local Visitor = {}
Visitor.__index = Visitor

--// Constructor
function Visitor.new()
    
    return setmetatable({}, Visitor)
end

--// End
return Visitor