---@class Stack
local Stack = {}

function Stack.New(t)

	return setmetatable( t or {}, {__index = Stack} )

end

function Stack:Pop()
    if self:IsEmpty() then return nil end

    return table.remove(self,self:Length())
end

function Stack:Push(v)
    if v == nil then return end 
    
    table.insert(self,v)
end

function Stack:Peek()
    return self[self:Length()]
end

function Stack:IsEmpty()
    return self:Length() == 0
end

function Stack:Length()
    return #self
end



return Stack