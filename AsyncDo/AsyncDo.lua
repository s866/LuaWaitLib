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