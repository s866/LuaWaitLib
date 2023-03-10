-- 这个文件储存的是已经预先写好的一些异步方法
-- 比如：滚动数字

local AsyncDo = {}

CO.AsyncDo = AsyncDo

local function MakeAsyncDoTag(tag,endName)
    return string.format('%s_%s',tostring(tag),tostring(endName))
end

---滚动数字
---@async
---@param tag string
---@param from number
---@param to number
---@param scrollTime number
---@param callFunc fun(curValue:number)
---@return Event
function AsyncDo:ScrollNumber(tag,from,to,scrollTime,callFunc)
    local event = CoroutineFactory:CreateEvent(tag,function ()
        local delta = to - from
        local curTime = 0

        CO.Wait:CustomWait(function (deltaTime)
            if curTime < scrollTime then
                local cur = from + delta * (curTime / scrollTime)
                callFunc(cur)
                curTime = curTime + deltaTime
                return false
            else
                return true
            end
        end,function ()
            -- 结束运行后数字要设置为目标值
            callFunc(to)
        end)
        
    end)
    return event
end

---队列执行，固定时间间隔，datas中的元素会在运行中动态添加的，需要注意
---@async
---@generic T
---@param datas T[]
---@param tag string
---@param timespan number
---@param callFunc fun(curIndex:integer,data:T)
---@return Event
function AsyncDo:QueueDo_ByTime(tag,datas,timespan,callFunc)
    return self:QueueDo_ByDynamicTime(tag,datas,function (index, data)
        return timespan
    end,callFunc)
end

---队列执行，动态时间间隔，datas中的元素会在运行中动态添加的，需要注意
---@async
---@generic T
---@param datas T[]
---@param tag string
---@param getTimeSpanFunc fun(curIndex:integer,data:T):number 获取当前下标下的时间间隔
---@param callFunc fun(curIndex:integer,data:T)
---@return Event
function AsyncDo:QueueDo_ByDynamicTime(tag,datas,getTimeSpanFunc,callFunc)
    local event = CoroutineFactory:CreateEvent(tag,function ()
        -- datas中的元素会在运行中动态添加的，需要注意
        if #datas == 0 then return end

        local curIndex = 1
        local curTime = getTimeSpanFunc(curIndex,datas[curIndex])

        CO.Wait:CustomWait(function (deltaTime)
            if curIndex > #datas then return true end

            if curTime < getTimeSpanFunc(curIndex,datas[curIndex]) then
                curTime = curTime + deltaTime

            else
                callFunc(curIndex,datas[curIndex])
                curIndex = curIndex + 1
                curTime = 0
            end
            return false
        end,function ()
            -- 执行完剩余没执行的
            for i = curIndex, #datas do
                callFunc(datas[i])
            end
        end)
        
    end)
    return event
end

---根据一定的时间间隔循环执行函数
---@param tag any
---@param timespan number
---@param execFunc fun(execCount:integer):boolean 返回值true则代表结束
---@param execOnStart ?boolean （默认false）是否启动就执行一次函数
---@return Event
function AsyncDo:Exec_ByTime(tag,timespan,execFunc,execOnStart)
    execOnStart = SetDefault(execOnStart,false)

    local curTime = 0
    local execCount = 0
    if execOnStart then curTime = timespan end

    local event = self:Exec_ByFrameTick(tag,function (deltaTime, _)
        if curTime < timespan then
            curTime = curTime + deltaTime
        else
            execCount = execCount + 1
            curTime = 0
        end
        return execFunc(execCount)
    end)

    return event
end

---每帧执行函数
---@param tag any
---@param execFunc fun(deltaTime,execCount:integer):boolean 返回值true则代表结束
---@return Event
function AsyncDo:Exec_ByFrameTick(tag,execFunc)
    local event = CoroutineFactory:CreateEvent(tag,function ()
        local execCount = 0

        CO.Wait:CustomWait(function (deltaTime)
            execCount = execCount + 1
            return execFunc(deltaTime,execCount)
        end)

    end)
    return event
end