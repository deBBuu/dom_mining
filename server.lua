local Inventory = exports.ox_inventory

function BucketCheck(reward)
    local buckets = Inventory:GetItem(source, 'empty_bucket', nill, true)
    if buckets >= reward then 
        return true
    else 
        return false
    end 
end 

function NotEnoughBuckets()
    local cfg = Config.Notifications[1]
    lib.notify(source, cfg.MineNotEnoughBuckets)
end 

function NotEnoughSpace()
    local cfg = Config.Notifications[1]
    lib.notify(source, cfg.MineNotEnoughSpace)
end 

function NoTools()
    local cfg = Config.Notifications[1]
    lib.notify(source, cfg.MineNoTools)
end 

function ProcessCheck(input)
    local cfg = Config.Process[1]
    local sum = input[1]
    local buckets = Inventory:GetItem(source, 'full_bucket', nill, true)
    if buckets >= sum then 
        return true 
    else 
        TriggerClientEvent('dom_mining:ResetisProcess', source)
        return false 
    end 
end

function GemCheck() 
    local gems = Inventory:GetItem(source, 'gem_rock', nill, true)
        if gems >= 1 then 
            return true
        else 
            return false 
        end 
end 

RegisterNetEvent("mining:gemBreakdown", function()
    local cfg = Config.Notifications[1]
    if GemCheck() == true then 
        local success = Inventory:CanCarryItem(source, 'water', 1)
            if success then 
                TriggerClientEvent("mining:drillCircle", source)
            else 
                TriggerClientEvent('dom_mining:ResetisBreakdown', source)
                lib.notify(source, cfg.GemNotEnoughSpace)
            end 
    else
        TriggerClientEvent('dom_mining:ResetisBreakdown', source)
        lib.notify(source, cfg.GemNoRock)
    end 
    Wait(Config.Drill[1].Time)
end)

function CanMine(reward)
    local bucketCheck = BucketCheck(reward)
    if bucketCheck then 
        local success = Inventory:CanCarryItem(source, 'full_bucket', reward)
        if success then 
            return true 
        else
            TriggerClientEvent('dom_mining:ResetisMining', source)
            NotEnoughSpace()
        end 
    else 
        TriggerClientEvent('dom_mining:ResetisMining', source)
        NotEnoughBuckets()
    end 
end 

RegisterNetEvent("mining:mineRock", function(data)
    math.randomseed(os.time())
    local cfg = Config.Mining
    local jackhammer = Inventory:Search(source, 'count', 'jackhammer', false)
    local pickaxe = Inventory:Search(source, 'count', 'pickaxe', false)
    local shovel = Inventory:Search(source, 'count', 'shovel', false)

    if jackhammer >= 1 then 
        local time = cfg[1].Time
        local reward = math.random(cfg[1].MinReward, cfg[1].MaxReward)
        local animation = {
            dict = 'amb@world_human_const_drill@male@drill@base',
            clip = 'base'
        }
        local props = {
            model = 'prop_tool_jackham',
            bone = 28422,
            pos = vec3(0.05, 0.00, 0.00),
            rot = vec3(0.0, 0.0, 0.0)
        }
        if CanMine(reward) then 
            TriggerClientEvent("mining:progressBar", source, time, reward, data, animation, props)
            Wait(time)
        end
    elseif pickaxe >= 1 then 
        local time = cfg[2].Time
        local reward = math.random(cfg[2].MinReward, cfg[2].MaxReward)
        local animation = {
            dict = 'melee@large_wpn@streamed_core',
            clip = 'ground_attack_0'
        }
        local props = {
            model = 'prop_tool_pickaxe',
            bone = 28422,
            pos = vec3(0.05, 0.00, 0.00),
            rot = vec3(-70.0, 30.0, 0.0)
        }
        if CanMine(reward) then 
            TriggerClientEvent("mining:progressBar", source, time, reward, data, animation, props)
            Wait(time)
        end
    elseif shovel >= 1 then 
        local time = cfg[3].Time
        local reward = math.random(cfg[3].MinReward, cfg[3].MaxReward)
        local animation = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base'
        }
        local props = {
            model = 'prop_cs_trowel',
            bone = 28422,
            pos = vec3(0.00, 0.00, 0.00),
            rot = vec3(0.0, 0.0, -1.5)
        }
        if CanMine(reward) then 
            TriggerClientEvent("mining:progressBar", source, time, reward, data, animation, props)
            Wait(time)
        end
    else 
        TriggerClientEvent('dom_mining:ResetisMining', source)
        NoTools()
    end 
end)

RegisterNetEvent("mining:Process", function(input)
    local cfg = Config.Notifications[1]
    local gemRocks = math.floor(input[1] / Config.Process[1].GiveGemRock)
    
    if ProcessCheck(input) == true then 
        local amount = input[1]
        local processedMaterial = nil
        
        -- Calculate the total chance for all material options
        local totalChance = 0
        for _, option in ipairs(Config.Process[1].options) do
            totalChance = totalChance + option.chance
        end
        
        -- Generate a random number between 0 and totalChance
        local randomValue = math.random() * totalChance
        
        -- Determine the processed material based on the random value
        local cumulativeChance = 0
        for _, option in ipairs(Config.Process[1].options) do
            cumulativeChance = cumulativeChance + option.chance
            if randomValue <= cumulativeChance then
                processedMaterial = option.value
                break
            end
        end
        
        -- Process the dirt with the selected material
        -- Add your processing logic here
        
        TriggerClientEvent("mining:processCircle", source, input, gemRocks, processedMaterial) -- Pass processedMaterial as an additional parameter
        
    else 
        lib.notify(source, cfg.ProcessNoDirt)
    end 
    
    Wait(Config.Process[1].Time)
end)


RegisterNetEvent("mining:Reward", function(reward)
    Inventory:RemoveItem(source, 'empty_bucket', reward)
    Inventory:AddItem(source, 'full_bucket', reward)
end)

RegisterNetEvent("mining:processReward", function(input, gemRocks, processedMaterial)
    local cfg = Config.Process[1]
    Inventory:RemoveItem(source, cfg.ItemToProcess, input[1])
    Inventory:AddItem(source, processedMaterial, input[1])
    
    if gemRocks >= 1 then 
        Inventory:AddItem(source, 'gem_rock', gemRocks)
    end 
end)

RegisterNetEvent("mining:gemReward", function()
    local cfg = Config.Drill[1]
    local gems = Inventory:GetItem(source, 'gem_rock', nill, true)
    local amounts = {}
    
    for i = 1, gems do 
        local slot = math.random(1,#(cfg.Reward))

        if amounts[slot] == nill then 
            amounts[slot] = 0
        end 
        amounts[slot] = amounts[slot] + 1
    end 

    for i=1, #(cfg.Reward) do 
        Inventory:RemoveItem(source, 'gem_rock', gems)
        Inventory:AddItem(source, cfg.Reward[i], amounts[i])
    end 
end)
