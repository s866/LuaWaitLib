-- 这个文件储存的是已经预先写好的一些异步方法
-- 比如：滚动数字

local AsyncDo = {}

CO.AsyncDo = AsyncDo


---滚动数字
---@async
---@param from number
---@param to number
---@param scrollTime number
---@param callFunc fun(curValue:number)
---@return Event
function AsyncDo:ScrollNumber(from,to,scrollTime,callFunc)
    local event = CoroutineFactory:CreateEvent('ScrollNumber',function ()
        local delta = to - from
        local curTime = 0

        while curTime < scrollTime do
            local cur = from + delta * (curTime / scrollTime)
            callFunc(cur)
            curTime = curTime + CoroutineFactory:GetDeltaTime()
            coroutine.yield()
        end
        callFunc(to)
        
    end)
    return event
end