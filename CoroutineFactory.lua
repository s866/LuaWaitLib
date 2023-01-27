require 'Lib'

---@class CoroutineReturnInfo
---@field IsSuccess boolean
---@field waitWrapperIns ?IWaitWrapper


---@class CoroutineFactory
CoroutineFactory = {}
---@type Task[]
CoroutineFactory.Coroutines_NextFrameRun = {}
CoroutineFactory.CoroutineStack = CO.Stack.New()

CoroutineFactory.debug = CO.GetDebugFlag()
CoroutineFactory.MAX_WAIT_TIME = 100



local function CoroutineTracer_NewFunctionCall(triggerType)
    print(triggerType)
    if triggerType == "return" then
		return
	end

    local info = debug.getinfo(2, "nSl" )
    if info == nil then return end
    if info.what ~= 'Lua' then return end
    print('--------------------------')
    print(info.source)
    print(info.currentline)
end

function CoroutineFactory:Clean()
    self.Coroutines_NextFrameRun = {}
    self.CoroutineStack = CO.Stack.New()

end

function CoroutineFactory:CreateCoroutine(func)
    local co = coroutine.create(func)
    if self.debug then
        -- 现在有vsc调试器，等后面有需求了再加
        -- debug.sethook( co, CoroutineTracer_NewFunctionCall, "cr" )
    end
    return co
end


---创建一个任务，不可被等待的被称为任务，一般根节点都为任务
---@param tag string 标签
---@param func async function 协程执行的函数
---@param autoStart ?boolean 自动启动
---@return Task
function CoroutineFactory:CreateTask(tag,func,autoStart)
    if autoStart == nil then autoStart = true end
    
    local task = CO.Task.New(func,tag)
    if autoStart == true then
        task:Run()
    end
    return task
end

---创建一个事件，事件可以被等待
---@param tag string 标签
---@param func async function 事件执行的函数
---@param autoStart ?boolean 自动启动
---@return Event
function CoroutineFactory:CreateEvent(tag,func,autoStart)
    if autoStart == nil then autoStart = true end
    
    local e = CO.Event.New(tag,func)
    if autoStart == true then
        e:Run()
    end
    return e
end




---@private
---@param task Task
function CoroutineFactory:ResumeCoroutine(task)
    if task == nil then return end
    
    self.CoroutineStack:Push(task)
    local preState = task:GetState()
	local suc, info = coroutine.resume(task.co)
    ---Task:Init的wrappedFunc确保了CoroutineReturnInfo类型
    ---@cast info CoroutineReturnInfo

    self.CoroutineStack:Pop()

    -- 如果是第一次启动，需要添加到树状结构管理里
    if preState == TaskEnum_StateType.Idle then
        local topTask = self:GetTopCoroutine()
        if topTask ~= nil then
            topTask:AddChild(task)
        end
    end


    if not suc then
        task:Kill()
        self:PrintDebugInfo()
        return
    end

    if task:GetCoroutineStatus() == "dead" then
        task:Kill()
        task:UpdateState(info.IsSuccess)
        return
    end
    -- 必须在所有resume执行后的后续处理操作完成后，才能进行update，不然有的状态没有及时更新，比如isPenddingKill
    task:UpdateState()

    if info.waitWrapperIns ~= nil then
        task:SetWaitWrapper(info.waitWrapperIns)
    end

    self:AddCoroutineData(task)
end


function CoroutineFactory:Update(deltaTime)
    local temp = self.Coroutines_NextFrameRun
    self.Coroutines_NextFrameRun = {}
    for i = 1, #temp do
        local task = temp[i]
        if not task.isPenddingKill then
            if not task:UpdateWaitWrapper(deltaTime) then
                -- 如果未等到结束就加回去等下一帧遍历
                self:AddCoroutineData(task)
            end
        else
            -- penddingKill不进行回加则代表删除了
            
        end
    end
    
end

---杀死同一tag的协程
---@param tag string
function CoroutineFactory:KillByTag(tag)
    if tag == nil then return end

    for i = 1, #self.Coroutines_NextFrameRun do
        local task = self.Coroutines_NextFrameRun[i]
        if task.tag == tag then
            task:Kill()
        end
    end
end


---@private
---@param data Task
function CoroutineFactory:AddCoroutineData(data)
    table.insert(self.Coroutines_NextFrameRun,data)
    return data
end






---@return Task|nil
function CoroutineFactory:GetTopCoroutine()
    return self.CoroutineStack:Peek()
end

--#region Debug方法

function CoroutineFactory:PrintStack()
    -- TODO 打印stack内容
end


function CoroutineFactory:PrintDebugInfo()
    -- TODO 暂时不知道要打印什么
end


--#endregion

