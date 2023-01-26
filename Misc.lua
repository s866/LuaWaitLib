Misc = {}

function Misc:EnumValue2Name(eunm,enumValue)
    for key, value in pairs(eunm) do
        if value == enumValue then
            return key
        end
    end
    return ''
end







---@enum COWaitEnum_WaitTaskOpt
COWaitEnum_WaitTaskOpt = {
    WaitAll = 1,
    WaitAny = 2,
}

---等待的事件出现错误后，处理方式
---@enum COWaitEnum_EventErrorOpt
COWaitEnum_EventErrorOpt = {
    DoNothing = 1,
    ErrorAsSuccess = 2,
    CallCustomFunc = 3,
}

---@class COWait_EventErrorProcessData
---@field opt COWaitEnum_EventErrorOpt
---@field func ?fun(task:Task) opt == CallCustomFunc时调用


---@enum COWaitEnum_TimeoutOpt
COWaitEnum_TimeoutOpt = {
    Break = 1,
    Continue = 2,
}


COWait = {}

function COWait:Wait(timeSecond)
    if timeSecond == nil then return end
    if timeSecond == 0 then return end

    ---@type CoroutineReturnInfo
    local retData = {waitWrapperIns = TimeWaitWrapper.New(timeSecond)}
    coroutine.yield(retData)

end

---@param event Event
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function COWait:WaitEvent(event,timeout,timeoutOpt,errorProcessData)
    return self:WaitAllEvents({event},timeout,timeoutOpt,errorProcessData)
end

---@param events Event[]
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function COWait:WaitAllEvents(events,timeout,timeoutOpt,errorProcessData)
    return self:WaitEvents_Internal(events,COWaitEnum_WaitTaskOpt.WaitAll,timeout,timeoutOpt,errorProcessData)
end

---@param events Event[]
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function COWait:WaitAnyEvents(events,timeout,timeoutOpt,errorProcessData)
    return self:WaitEvents_Internal(events,COWaitEnum_WaitTaskOpt.WaitAny,timeout,timeoutOpt,errorProcessData)
end

---@private
---@param events Event[]
---@param eventWaitOpt COWaitEnum_WaitTaskOpt
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
---@return boolean ;是否成功
function COWait:WaitEvents_Internal(events,eventWaitOpt,timeout,timeoutOpt,errorProcessData)
    if events == nil then return true end
    if errorProcessData == nil then
        errorProcessData = {opt = COWaitEnum_EventErrorOpt.DoNothing}
    end
    

    local allEnd = true
    for i = 1, #events do
        if not events[i]:IsEnd() then
            allEnd = false
            break
        end
    end
    
    if allEnd then return true end

    local eventWrapper = EventsTimeoutWaitWrapper.New(events,eventWaitOpt,timeout,timeoutOpt,errorProcessData)
    ---@type CoroutineReturnInfo
    local retData = {waitWrapperIns = eventWrapper}
    coroutine.yield(retData)

    return not eventWrapper:IsTimeout()
end



function COWait:WaitFrameCount(count)
    if count <= 0 then return end

    local wrapper = FrameWaitWrapper.New(count)
    ---@type CoroutineReturnInfo
    local retData = {waitWrapperIns = wrapper}
    coroutine.yield(retData)

end