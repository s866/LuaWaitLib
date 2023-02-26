
local Test_Tree = {}

function Test_Tree:TwoTree()
    TestLib:DoClean()
    local isFinish = false
    local t1,t2
    t1 = CoroutineFactory:CreateTask('Tree1',function ()
        t2 = CoroutineFactory:CreateTask('Tree2',function ()
            CO.Wait:WaitFrameCount(2)
            
            isFinish = true
            print('t2 finish')
        end)
        print('t1 finish')
    end)

    local t1t = t1.belongTree:GetAllTagName()
    assert(t1t[1] == 'Tree1')
    assert(t1t[2] == nil)
    local t2t = t2.belongTree:GetAllTagName()
    assert(t2t[1] == 'Tree2')
    assert(t2t[2] == nil)

    TestLib:DoUpdate()
    assert(isFinish == true)
end


function Test_Tree:TwoTree_TwoLife()
    TestLib:DoClean()
    local isFinish = false
    ---@type Task,Task,Event
    local t1,t2,t2e
    t1 = CoroutineFactory:CreateTask('Tree1',function ()
        t2 = CoroutineFactory:CreateTask('Tree2',function ()
            t2e = CO.AsyncDo:Exec_ByFrameTick('Tree2_Ticker',function() return false end)
            CO.Wait:WaitFrameCount(20)
            
            isFinish = true
        end)
        
    end)

    local t1t = t1.belongTree:GetAllTagName()
    assert(t1t[1] == 'Tree1')
    assert(t1t[2] == nil)
    local t2t = t2.belongTree:GetAllTagName()
    assert(t2t[1] == 'Tree2')
    assert(t2t[2] == 'Tree2_Ticker')
    assert(t2t[3] == nil)

    TestLib:DoUpdate()
    assert(t2:IsRoot() == true)
    assert(t2e.runTask:IsRoot() == false)
    assert(t2e.runTask.belongTree.root ==  t2)    
    
    assert(t1:IsKilled() == true)
    assert(t2:IsKilled() == false)
    assert(t2e:IsKilled() == false)

    t2:Kill()
    assert(t2:IsKilled() == true)
    assert(t2e:IsKilled() == true)


    assert(isFinish == false)
end


function Test_Tree:All()
    self:TwoTree()
    self:TwoTree_TwoLife()
end

return Test_Tree