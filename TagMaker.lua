---@class TagMaker
local TagMaker = {}

CO.TagMaker = TagMaker

function TagMaker.New(headName)
    ---@type TagMaker
    local o = {}

    setmetatable(o,{__index = TagMaker})
    o:Init(headName)
    return o
end

function TagMaker:Init(headName)
    self.headName = headName
    ---@type string[]
    self.names = {}
end


function TagMaker:Make(name)
    local fullName = string.format('%s_%s',self.headName,name)
    VectorT:Push_back(self.names,fullName)

    return fullName
end

function TagMaker:GetAllTagName()
    return self.names
end

function TagMaker:Clean()
    self.names = {}
end