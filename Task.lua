---@enum TaskEnum_StateType
TaskEnum_StateType = {
    Idle = 1,
    Running = 2,
    Error = 3,
    Success = 4,

}

---@class Task
local Task = {}

CO.Task = Task

function Task.New(func,tag)
    ---@type Task
    local o = {}
    setmetatable(o,{__index = Task})
    o:Init(func,tag)
    return o
end

---@param tag string
function Task:Init(func,tag)
    local wrappedFunc = function (...)
        local res,suc = CO.SafeCall(func,...)
        if res == nil then
            res = {}
        end
        ---@cast res CoroutineReturnInfo
        res.IsSuccess = suc        
        return res
    end
    local co = CoroutineFactory:CreateCoroutine(wrappedFunc)
    self.co = co
    self.tag = tag
    self.state = TaskEnum_StateType.Idle
    self.isPenddingKill = false
    ---@type Task[]
    self.children = {}
    ---@type Task
    self.parent = nil
    self.successListeners = {}
    self.errorListeners = {}
    return self
end

---@param wrapperIns IWaitWrapper
function Task:SetWaitWrapper(wrapperIns)
    self.waitWrapper = wrapperIns

    self.waitWrapper:BindTask(self)
    
end

function Task:HasWaitWrapper()
    return self.waitWrapper ~= nil
end

function Task:UpdateWaitWrapper(deltaTime)
    -- 如果不存在waitWrapper，则直接返回已经完成
    if self.waitWrapper == nil then return true end

    return self.waitWrapper:WaitUpdate(deltaTime)
end


function Task:Run()
    -- 这里还不是真正的运行，需要在coroutinue.resume之后才算，所以在UpdateState里更新
    -- self:SetState(TaskEnum_StateType.Running)

    ---@diagnostic disable-next-line
    CoroutineFactory:ResumeCoroutine(self)
    
end




---@param func fun(task:Task)
function Task:AddSuccessListener(func)
    if func == nil then return end
    table.insert(self.successListeners,func)
end

---@param func fun(task:Task)
function Task:RemoveSuccessListener(func)
    for i = 1, #self.successListeners do
        if self.successListeners[i] == func then
            table.remove(self.successListeners,i)
        end
    end
end

---@param func fun(task:Task)
function Task:AddErrorListener(func)
    if func == nil then return end
    table.insert(self.errorListeners,func)
end

---@param func fun(task:Task)
function Task:RemoveErrorListener(func)
    for i = 1, #self.errorListeners do
        if self.errorListeners[i] == func then
            table.remove(self.errorListeners,i)
        end
    end
end


function Task:Kill()
    -- 设置标志，下一帧清理
    self.isPenddingKill = true

    for i = 1, #self.children do
        self.children[i]:Kill()
    end

    if self.parent ~= nil then
        -- 把自己从parent的children里拿出，防止内存泄漏
        self.parent:RemoveChild(self)    
        self.parent = nil
    end
    
end





function Task:GetState()
    return self.state
end

---@private
---@param state TaskEnum_StateType
---@return boolean
function Task:SetState(state)
    if self.state ~= state then
        self.state = state
        return true
    end    
    return false
end

function Task:UpdateState(isSuccess)
    local coStatus = self:GetCoroutineStatus()
    if coStatus == "running" or coStatus == "suspended" or coStatus == "normal" then
        self:SetState(TaskEnum_StateType.Running)
    elseif coStatus == "dead" then
        if isSuccess then
            self:Success()
        else
            self:Fail()
        end
    end
end

function Task:GetCoroutineStatus()
    if self.co == nil then return end

    return coroutine.status(self.co)
end






function Task:Fail()
    if self.state ~= TaskEnum_StateType.Success and self:SetState(TaskEnum_StateType.Error) then
        for i = 1, #self.errorListeners do
            CO.SafeCall(self.errorListeners[i],self)
        end
        self.errorListeners = {}
    end
end

function Task:Success()
    if self.state ~= TaskEnum_StateType.Error and self:SetState(TaskEnum_StateType.Success) then
        for i = 1, #self.successListeners do
            CO.SafeCall(self.successListeners[i],self)
        end
        self.successListeners = {}
    end
end


---@param child Task
function Task:AddChild(child)
    if child == nil then return end
    if child:IsEnd() then 
        COLogError(string.format('%s AddChild %s fail',self:ToString(),child:ToString()))
        return
    end
    if child.parent ~= nil then
        COLogError(string.format('%s AddChild, %s parent %s not nil',self:ToString(),child:ToString(),child.parent:ToString()))
        return
    end
    child.parent = self
    table.insert(self.children,child)    
end

function Task:RemoveChild(child)
    if child == nil then return end

    for i = 1, #self.children do
        if self.children[i] == child then
            table.remove(self.children,i)
            return
        end
    end
    
end

function Task:IsEnd()
    if self.state == TaskEnum_StateType.Error or self.state == TaskEnum_StateType.Success then
        return true
    end
    return false
end

function Task:IsSuccess()
    return self.state == TaskEnum_StateType.Success
end

function Task:GetTaskStackTrace()
    -- TODO 打印当前节点到树状根节点的路径
end

function Task:ToString()
    return string.format('task:[tag = %s state = %s]',self.tag,CO.Misc:EnumValue2Name(TaskEnum_StateType,self.state))
end