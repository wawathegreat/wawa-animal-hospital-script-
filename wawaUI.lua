-- 1. Load the WawaUi library directly from GitHub
local WawaUi = loadstring(game:HttpGet("https://raw.githubusercontent.com/wawathegreat/WawaUi/main/WawaUI.lua"))()

-- Services & Setup
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local proximityPromptService = game:GetService("ProximityPromptService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local plr = players.LocalPlayer

-- Feature States
local autoHeartbeatActive = false
local npcEspActive = false
local instantPromptsActive = false
local activeHighlights = {}
local originalHoldDurations = {}

-- 2. Create Window and Tab
local Window = WawaUi.CreateWindow("wawa animal script")
local MainTab = Window:AddTab("rbxassetid://4483345998")

-- 3. Add Player Lost Sanity Toggle
MainTab:AddToggle(
    "Player Lost Sanity",
    "Triggers the PlayerLostSanity event",
    false,
    function(Value)
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
    "Skip Heartbeat",
    "Automatically bypasses the Heartbeat minigame",
    false,
    function(Value)
        autoHeartbeatActive = Value
    end
)

-- 5. Proximity Prompt Helper Functions
local function applyInstantPrompt(prompt)
    if not originalHoldDurations[prompt] then
        originalHoldDurations[prompt] = prompt.HoldDuration
    end
    prompt.HoldDuration = 0
end

local function restorePromptDuration(prompt)
    if originalHoldDurations[prompt] ~= nil then
        prompt.HoldDuration = originalHoldDurations[prompt]
    end
end

-- Hook onto new prompts as they appear
proximityPromptService.PromptShown:Connect(function(prompt)
    if instantPromptsActive then
        applyInstantPrompt(prompt)
    end
end)

-- Add Instant Proximity Prompts Toggle
MainTab:AddToggle(
    "Instant Proximity Prompts",
    "Removes hold time on all interaction prompts",
    false,
    function(Value)
        instantPromptsActive = Value
        if Value then
            for _, descendant in ipairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    applyInstantPrompt(descendant)
                end
            end
        else
            for prompt, _ in pairs(originalHoldDurations) do
                if prompt and prompt.Parent then
                    restorePromptDuration(prompt)
                end
            end
        end
    end
)

-- 6. NPC ESP Helper Functions
local function removeESP(model)
    if activeHighlights[model] then
        activeHighlights[model]:Destroy()
        activeHighlights[model] = nil
    end
end

local function applyESP(model)
    if not model:IsA("Model") then return end

    local isSkinwalker = model:GetAttribute("skinwalker") == true
    local targetColor = isSkinwalker and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)

    if activeHighlights[model] then
        activeHighlights[model].FillColor = targetColor
        return
    end

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

task.spawn(function()
    while true do
        task.wait(0.5)
        if npcEspActive then
            updateNPCHighlights()
        end
    end
end)

-- 7. Add NPC ESP Toggle
MainTab:AddToggle(
    "NPC Skinwalker ESP",
    "Highlights Skinwalker NPCs Red and Normal NPCs Green",
    false,
    function(Value)
        npcEspActive = Value
        updateNPCHighlights()
    end
)
