-- **************************************************
-- 本测试时间间隔定为1s，和帧对应便于测试
-- **************************************************

require 'CoroutineFactory'

local Test = {}

local CUR_FRAME = 0

function Test:DoClean()
    CUR_FRAME = 0
end

function Test:DoUpdate()
    for i = 1, 10 do
        CUR_FRAME = i
        print(string.format('frame %s',CUR_FRAME))
        CoroutineFactory:Update(1)
    end
    CoroutineFactory:Clean()
end



---等0秒，当前帧执行
function Test:WaitZero_RunSameFrame()
    self:DoClean()
    CoroutineFactory:CreateTask('WaitZero_RunSameFrame',function ()
        assert(CUR_FRAME == 0)
        local e = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(0)
        end)
        COWait:WaitEvent(e)
        assert(CUR_FRAME == 0)

    end)

    self:DoUpdate()
end

---等一帧长度
function Test:WaitOneFrame_RunNextFrame1()
    local isFinish = false
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        print('WaitOneFrame_RunNextFrame1 start')
        assert(CUR_FRAME == 0)
        local e = CoroutineFactory:CreateEvent('Func',function ()
            print('wait start')
            COWait:Wait(1)
            print('wait end')
        end)
        COWait:WaitEvent(e)
        assert(CUR_FRAME == 1)
        print('WaitOneFrame_RunNextFrame1 end')
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

---event事件触发后，在同一帧resume所有等待该event的task
function Test:EventTrigger_OneSameFrame()
    local isFinish = false
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e = CoroutineFactory:CreateEvent('Func',function ()
            print('wait start')
            COWait:Wait(1)
            print('wait end')
        end)
        COWait:WaitEvent(e)
        assert(CUR_FRAME == 1)
        isFinish = true

    end)

    -- 翻转nextframe列表
    local temp = CoroutineFactory.Coroutines_NextFrameRun[2]
    CoroutineFactory.Coroutines_NextFrameRun[2] = CoroutineFactory.Coroutines_NextFrameRun[1]
    CoroutineFactory.Coroutines_NextFrameRun[1] = temp



    self:DoUpdate()
    assert(isFinish)
end

---多层嵌套的情况下，需要建立父子结构，使得可以killgroup
function Test:TagGroup()
    local isFinish = false
    self:DoClean()
    ---@type Task,Event
    local m,e = nil,nil
    e = CoroutineFactory:CreateEvent('Func',function ()
        print('wait start')
        COWait:Wait(1)
        assert(e.runTask.parent == m)
        print('wait end')
    end,false)

    m = CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        assert(e.runTask.parent == nil)
        assert(#m.children == 0)
        e:Run()
        assert(e.runTask.parent == m)
        assert(#m.children == 1)
        COWait:WaitEvent(e)
        assert(e.runTask.parent == nil)
        assert(#m.children == 0)
        assert(CUR_FRAME == 1)
        isFinish = true

    end,false)

    m:Run()
    self:DoUpdate()
    assert(isFinish)
end


---event超时，超时继续运行
function Test:EventTrigger_Timeout_Break()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e = CoroutineFactory:CreateEvent('Func',function ()
            print('wait start')
            COWait:Wait(100)
            print('wait end')
        end)
        local suc = COWait:WaitEvent(e,5,COWaitEnum_TimeoutOpt.Break)
        assert(suc == false)
        assert(CUR_FRAME == 5)

        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish == false)
end

---event超时，超时继续运行
function Test:EventTrigger_Timeout_Continue()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e = CoroutineFactory:CreateEvent('Func',function ()
            print('wait start')
            COWait:Wait(100)
            print('wait end')
        end)
        local suc = COWait:WaitEvent(e,5,COWaitEnum_TimeoutOpt.Continue)
        assert(suc == false)
        assert(CUR_FRAME == 5)

        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

---等待多个事件同时完成
function Test:WaitAllEvents()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e1 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(1)
            print('e1 end')
        end)
        local e2 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(2)
            print('e2 end')
        end)
        local e3 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(3)
            print('e3 end')
        end)

        local suc = COWait:WaitAllEvents({e1,e2,e3},5,COWaitEnum_TimeoutOpt.Continue)
        assert(CUR_FRAME == 3)
        print('wait end')
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)


end


function Test:WaitAllEvents_Error_DoNothing()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e1 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(1)
            error('WaitAllEvents_Error_DoNothing error')
        end)
        local suc = COWait:WaitAllEvents({e1},5,COWaitEnum_TimeoutOpt.Continue,{opt = COWaitEnum_EventErrorOpt.DoNothing})
        assert(e1:GetState() == TaskEnum_StateType.Error)
        assert(suc == false)
        assert(CUR_FRAME == 5)
        print('wait end')
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

function Test:WaitAllEvents_Error_ErrorAsSuccess()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e1 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(1)
            error('WaitAllEvents_Error_ErrorAsSuccess error')
        end)
        local suc = COWait:WaitAllEvents({e1},5,COWaitEnum_TimeoutOpt.Continue,{opt = COWaitEnum_EventErrorOpt.ErrorAsSuccess})
        assert(e1:GetState() == TaskEnum_StateType.Error)
        assert(suc == true)
        assert(CUR_FRAME == 1)
        print('wait end')
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

function Test:WaitAllEvents_Error_CallCustomFunc()
    local isFinish = false
    local called = false
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e1 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(1)
            error('WaitAllEvents_Error_CallCustomFunc error')
        end)
        local suc = COWait:WaitAllEvents({e1},5,COWaitEnum_TimeoutOpt.Continue,{
            opt = COWaitEnum_EventErrorOpt.CallCustomFunc,
            func = function (task)
                assert(task.tag == 'Func')
                called = true
            end
        })
        assert(e1:GetState() == TaskEnum_StateType.Error)
        assert(suc == false)
        assert(called == true)
        assert(CUR_FRAME == 5)
        print('wait end')
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end





function Test:WaitFrameCount()
    
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        COWait:WaitFrameCount(3)
        assert(CUR_FRAME == 3)
        COWait:WaitFrameCount(3)
        assert(CUR_FRAME == 6)
        print('wait end')
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)

end 


---kill在下一帧处理
function Test:Kill_OneNextFrameClean()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e1 = CoroutineFactory:CreateEvent('Func',function ()
            COWait:Wait(5)
            assert(false)
        end)
        e1:Kill()
        assert(#CoroutineFactory.Coroutines_NextFrameRun == 1)
        COWait:WaitFrameCount(1)
        for i = 1, #CoroutineFactory.Coroutines_NextFrameRun do
            assert(CoroutineFactory.Coroutines_NextFrameRun[i].tag ~= 'Func')
        end
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

---kill了之后清理child
function Test:Kill_Group()
    local isFinish = false
    
    self:DoClean()
    CoroutineFactory:CreateTask('WaitOneFrame_RunNextFrame1',function ()
        assert(CUR_FRAME == 0)
        local e2 = CoroutineFactory:CreateEvent('Func2',function ()
            COWait:Wait(5)
            assert(false)
        end,false)
        local e1 = CoroutineFactory:CreateEvent('Func1',function ()
            e2:Run()
            COWait:Wait(5)
            assert(false)
        end)
        e1:Kill()
        assert(e2:IsKilled())
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

function Test:Kill_Tag()
    local isFinish = false
    self:DoClean()
    ---@type Event,Event,Event
    local e1,e2,e3 = nil,nil,nil
    e1 = CoroutineFactory:CreateEvent('Func',function ()
        COWait:Wait(10)
    end)
    e2 = CoroutineFactory:CreateEvent('Func',function ()
        COWait:Wait(10)
    end)
    e3 = CoroutineFactory:CreateEvent('Func',function ()
        COWait:Wait(10)
    end)
    CoroutineFactory:KillByTag('Func')
    assert(e1:IsKilled())
    assert(e2:IsKilled())
    assert(e3:IsKilled())
    

    self:DoUpdate()

end




function Test:All()
    self:WaitZero_RunSameFrame()
    self:WaitOneFrame_RunNextFrame1()
    self:EventTrigger_OneSameFrame()
    self:TagGroup()
    self:EventTrigger_Timeout_Break()
    self:EventTrigger_Timeout_Continue()
    
    self:WaitAllEvents()
    self:WaitAllEvents_Error_DoNothing()
    self:WaitAllEvents_Error_ErrorAsSuccess()
    self:WaitAllEvents_Error_CallCustomFunc()


    self:WaitFrameCount()
    self:Kill_OneNextFrameClean()
    self:Kill_Group()
    self:Kill_Tag()
end

return Test

