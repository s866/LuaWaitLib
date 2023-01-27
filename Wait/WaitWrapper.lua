
---@class IWaitWrapper
---@field WaitUpdate fun(self:IWaitWrapper,deltaTime:number):boolean ;返回是否结束，true为结束
---@field BindTask fun(self:IWaitWrapper,task:Task)
---@field HurryUpTask fun(self:IWaitWrapper) ;运行正在等待的task

-- **********************************************
-- 目前最好不要编写类似调用自定义函数的WaitWrapper，
-- 比如传入一个updateFunc，然后在WaitUpdate里调用这个函数，
-- 因为WaitUpdate发生错误后，将不会有错误处理的选项进行处理，
-- 可能会出现一些意料之外的事情
-- **********************************************



---@class TimeWaitWrapper : IWaitWrapper
local TimeWaitWrapper = {}
TimeWaitWrapper.DEFUALT_WAIT_TIME_SECOND = 1
TimeWaitWrapper.MAX_WAIT_TIME_SECOND = 20

CO.TimeWaitWrapper = TimeWaitWrapper

function TimeWaitWrapper.New(waitTime)
    ---@type TimeWaitWrapper
    local o = {}

    setmetatable(o,{__index = TimeWaitWrapper})
    o:Init(waitTime)
    return o
end

function TimeWaitWrapper:Init(waitTime)
    if waitTime == nil then waitTime = self.DEFUALT_WAIT_TIME_SECOND end

    self.waitTime = math.min(waitTime,self.MAX_WAIT_TIME_SECOND)
    self.curWaitTime = 0
    self.timeEndFuncs = {}
    ---@type table<Task,boolean>
    self.tasks = {}
end


function TimeWaitWrapper:WaitUpdate(deltaTime)
    self.curWaitTime = self.curWaitTime + deltaTime
    if self:IsEnd() then
        for i = 1, #self.timeEndFuncs do
            CO.SafeCall(self.timeEndFuncs[i])
        end
        self:HurryUpTask()
        return true
    end
    return false
end

function TimeWaitWrapper:IsEnd()
    return self.curWaitTime >= self.waitTime
end

function TimeWaitWrapper:AddTimeEndFunc(func)
    table.insert(self.timeEndFuncs,func)
end

---@param task Task
function TimeWaitWrapper:BindTask(task)
    self.tasks[task] = true
end

function TimeWaitWrapper:HurryUpTask()
    for task, value in pairs(self.tasks) do
        task:Run()
    end
end


---@class EventsWaitWrapper : IWaitWrapper
local EventsWaitWrapper = {}

CO.EventsWaitWrapper = EventsWaitWrapper

function EventsWaitWrapper.New(events,eventsWaitOpt,errorProcessData)
    ---@type EventsWaitWrapper
    local o = {}

    setmetatable(o,{__index = EventsWaitWrapper})
    o:Init(events,eventsWaitOpt,errorProcessData)
    return o
end

---@param events Event[]
---@param eventsWaitOpt COWaitEnum_WaitTaskOpt
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function EventsWaitWrapper:Init(events,eventsWaitOpt,errorProcessData)
    self.events = events
    self.eventsWaitOpt = eventsWaitOpt
    self.errorProcessData = errorProcessData


    self.eventSuccessCount = 0
    -- 必须在等待的事件触发后马上触发，否则可能出现帧延迟的情况
    self.OnEventSuccessFunc = function ()
        if self.eventsWaitOpt == COWaitEnum_WaitTaskOpt.WaitAny then
            self:CleanEventSuccessListener()
            self:HurryUpTask()                

        elseif self.eventsWaitOpt == COWaitEnum_WaitTaskOpt.WaitAll then
            self.eventSuccessCount = self.eventSuccessCount + 1
            if self.eventSuccessCount >= #self.events then
                self:CleanEventSuccessListener()
                self:HurryUpTask()
            end
        else
            COLogError('unknown event wait opt %d',self.eventsWaitOpt)
        end
    end


    ---@type table<Task,boolean>
    self.tasks = {}
end

function EventsWaitWrapper:WaitUpdate(deltaTime)
    -- 这里代表一直等待，触发由OnEventSuccessFunc处理
    return false
end

---@param task Task
function EventsWaitWrapper:BindTask(task)
    self.tasks[task] = true
    
    for i = 1, #self.events do
        -- 加完必须删除！！！
        self.events[i]:AddSuccessListener(self.OnEventSuccessFunc)
        if self.errorProcessData.opt == COWaitEnum_EventErrorOpt.ErrorAsSuccess then
            self.events[i]:AddErrorListener(self.OnEventSuccessFunc)
        elseif self.errorProcessData.opt == COWaitEnum_EventErrorOpt.CallCustomFunc then
            self.events[i]:AddErrorListener(self.errorProcessData.func)
        end
    end
end

function EventsWaitWrapper:HurryUpTask()
    for task, value in pairs(self.tasks) do
        task:Run()
    end
end

function EventsWaitWrapper:CleanEventSuccessListener()
    for i = 1, #self.events do
        self.events[i]:RemoveSuccessListener(self.OnEventSuccessFunc)
        if self.errorProcessData.opt == COWaitEnum_EventErrorOpt.ErrorAsSuccess then
            self.events[i]:RemoveErrorListener(self.OnEventSuccessFunc)
        elseif self.errorProcessData.opt == COWaitEnum_EventErrorOpt.CallCustomFunc then
            self.events[i]:RemoveErrorListener(self.errorProcessData.func)
        end
    end
end


---@class FrameWaitWrapper : IWaitWrapper
local FrameWaitWrapper = {}
CO.FrameWaitWrapper = FrameWaitWrapper

function FrameWaitWrapper.New(count)
    ---@type FrameWaitWrapper
    local o = {}

    setmetatable(o,{__index = FrameWaitWrapper})
    o:Init(count)
    return o
end

function FrameWaitWrapper:Init(count)
    self.count = count
    self.curCount = 0
    ---@type table<Task,boolean>
    self.tasks = {}
end

function FrameWaitWrapper:WaitUpdate(deltaTime)
    self.curCount = self.curCount + 1
    if self:IsEnd() then
        self:HurryUpTask()
        return true
    end
    return false
end

function FrameWaitWrapper:BindTask(task)
    self.tasks[task] = true

end

function FrameWaitWrapper:HurryUpTask()
    for task, value in pairs(self.tasks) do
        task:Run()
    end
end

function FrameWaitWrapper:IsEnd()
    return self.curCount >= self.count
end








---@class EventsTimeoutWaitWrapper : IWaitWrapper
local EventsTimeoutWaitWrapper = {}
EventsTimeoutWaitWrapper.DEFAULT_TIMEOUT_SECOND = 10

CO.EventsTimeoutWaitWrapper = EventsTimeoutWaitWrapper

function EventsTimeoutWaitWrapper.New(events,eventsWaitOpt,timeout,timeoutOpt,errorProcessData)
    ---@type EventsTimeoutWaitWrapper
    local o = {}

    setmetatable(o,{__index = EventsTimeoutWaitWrapper})
    o:Init(events,eventsWaitOpt,timeout,timeoutOpt,errorProcessData)
    return o
end

---@param events Event[]
---@param eventsWaitOpt COWaitEnum_WaitTaskOpt
---@param timeout ?number
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function EventsTimeoutWaitWrapper:Init(events,eventsWaitOpt,timeout,timeoutOpt,errorProcessData)
    self.eventsWaitWrapper = EventsWaitWrapper.New(events,eventsWaitOpt,errorProcessData)

    if timeout == nil then timeout = self.DEFAULT_TIMEOUT_SECOND end
    if timeoutOpt == nil then timeoutOpt = COWaitEnum_TimeoutOpt.Break end
    self.timeoutOpt = timeoutOpt


    self.timeWaitWrapper = TimeWaitWrapper.New(timeout)
    self.timeWaitWrapper:AddTimeEndFunc(function ()
        COLogError('************************************')
        COLogError('wait below events timeout')
        for i = 1, #self.eventsWaitWrapper.events do
            COLogError(self.eventsWaitWrapper.events[i]:ToString())    
        end
        COLogError('************************************')
    end)
    
end

function EventsTimeoutWaitWrapper:WaitUpdate(deltaTime)
    if self.eventsWaitWrapper:WaitUpdate(deltaTime) == true then
        return true
    end

    return self.timeWaitWrapper:WaitUpdate(deltaTime)
end

---@param task Task
function EventsTimeoutWaitWrapper:BindTask(task)
    self.eventsWaitWrapper:BindTask(task)
    -- 超时处理
    if self.timeoutOpt == COWaitEnum_TimeoutOpt.Break then
        -- 中断则不进行处理
    elseif self.timeoutOpt == COWaitEnum_TimeoutOpt.Continue then
        -- 继续运行
        self.timeWaitWrapper:BindTask(task)
    else
    end
end

function EventsTimeoutWaitWrapper:HurryUpTask()
    self.eventsWaitWrapper:HurryUpTask()
end

function EventsTimeoutWaitWrapper:IsTimeout()
    return self.timeWaitWrapper:IsEnd()
end




