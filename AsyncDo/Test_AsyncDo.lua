local Test_AsyncDo = {}
local CUR_FRAME = 0

function Test_AsyncDo:DoClean()
    CUR_FRAME = 0
end

function Test_AsyncDo:DoUpdate()
    for i = 1, 10 do
        CUR_FRAME = i
        print(string.format('frame %s',CUR_FRAME))
        CoroutineFactory:Update(1)
    end
    CoroutineFactory:Clean()
end

function Test_AsyncDo:ScrollNumber()
    local isFinish = false
    self:DoClean()
    local nums = {}
    local okNums = {0,25,50,75,100}
    CoroutineFactory:CreateTask('Root',function ()
        -- 刚启动第一帧没有deltaTime，所以需要跳过
        CO.Wait:WaitFrameCount(1)
        
        local e = CO.AsyncDo:ScrollNumber(0,100,4,function (curValue)
            table.insert(nums,curValue)
        end)
        local suc = CO.Wait:WaitEvent(e)
        assert(suc)
        for i = 1, #nums do
            print(nums[i])
            assert(nums[i] == okNums[i])
        end
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

function Test_AsyncDo:All()
    self:ScrollNumber()
end


return Test_AsyncDo