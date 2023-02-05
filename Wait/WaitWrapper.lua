
---@class IWaitWrapper
---@field WaitUpdate fun(self:IWaitWrapper,deltaTime:number):boolean ;返回是否结束，true为结束
---@field BindTask fun(self:IWaitWrapper,task:Task) ;这里的task默认为wait调用所在的task，自动赋值
---@field HurryUpTask fun(self:IWaitWrapper) ;运行正在等待的task


-- ***************************************
-- 编写注意：
-- 每一个waitwrapper都需要负责调用hurryup来继续等待中的event的运行
-- 否则event将会一直等待，update返回true并不会自动调用hurryup！！！
-- ***************************************



---@class CustomWaitWrapper : IWaitWrapper
local CustomWaitWrapper = {}

CO.CustomWaitWrapper = CustomWaitWrapper

function CustomWaitWrapper.New(customFunc,hurryUpDoFunc)
    ---@type CustomWaitWrapper
    local o = {}

    setmetatable(o,{__index = CustomWaitWrapper})
    o:Init(customFunc,hurryUpDoFunc)
    return o
end

function CustomWaitWrapper:Init(customFunc,hurryUpDoFunc)
    self.customFunc = customFunc
    self.hurryUpDoFunc = hurryUpDoFunc

    ---@type Task
    self.task = nil
end


function CustomWaitWrapper:WaitUpdate(deltaTime)
    if self.customFunc(deltaTime) == true then
        self:HurryUpTask()
    end
    return false
end

---@param task Task
function CustomWaitWrapper:BindTask(task)
    self.task = task
end

function CustomWaitWrapper:HurryUpTask()
    if self.hurryUpDoFunc ~= nil then
        -- 这里出现异常要抛出去不能捕获
        self.hurryUpDoFunc()
    end

    self.task:Run()
end






---@class TimeWaitWrapper : IWaitWrapper
local TimeWaitWrapper = {}
TimeWaitWrapper.DEFUALT_WAIT_TIME_SECOND = 1
TimeWaitWrapper.MAX_WAIT_TIME_SECOND = 20000

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
    ---@type Task
    self.task = nil
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
    self.task = task
end

function TimeWaitWrapper:HurryUpTask()
    if self.task == nil then return end
    self.task:Run()
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


    ---@type Task
    self.task = nil
end

function EventsWaitWrapper:WaitUpdate(deltaTime)
    -- 这里代表一直等待，触发由OnEventSuccessFunc处理
    return false
end

---@param task Task
function EventsWaitWrapper:BindTask(task)
    self.task = task
    
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
    self.task:Run()
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
    ---@type Task
    self.task = nil
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
    self.task = task

end

function FrameWaitWrapper:HurryUpTask()
    self.task:Run()
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

    self.task = nil

    self.timeWaitWrapper = TimeWaitWrapper.New(timeout)
    self.timeWaitWrapper:AddTimeEndFunc(function ()
        COLogError('************************************')
        COLogError('wait below events timeout')
        for i = 1, #self.eventsWaitWrapper.events do
            COLogError(self.eventsWaitWrapper.events[i]:ToString())    
        end
        COLogError('timeout opt %d ,time %d',self.timeoutOpt,self.timeWaitWrapper.waitTime)
        COLogError('************************************')
    end)
    
end

function EventsTimeoutWaitWrapper:WaitUpdate(deltaTime)
    if self.eventsWaitWrapper:WaitUpdate(deltaTime) == true then
        return true
    end
    local isTimeout = self.timeWaitWrapper:WaitUpdate(deltaTime)
    if isTimeout then
        self.eventsWaitWrapper:CleanEventSuccessListener()
        if self.timeoutOpt == COWaitEnum_TimeoutOpt.Break then
            -- 中断的情况超时需要Kill掉，不然等待的event还在运行，导致等待的event完成后使得中断的协程resume
            self.task:Kill()
        end
    end
    return isTimeout
end

---@param task Task
function EventsTimeoutWaitWrapper:BindTask(task)
    self.task = task
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




