local CS = CraftStoreFixedAndImprovedLongClassName

-- With Gold Road, ZOS swapped the indices of ring and necklace
-- Migration of values in CS.Account.crafting.stored[7]
function CS.MigrateJewelryIdSwap()
    local function LinkedItemIsCheaperThanCurrentItemAndShouldReplaceIt(link, craft, line, trait)
        local q1, l1, v1 = GetItemLinkQuality(link), GetItemLinkRequiredLevel(link),
            GetItemLinkRequiredChampionPoints(link)

        -- safety check due to Dragonhold quests
        if CS.NilCheck(CS.Account.crafting.stored, {}, craft, line, trait) == {} then
            return true
        elseif CS.Account.crafting.stored[craft][line][trait] == nil or not CS.Account.crafting.stored[craft][line][trait].link then
            return true
        else
            local q2 = GetItemLinkQuality(CS.Account.crafting.stored[craft][line][trait].link)
            local l2 = GetItemLinkRequiredLevel(CS.Account.crafting.stored[craft][line][trait].link)
            local v2 = GetItemLinkRequiredChampionPoints(CS.Account.crafting.stored[craft][line][trait].link)
            if q1 < q2 then
                return true
            end
            if l1 < l2 then
                return true
            end
            if v1 < v2 then
                return true
            end
            return false
        end
    end

    local function deepcopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key)] = deepcopy(orig_value)
            end
            setmetatable(copy, deepcopy(getmetatable(orig)))
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end

    local function tablelength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end

    -- craft jewelry
    local jewelryCraft = 7

    -- safety check
    if CS.Account.crafting.stored[jewelryCraft] == nil then
        zo_callLater(
            function()
                CHAT_ROUTER:AddSystemMessage("[CraftStore] !!ERROR!! CS.Account.crafting.stored[" ..
                    tostring(jewelryCraft) .. "] not accessible. Skipping migration.")
            end, 50)
        return
    end

    local oldNecklaceLine = 1
    local oldRingLine = 2
    local newNecklaceLine = 2
    local newRingLine = 1
    local cache = nil

    for trait = 1, tablelength(CS.Account.crafting.stored[jewelryCraft][oldNecklaceLine]) do
        local oldNecklaceTraitData = CS.Account.crafting.stored[jewelryCraft][oldNecklaceLine][trait]
        local oldRingTraitData = CS.Account.crafting.stored[jewelryCraft][oldRingLine][trait]

        if CS.Debug then zo_callLater(function() CHAT_ROUTER:AddSystemMessage("trait " .. tostring(trait)) end, 50) end
        local actualLineOfOldNecklaceTraitData, actualLineOfOldRingTraitData = 0, 0

        if oldNecklaceTraitData.link ~= nil then
            _, actualLineOfOldNecklaceTraitData, _ = CS.GetTrait(oldNecklaceTraitData.link)
            if CS.Debug then
                zo_callLater(
                    function() CHAT_ROUTER:AddSystemMessage("line 1: " .. tostring(oldNecklaceTraitData.link)) end, 50)
            end
        else
            if CS.Debug then zo_callLater(function() CHAT_ROUTER:AddSystemMessage("line 1: {}") end, 50) end
        end
        if oldRingTraitData.link ~= nil then
            _, actualLineOfOldRingTraitData, _ = CS.GetTrait(oldRingTraitData.link)

            if CS.Debug then
                zo_callLater(
                    function() CHAT_ROUTER:AddSystemMessage("line 2: " .. tostring(oldRingTraitData.link)) end, 50)
            end
        else
            if CS.Debug then zo_callLater(function() CHAT_ROUTER:AddSystemMessage("line 2: {}") end, 50) end
        end

        -- ################## Actual migration start here ##################
        if actualLineOfOldNecklaceTraitData == 0 then
            -- line1 empty and line2 empty, nothing to do
            if actualLineOfOldRingTraitData == 0 then 
                if CS.Debug then
                    zo_callLater(
                        function() CHAT_ROUTER:AddSystemMessage("line1 empty and line2 empty, nothing to do") end, 50)
                end

            -- line1 empty and line2 not empty
            else
                if CS.Debug then
                    zo_callLater(
                        function() CHAT_ROUTER:AddSystemMessage("line1 empty and line2 not empty") end, 50)
                end
                if actualLineOfOldRingTraitData == newRingLine then
                    if CS.Debug then
                        zo_callLater(
                            function()
                                CHAT_ROUTER:AddSystemMessage("line2 wrong")
                            end,
                            50)
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("moving entry of line2 to line1") end, 50)
                    end
                    CS.Account.crafting.stored[jewelryCraft][newRingLine][trait] = deepcopy(oldRingTraitData)
                    CS.Account.crafting.stored[jewelryCraft][oldRingLine][trait] = {}

                else 
                    if CS.Debug then
                        zo_callLater(
                            function()
                                CHAT_ROUTER:AddSystemMessage("line2 correct, nothing to do")
                            end,
                            50)
                    end
                end
            end
        else
            if actualLineOfOldRingTraitData == 0 then -- line1 not empty and line2 empty
                if CS.Debug then
                    zo_callLater(
                        function() CHAT_ROUTER:AddSystemMessage("line1 not empty and line2 empty") end, 50)
                end
                if actualLineOfOldNecklaceTraitData == newNecklaceLine then
                    if CS.Debug then
                        zo_callLater(
                            function()
                                CHAT_ROUTER:AddSystemMessage("line1 wrong")
                            end, 50)

                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("moving entry of line1 to line2") end, 50)
                    end
                    CS.Account.crafting.stored[jewelryCraft][newNecklaceLine][trait] = deepcopy(oldNecklaceTraitData)
                    CS.Account.crafting.stored[jewelryCraft][oldNecklaceLine][trait] = {}

                else 
                    if CS.Debug then
                        zo_callLater(
                            function()
                                CHAT_ROUTER:AddSystemMessage("line1 correct, nothing to do")
                            end,
                            50)
                    end
                end
            else -- line1 not empty and line2 not empty
                if CS.Debug then
                    zo_callLater(
                        function() CHAT_ROUTER:AddSystemMessage("line1 not empty and line2 not empty") end, 50)
                end
                -- line1 wrong and line2 wrong => swap entries
                if actualLineOfOldRingTraitData == newNecklaceLine and actualLineOfOldNecklaceTraitData == newRingLine then
                    if CS.Debug then
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("line1 wrong and line2 wrong => swap entries") end,
                            50)
                    end
                    cache = deepcopy(oldNecklaceTraitData)
                    CS.Account.crafting.stored[jewelryCraft][newRingLine][trait] = deepcopy(oldRingTraitData)
                    CS.Account.crafting.stored[jewelryCraft][newNecklaceLine][trait] = cache

                    -- line1 wrong and line2 correct => two actions:
                    --   1. Compare entries of line1 and line2. If entry from line1 is cheaper than current entry in line2: replace entry of line2 with entry of line1
                    --   2. Clear line1
                elseif actualLineOfOldRingTraitData == newNecklaceLine and actualLineOfOldNecklaceTraitData == newNecklaceLine then
                    if CS.Debug then
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("line1 wrong and line2 correct") end, 50)
                    end
                    if LinkedItemIsCheaperThanCurrentItemAndShouldReplaceIt(oldNecklaceTraitData.link, jewelryCraft, newNecklaceLine, trait) then
                        if CS.Debug then
                            zo_callLater(
                                function() CHAT_ROUTER:AddSystemMessage(
                                    "line1 cheaper than line2, replacing entry of line2 with line1") end, 50)
                        end
                        CS.Account.crafting.stored[jewelryCraft][newNecklaceLine][trait] = deepcopy(oldNecklaceTraitData)
                    else
                        if CS.Debug then
                            zo_callLater(
                                function() CHAT_ROUTER:AddSystemMessage(
                                    "line2 already cheaper or equal than line1, keeping line2") end, 50)
                        end
                    end
                    if CS.Debug then
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("clearing line1") end, 50)
                    end
                    CS.Account.crafting.stored[jewelryCraft][oldNecklaceLine][trait] = {}

                    -- line1 correct and line2 wrong => two actions:
                    --   1. Compare entries of line1 and line2. If entry from line2 is cheaper than current entry in line1: replace entry of line1 with entry of line2
                    --   2. Clear line2
                elseif actualLineOfOldRingTraitData == newRingLine and actualLineOfOldNecklaceTraitData == newRingLine then
                    if CS.Debug then
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("line1 correct and line2 wrong") end, 50)
                    end
                    if LinkedItemIsCheaperThanCurrentItemAndShouldReplaceIt(oldRingTraitData.link, jewelryCraft, newRingLine, trait) then
                        if CS.Debug then
                            zo_callLater(
                                function() CHAT_ROUTER:AddSystemMessage(
                                    "line2 cheaper than line1, replacing entry of line1 with line2") end, 50)
                        end
                        CS.Account.crafting.stored[jewelryCraft][newRingLine][trait] = deepcopy(oldRingTraitData)
                    else
                        if CS.Debug then
                            zo_callLater(
                                function() CHAT_ROUTER:AddSystemMessage(
                                    "line1 already cheaper or equal than line2, keeping line1") end, 50)
                        end
                    end
                    if CS.Debug then
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("clearing line2") end, 50)
                    end
                    CS.Account.crafting.stored[jewelryCraft][oldRingLine][trait] = {}

                    
                -- line1 correct and line2 correct => do nothing
                else 
                    if CS.Debug then
                        zo_callLater(
                            function() CHAT_ROUTER:AddSystemMessage("line1 correct and line2 correct, nothing to do") end, 50)
                    end
                end
            end
        end
        -- ################## End of actual migration ##################
    end
end
