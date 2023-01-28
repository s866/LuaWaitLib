
---@class Event
local Event = {}

CO.Event = Event

function Event.New(tag,func)
    ---@class Event
    local o = {}

    setmetatable(o,{__index = Event})
    o:Init(tag,func)
    return o
end

function Event:Init(tag,func)
    self.runTask = CoroutineFactory:CreateTask(tag,func,false)
end

function Event:Run()
    self.runTask:Run()
end

function Event:HurryUp()
    self.runTask:HurryUp()
end


function Event:AddSuccessListener(func)
    self.runTask:AddSuccessListener(func)
end
function Event:RemoveSuccessListener(func)
    self.runTask:RemoveSuccessListener(func)
end

function Event:AddErrorListener(func)
    self.runTask:AddErrorListener(func)
end
function Event:RemoveErrorListener(func)
    self.runTask:RemoveErrorListener(func)
end

function Event:Kill()
    self.runTask:Kill()
end

function Event:IsKilled()
    return self.runTask:IsKilled()
end

function Event:GetState()
    return self.runTask:GetState()
end

function Event:IsEnd()
    return self.runTask:IsEnd()
end

function Event:IsSuccess()
    return self.runTask:IsSuccess()
end


function Event:ToString()
    local taskStr = ''
    if self.runTask ~= nil then
        taskStr = self.runTask:ToString()
    end
    return string.format('event:[%s]',taskStr)
end