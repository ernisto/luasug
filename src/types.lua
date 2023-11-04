--// Module
local types = {}

--// Types
export type pos = { absolute: number, column: number, line: number }
local pos = {}
types.pos = pos

function pos:__tostring()
	
	return `pos{"{"} line: {self.line}, column: {self.column}, absolute: {self.absolute} {"}"}`
end

--// End
export type range = { min: pos, max: pos }
return types