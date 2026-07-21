-- 1. Load your WawaUi library directly from GitHub
local WawaUi = loadstring(game:HttpGet("https://raw.githubusercontent.com/wawathegreat/WawaUi/main/WawaUI.lua"))()

-- Services & Setup
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local proximityPromptService = game:GetService("ProximityPromptService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local plr = players.LocalPlayer

-- Check if device is PC
local isPC = userInputService.KeyboardEnabled and not userInputService.TouchEnabled

-- Feature States
local autoHeartbeatActive = false
local npcEspActive = false
local instantPromptsActive = false
local activeHighlights = {}
local originalHoldDurations = {}

-- 2. Create Window and Tab via WawaUi
local Window = WawaUi.CreateWindow("wawa animal script")
local MainTab = Window:AddTab("rbxassetid://4483345998")

-- Helper to unlock/lock cursor when GUI state changes (PC only)
local guiVisible = true

local function updateCursorState(visible)
    if not isPC then return end
    if visible then
        userInputService.MouseBehavior = Enum.MouseBehavior.Default
        userInputService.MouseIconEnabled = true
    else
        userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end

-- Initialize cursor for PC users on startup
updateCursorState(true)

-- Listen for F key press to toggle (PC only)
if isPC then
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
            guiVisible = not guiVisible
            
            -- If your WawaUi library supports a .SetVisible or container toggle:
            if Window.Frame then
                Window.Frame.Visible = guiVisible
            end
            
            updateCursorState(guiVisible)
        end
    end)
end

-- 3. Add Toggles
MainTab:AddToggle(
    "Player Lost Sanity",
    "Triggers the PlayerLostSanity event",
    false,
    function(Value)
        if Value then
            local args = {[1] = 0/0, [2] = "Test", n = 2}
            local net = replicatedStorage:WaitForChild("Util"):WaitForChild("Net")
            local remote = net:FindFirstChild("RE/PlayerLostSanity")
            if remote then
                remote:FireServer(unpack(args, 1, args.n or #args))
            end
        end
    end
)

MainTab:AddToggle(
    "Skip Heartbeat",
    "Automatically bypasses the Heartbeat minigame",
    false,
    function(Value)
        autoHeartbeatActive = Value
    end
)

-- Proximity Prompt Logic
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

proximityPromptService.PromptShown:Connect(function(prompt)
    if instantPromptsActive then
        applyInstantPrompt(prompt)
    end
end)

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

-- NPC ESP
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

MainTab:AddToggle(
    "NPC Skinwalker ESP",
    "Highlights Skinwalker NPCs Red and Normal NPCs Green",
    false,
    function(Value)
        npcEspActive = Value
        updateNPCHighlights()
    end
)
