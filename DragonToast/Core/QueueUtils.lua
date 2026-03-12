-------------------------------------------------------------------------------
-- QueueUtils.lua
-- Shared FIFO queue helpers for internal addon state
--
-- Supported versions: TBC Anniversary, Retail, MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...
local QueueUtils = ns.QueueUtils

-------------------------------------------------------------------------------
-- Queue constructors
-------------------------------------------------------------------------------

function QueueUtils.New()
    return { first = 1, last = 0 }
end

-------------------------------------------------------------------------------
-- Queue operations
-------------------------------------------------------------------------------

function QueueUtils.Push(queue, item)
    queue.last = queue.last + 1
    queue[queue.last] = item
end

function QueueUtils.Pop(queue)
    if queue.first > queue.last then return nil end

    local item = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return item
end

function QueueUtils.Size(queue)
    return queue.last - queue.first + 1
end

function QueueUtils.Reset(queue)
    for index = queue.first, queue.last do
        queue[index] = nil
    end

    queue.first = 1
    queue.last = 0
end
