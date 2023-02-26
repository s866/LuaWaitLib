---@class CoTree
local CoTree = {}

CO.CoTree = CoTree

---@param root Task
function CoTree.New(root)
    ---@type CoTree
    local o = {}

    setmetatable(o,{__index = CoTree})
    o:Init(root)
    return o
end

---@param root Task
function CoTree:Init(root)
    self.root = root

end


function CoTree:GetAllTagName()
    local tags = {}
    local nodes = self:GetNodes_BFS()
    for i = 1, #nodes do
        table.insert(tags,nodes[i].tag)
    end
    return tags
end

function CoTree:GetNodes_BFS()
    ---@type Task[]
    local nodes = {}
    local temp = {self.root}
    while #temp ~= 0 do
        local temp2 = {}
        for i = 1, #temp do
            local children = temp[i].children
            table.move(children,1,#children,#temp2 + 1,temp2)
        end
        table.move(temp,1,#temp,#nodes + 1,nodes)
        temp = temp2
    end
    return nodes
end

-- TODO
function CoTree:GetNodes_DFS()

end

function CoTree:Kill(triggerFailEvent)
    triggerFailEvent = SetDefault(triggerFailEvent,false)
    self.root:Kill(triggerFailEvent)
end
