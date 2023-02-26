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
    ---@type table<string,boolean>
    self.names = {}
end


function TagMaker:Make(name)
    local fullName = string.format('%s_%s',self.headName,name)
    self.names[fullName] = true

    return fullName
end
---@deprecated 
function TagMaker:GetAllTagName()
    local r = {}
    for key, value in pairs(self.names) do
        VectorT:Push_back(r,key)
    end
    return r
end

---@deprecated 使用CoTree:Kill代替
function TagMaker:KillAllByTag(triggerFailEvent)
    triggerFailEvent = SetDefault(triggerFailEvent,false)
    for key, value in pairs(self.names) do
        CoroutineFactory:KillByTag(key,triggerFailEvent)
    end
end

function TagMaker:Clean()
    self.names = {}
end