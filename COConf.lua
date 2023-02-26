function CO.GetDebugFlag()
    return true
end




function COLogDebug(msg,...)
    print(string.format(msg,...))
end

function COLogInfo(msg,...)
    print(string.format(msg,...))
end

function COLogWarn(msg,...)
    print(string.format(msg,...))
end

function COLogError(msg,...)
    print(string.format(msg,...))
end

function SetDefault(value,defaultValue)
    if value ~= nil then
        return value
    end
    return defaultValue
end



function CO.SafeCall(f,...)
    local function try2(callf)
        -- try to call it
        local ok, res = xpcall(callf,function (errorMsg)
            COLogError(debug.traceback())
            return errorMsg
        end)
        if not ok then
            COLogError('error: %s',tostring(res))
            if res == nil then
                res = 'no error msg'
            end
        end
        -- ok?
        if not ok then
            return nil,res
        end
        return res,nil
    end
    


    if f == nil then
        return nil,false
    end
    local d = {...}
    local ret,err = try2(function ()
        return f(table.unpack(d))
    end)
        
    if err ~= nil then
        COLogError('[SafeCall] err = '.. err)
        return nil,false
    end
    return ret,true
end