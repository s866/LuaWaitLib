
---@class CoroutineReturnInfo
---@field IsSuccess boolean
---@field waitWrapperIns ?IWaitWrapper


---@class CoroutineFactory
CoroutineFactory = {}
---@type Task[]
CoroutineFactory.Coroutines_NextFrameRun = {}
CoroutineFactory.curTree = nil
CoroutineFactory.curDeltaTime = 0

CoroutineFactory.debug = CO.GetDebugFlag()
CoroutineFactory.MAX_WAIT_TIME = 100
CoroutineFactory.FrameCount = 0


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
    self.curTree = nil
    
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
---@param autoStart ?boolean （默认true）自动启动
---@param isRoot ?boolean （默认true）是否为Root节点
---@return Task
function CoroutineFactory:CreateTask(tag,func,autoStart,isRoot)
    autoStart = SetDefault(autoStart,true)
    isRoot = SetDefault(isRoot,true)

    

    local task = CO.Task.New(func,tag)
    local belongTree
    if isRoot then
        belongTree = CO.CoTree.New(task)
    else
        belongTree = self:GetOrCreateCurTree(task)
    end
    task:MoveToTree(belongTree)

    if autoStart == true then
        task:Run()
    end
    return task
end

---创建一个事件，事件可以被等待
---@param tag string 标签
---@param func async function 事件执行的函数
---@param autoStart ?boolean （默认true）自动启动
---@param isRoot ?boolean （默认true）是否为Root节点
---@return Event
function CoroutineFactory:CreateEvent(tag,func,autoStart,isRoot)
    autoStart = SetDefault(autoStart,true)
    isRoot = SetDefault(isRoot,false)
    
    local e = CO.Event.New(tag,func,isRoot)

    local belongTree
    if isRoot then
        belongTree = CO.CoTree.New(e)
    else
        belongTree = self:GetOrCreateCurTree(e)
    end
    e.runTask:MoveToTree(belongTree)

    if autoStart == true then
        e:Run()
    end
    return e
end

function CoroutineFactory:CreateWaitEvent(tag,timeSecond,autoStart)
    return self:CreateEvent(tag,function ()
        CO.Wait:Wait(timeSecond)
    end,autoStart)
end

function CoroutineFactory:CreateCustomWaitEvent(tag,waitFunc,autoStart)
    return self:CreateEvent(tag,waitFunc,autoStart)
end





---@private
---@param task Task
function CoroutineFactory:ResumeCoroutine(task)
    if task == nil then return end
    

    local preState,suc,info

    if task:IsOrphan() then
        preState = task:GetState()
        suc, info = coroutine.resume(task.co)
    else
        self.curTree = task.belongTree
        local coStack = task.belongTree:GetCoStack()
        coStack:Push(task)
        preState = task:GetState()
        suc, info = coroutine.resume(task.co)
        coStack:Pop()
    
    end
    ---CoroutineReturnInfo类型来自 Task:Init的wrappedFunc
    ---nil类型来自 coroutine.yield()
    ---@cast info CoroutineReturnInfo|nil

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
        ---@cast info -nil
        -- 如果时dead，Task:Init的wrappedFunc确保了不为nil
        task:Kill_Pure()
        task:UpdateState(info.IsSuccess)
        return
    end
    -- 必须在所有resume执行后的后续处理操作完成后，才能进行update，不然有的状态没有及时更新，比如isPenddingKill
    task:UpdateState()

    if info ~= nil and info.waitWrapperIns ~= nil then
        task:SetWaitWrapper(info.waitWrapperIns)
    end

    self:AddCoroutineData_Checked(task)
end


function CoroutineFactory:Update(deltaTime)
    self:SetDeltaTime(deltaTime)
    self.FrameCount = self.FrameCount + 1
    
    local temp = self.Coroutines_NextFrameRun
    self.Coroutines_NextFrameRun = {}
    for i = 1, #temp do
        local task = temp[i]
        if not task:IsKilled() then
            if task:HasWaitWrapper() then
                -- 存在则调用更新
                if not task:UpdateWaitWrapper(deltaTime) then
                    -- 如果未等到结束就加回去等下一帧遍历
                    self:AddCoroutineData_Checked(task)
                end
            else
                -- 不存在则每帧调用run
                task:Run()
            end
            
        else
            -- 无效的则不进行回加，代表删除了
            
        end
    end
    
end

function CoroutineFactory:SetDeltaTime(t)
    self.curDeltaTime = t
end

function CoroutineFactory:GetDeltaTime()
    return self.curDeltaTime
end

function CoroutineFactory:GetCurTree()
    return self.curTree
end

function CoroutineFactory:GetOrCreateCurTree(root)
    local curTree = self:GetCurTree()
    if curTree == nil then
        curTree = CO.CoTree.New(root)
    end
    return curTree
end

---杀死同一tag的协程
---@param tag string
function CoroutineFactory:KillByTag(tag,triggerFailEvent)
    if tag == nil then return end

    triggerFailEvent = SetDefault(triggerFailEvent,true)

    for i = 1, #self.Coroutines_NextFrameRun do
        local task = self.Coroutines_NextFrameRun[i]
        if task.tag == tag then
            if triggerFailEvent == true then
                task:Kill()
            else
                task:Kill_Pure()
            end
        end
    end
end

---@param events Event[]
function CoroutineFactory:KillEvents(events)
    for i = 1, #events do
        events[i]:Kill()
    end
end


---（如果task不存在WaitWrapper，这个函数将会跳过它）让所有wait中的协程继续运行  
---例如：  
---正在滚动数字，如果再点击一下跳过滚动数字，则调用HurryUpByTags  
---然后滚动数字的CustomWaitWrapper则会调用HurryUp方法直接结束
---@param hurryUpTags string[]
function CoroutineFactory:HurryUpByTags(hurryUpTags)
    for i = 1, #self.Coroutines_NextFrameRun do
        local task = self.Coroutines_NextFrameRun[i]
        for j = 1, #hurryUpTags do
            if task == hurryUpTags[j] then
                task:HurryUp()
                break
            end
        end
    end
end


---@private
---@param data Task
function CoroutineFactory:AddCoroutineData_Checked(data)
    -- 由于hurryup是同一帧执行，所以会出现重复添加的情况，这里需要过滤
    for i = 1, #self.Coroutines_NextFrameRun do
        if data == self.Coroutines_NextFrameRun[i] then
            return false
        end
    end
    
    self:AddCoroutineData_Internal(data)
    return true
end

---@private
---@param data Task
function CoroutineFactory:AddCoroutineData_Internal(data)
    table.insert(self.Coroutines_NextFrameRun,data)
    return data
    
end

function CoroutineFactory:IsCoroutineExist(tag)
    for i = 1, #self.Coroutines_NextFrameRun do
        local co = self.Coroutines_NextFrameRun[i]
        if co.tag == tag then
            return true
        end
    end
    return false
end


---@return Task|nil
function CoroutineFactory:GetTopCoroutine()
    if self.curTree == nil then return end

    return self.curTree:GetCoStack():Peek()
end

--#region Debug方法

function CoroutineFactory:PrintStack()
    -- TODO 打印stack内容
end


function CoroutineFactory:PrintDebugInfo()
    -- TODO 暂时不知道要打印什么
end


--#endregion

