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

function Test_AsyncDo:ScrollNumber_Normal()
    local isFinish = false
    self:DoClean()
    local nums = {}
    local okNums = {0,25,50,75,100}
    CoroutineFactory:CreateTask('Root',function ()
        local e = CO.AsyncDo:ScrollNumber('ScrollNumber',0,100,4,function (curValue)
            table.insert(nums,curValue)
        end)
        local suc = CO.Wait:WaitEvent(e)
        assert(suc)
        for i = 1, #nums do
            print(nums[i])
            assert(nums[i] == okNums[i])
        end
        assert(CUR_FRAME == 5)
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end

function Test_AsyncDo:ScrollNumber_HurryUp()
    local isFinish = false
    self:DoClean()
    local nums = {}
    local okNums = {0,25,100}
    CoroutineFactory:CreateTask('Root',function ()
        local e = CO.AsyncDo:ScrollNumber('ScrollNumber',0,100,4,function (curValue)
            table.insert(nums,curValue)
        end)
        CO.Wait:WaitFrameCount(2)
        e:HurryUp()
        for i = 1, #nums do
            print(nums[i])
            assert(nums[i] == okNums[i])
        end
        assert(CUR_FRAME == 2)
        isFinish = true
    end)

    self:DoUpdate()
    assert(isFinish)
end


function Test_AsyncDo:All()
    self:ScrollNumber_Normal()
    self:ScrollNumber_HurryUp()
end


return Test_AsyncDo