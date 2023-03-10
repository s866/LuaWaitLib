
---@enum COWaitEnum_WaitTaskOpt
COWaitEnum_WaitTaskOpt = {
    WaitAll = 1,
    WaitAny = 2,
}

---等待的事件出现错误后，处理方式
---@enum COWaitEnum_EventErrorOpt
COWaitEnum_EventErrorOpt = {
    DoNothing = 1, -- 不做任何处理
    ErrorAsSuccess = 2, -- 把错误当成成功，事件全部结束后继续运行
    CallCustomFunc = 3, -- 发生错误后调用自定义函数，然后行为和DoNothing一样
}

---@class COWait_EventErrorProcessData
---@field opt COWaitEnum_EventErrorOpt
---@field func ?fun(task:Task) opt == CallCustomFunc时调用


---@enum COWaitEnum_TimeoutOpt
COWaitEnum_TimeoutOpt = {
    Break = 1,
    Continue = 2,
}


local Wait = {}
CO.Wait = Wait

function Wait:Wait(timeSecond)
    if timeSecond == nil then return end
    if timeSecond == 0 then return end

    local retData = self:CreateWaitCoroutineReturnInfo(timeSecond)

    coroutine.yield(retData)

end

function Wait:CreateWaitCoroutineReturnInfo(timeSecond)
    local retData = {waitWrapperIns = CO.TimeWaitWrapper.New(timeSecond)}
    return retData
end


---@param event Event
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function Wait:WaitEvent(event,timeout,timeoutOpt,errorProcessData)
    return self:WaitAllEvents({event},timeout,timeoutOpt,errorProcessData)
end

---@param events Event[]
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function Wait:WaitAllEvents(events,timeout,timeoutOpt,errorProcessData)
    return self:WaitEvents_Internal(events,COWaitEnum_WaitTaskOpt.WaitAll,timeout,timeoutOpt,errorProcessData)
end

---@param events Event[]
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
function Wait:WaitAnyEvents(events,timeout,timeoutOpt,errorProcessData)
    return self:WaitEvents_Internal(events,COWaitEnum_WaitTaskOpt.WaitAny,timeout,timeoutOpt,errorProcessData)
end

---@private
---@param events Event[]
---@param eventWaitOpt COWaitEnum_WaitTaskOpt
---@param timeout ?number 超时时间
---@param timeoutOpt ?COWaitEnum_TimeoutOpt （默认Break）超时后的协程是否继续
---@param errorProcessData ?COWait_EventErrorProcessData （默认opt为DoNothing）等待的event出现错误后的处理
---@return boolean ;是否成功
function Wait:WaitEvents_Internal(events,eventWaitOpt,timeout,timeoutOpt,errorProcessData)
    if events == nil then return true end
    if errorProcessData == nil then
        errorProcessData = {opt = COWaitEnum_EventErrorOpt.DoNothing}
    end
    
    if eventWaitOpt == COWaitEnum_WaitTaskOpt.WaitAll then
        local allEnd = true
        for i = 1, #events do
            if not events[i]:IsEnd() then
                allEnd = false
                break
            end
        end
        
        if allEnd then return true end
    elseif eventWaitOpt == COWaitEnum_WaitTaskOpt.WaitAny then
        local anyEnd = false
        for i = 1, #events do
            if events[i]:IsEnd() then
                anyEnd = true
                break
            end
        end
        if anyEnd then return true end
    end
    
    

    local eventWrapper = CO.EventsTimeoutWaitWrapper.New(events,eventWaitOpt,timeout,timeoutOpt,errorProcessData)
    ---@type CoroutineReturnInfo
    local retData = {waitWrapperIns = eventWrapper}
    coroutine.yield(retData)

    return eventWrapper:IsSuccess()
end



function Wait:WaitFrameCount(count)
    if count <= 0 then return end

    local wrapper = CO.FrameWaitWrapper.New(count)
    ---@type CoroutineReturnInfo
    local retData = {waitWrapperIns = wrapper}
    coroutine.yield(retData)

end

---自定义等待
---@param customFunc fun(deltaTime:number):boolean 每帧执行的等待函数，返回是否结束
---@param hurryUpDoFunc ?fun() 等待运行结束后执行的函数
function Wait:CustomWait(customFunc,hurryUpDoFunc)
    if customFunc == nil then return end

    local wrapper = CO.CustomWaitWrapper.New(customFunc,hurryUpDoFunc)
    ---@type CoroutineReturnInfo
    local retData = {waitWrapperIns = wrapper}
    coroutine.yield(retData)

end

---TODO 添加超时
---自定义规则等待
---@param ruleFunc fun():boolean 返回true则代表规则匹配成功
function Wait:WaitRule(ruleFunc)
    self:CustomWait(function (deltaTime)
        return ruleFunc()
    end)
end