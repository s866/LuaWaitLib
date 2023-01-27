local Misc = {}
CO.Misc = Misc

function Misc:EnumValue2Name(eunm,enumValue)
    for key, value in pairs(eunm) do
        if value == enumValue then
            return key
        end
    end
    return ''
end

