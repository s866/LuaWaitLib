
local TestLib = {}
local CUR_FRAME = 0

function TestLib:DoClean()
    CUR_FRAME = 0
end

function TestLib:DoUpdate()
    for i = 1, 10 do
        CUR_FRAME = i
        print(string.format('frame %s',CUR_FRAME))
        CoroutineFactory:Update(1)
    end
    CoroutineFactory:Clean()
end

return TestLib