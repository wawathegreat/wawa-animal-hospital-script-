-- 1. Load the WawaUi library
local WawaUi = loadstring(game:HttpGet("https://raw.githubusercontent.com/wawathegreat/WawaUi/main/WawaUI.lua"))()

-- Services & Setup
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local plr = players.LocalPlayer

local GameLib = require(replicatedStorage:WaitForChild("Lib"))

-- Feature States
local autoHeartbeatActive = false
local npcEspActive = false
local activeHighlights = {}

-- 2. Create Window and Tab
local Window = WawaUi.CreateWindow("wawa animal hospital script")
local MainTab = Window:AddTab("rbxassetid://4483345998")

-- 3. Add Player Lost Sanity Toggle
MainTab:AddToggle(
    "Player Lost Sanity",                  -- Title
    "Triggers the PlayerLostSanity event", -- Description
    false,                                 -- Default state
    function(Value)                        -- Callback
        if Value then
            local args = {
                [1] = 0/0,
                [2] = "Test",
                n = 2,
            }

            local net = replicatedStorage:WaitForChild("Util"):WaitForChild("Net")
            local remote = net:FindFirstChild("RE/PlayerLostSanity")

            if remote then
                remote:FireServer(unpack(args, 1, args.n or #args))
            end
        end
    end
)

-- 4. Add Skip Heartbeat Toggle
MainTab:AddToggle(
    "Skip Heartbeat",                               -- Title
    "Automatically bypasses the Heartbeat minigame", -- Description
    false,                                         -- Default State
    function(Value)                                -- Callback
        autoHeartbeatActive = Value
    end
)

-- 5. NPC ESP / Skinwalker Highlight Helper Functions
local function removeESP(model)
    if activeHighlights[model] then
        activeHighlights[model]:Destroy()
        activeHighlights[model] = nil
    end
end

local function applyESP(model)
    if not model:IsA("Model") then return end

    -- Check attribute condition
    local isSkinwalker = model:GetAttribute("skinwalker") == true
    local targetColor = isSkinwalker and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)

    -- If highlight already exists, just update color if changed
    if activeHighlights[model] then
        activeHighlights[model].FillColor = targetColor
        return
    end

    -- Create new Highlight instance
    local highlight = Instance.new("Highlight")
    highlight.FillColor = targetColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = model
    highlight.Parent = model

    activeHighlights[model] = highlight
end

local function updateNPCHighlights()
    if not npcEspActive then
        for model, _ in pairs(activeHighlights) do
            removeESP(model)
        end
        return
    end

    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, child in ipairs(npcsFolder:GetChildren()) do
            applyESP(child)
        end
    end
end

-- Periodically refresh NPC highlights while active
task.spawn(function()
    while true do
        task.wait(0.5)
        if npcEspActive then
            updateNPCHighlights()
        end
    end
end)

-- 6. Add NPC ESP Toggle
MainTab:AddToggle(
    "NPC Skinwalker ESP",                                   -- Title
    "Highlights Skinwalker NPCs Red and Normal NPCs Green", -- Description
    false,                                                 -- Default State
    function(Value)                                        -- Callback
        npcEspActive = Value
        updateNPCHighlights()
    end
)

-- 7. Minigame Override Logic
local function v33(p26)
    if autoHeartbeatActive then
        collectionService:AddTag(plr, "InMinigame")
        task.wait(0.1)
        GameLib.HeartMinigameComplete(true)
        collectionService:RemoveTag(plr, "InMinigame")
        return
    end
end

if GameLib.Inject then
    GameLib.Inject("StartCircleMinigame", v33)
    GameLib.Inject("EndCircleMinigame", function() 
        collectionService:RemoveTag(plr, "InMinigame") 
    end)
end
