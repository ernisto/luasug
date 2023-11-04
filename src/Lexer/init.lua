--// Packages
local types = require("../types.lua")
type range = types.range
type pos = types.pos

--// Module
local Lexer = {}
Lexer.__index = Lexer

--// Function
function Lexer.new(source: string)
	
	local self = setmetatable({}, Lexer)
	local chars = source:split()
	local index = 0
	
	function self:popChar(expectedChar: string?): string
		
		local char = chars[index]
		
		if not char or char == "" then return end
		if expectedChar and char ~= expectedChar then return end
		
		index += 1
		return char
	end
	function self:popSeq(sequence: string): string?
		
		if self:peek(#sequence) ~= sequence then return end
		
		index += #sequence
		return sequence
	end
	function self:popAlpha(): string
		
		local char = self:peek()
		if not char then return end
		if char:lower() == char:upper() then return end
		
		self:advance()
		return char
	end
	function self:popDigit(): string
		
		local char = chars[index]
		if not tonumber(char) then return end
		
		index += 1
		return char
	end
	
	function self:peek(length: number): string
		
		return if length then table.concat(chars, index, index + length - 1)
			else chars[index]
	end
	function self:advance(length: number)
		
		index += length
	end
	function self:pos()
		
		return index
	end
	
	function self:skipBlank(): boolean
		
		local char = chars[index]
		
		while char == " " or char == "\n" or char == "\t" do
			
			index += 1
			char = chars[index]
		end
	end
	function self:backpoint(): () -> ()
		
		local backIndex = index
		return function()
			
			index = backIndex
			return self
		end
	end
	
	--// End
	self:skipBlank()
	return self
end

--// End
return Lexer