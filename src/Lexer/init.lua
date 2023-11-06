--// Packages
local types = require("../types.lua")
local pos = types.pos
type pos = types.pos

--// Module
local Lexer = {}
Lexer.__index = Lexer

--// Function
function Lexer.new(source: string)
	
	local self = setmetatable({}, Lexer)
	local chars = source:split("")
	
	local lineStart = 1
	local lines = 1
	local index = 1
	
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
		
		index += 1
		return char
	end
	function self:popDigit(radix: number?): string
		
		local char = chars[index]
		if not tonumber(char, radix) then return end
		
		index += 1
		return char
	end
	function self:popAlphanum(): string
		
		return self:popDigit(10 + 26)
	end
	
	function self:peek(length: number): string
		
		return if length then table.concat(chars, index, index + length - 1)
			else chars[index]
	end
	function self:advance(length: number)
		
		index += length
	end
	function self:backpoint(): () -> ()
		
		local backIndex = index
		return function()
			
			index = backIndex
			return self
		end
	end
	function self:pos(): pos
		
		return setmetatable({ absolute = index, column = index - lineStart + 1, line = lines }, pos)
	end
	
	function self:skipBlank()
		
		local char = chars[index]
		
		while char == " " or char == "\n" or char == "\t" do
			
			if char == "\n" then
				
				lineStart = index
				lines += 1
			end
			
			index += 1
			char = chars[index]
		end
	end
	function self:popUntil(ender: string): string?
		
		local nextEndChar = ender:sub(1, 1)
		local endMatchGoal = #ender
		local endMatchCount = 0
		
		local content = ""
		
		while true do
			
			local char = self:popChar()
			if not char then return content end
			
			if char == "\n" then
				
				lineStart = index
				lines += 1
			end
			
			if char == nextEndChar then
				
				endMatchCount += 1
				if endMatchCount == endMatchGoal then return content end
			else
				
				endMatchCount = 0
				content ..= char
			end
		end
	end
	
	--// End
	self:skipBlank()
	return self
end

--// End
return Lexer