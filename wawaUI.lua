-- Services & Setup
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local proximityPromptService = game:GetService("ProximityPromptService")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local plr = players.LocalPlayer

-- Feature States
local autoHeartbeatActive = false
local npcEspActive = false
local instantPromptsActive = false
local activeHighlights = {}
local originalHoldDurations = {}

-- ========================================================
-- 1. WAWA UI LIBRARY (WITH F KEY & CURSOR UNLOCK)
-- ========================================================
local Library = {}
Library.__index = Library

function Library.CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WawaUI_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false

    local CoreGui = game:GetService("CoreGui")
    if CoreGui:FindFirstChild(ScreenGui.Name) then
        CoreGui:FindFirstChild(ScreenGui.Name):Destroy()
    end
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 450, 0, 320)
    MainFrame.Position = UDim2.new(0.5, -225, 0.5, -160)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 8)
    TopBarCorner.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.Text = title or "Wawa UI"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 15
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TopBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    -- Function to update cursor state based on GUI visibility
    local function setGuiState(visible)
        ScreenGui.Enabled = visible
        if visible then
            userInputService.MouseBehavior = Enum.MouseBehavior.Default
            userInputService.MouseIconEnabled = true
        else
            userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end

    -- Initial setup: open GUI and unlock cursor
    setGuiState(true)

    CloseBtn.MouseButton1Click:Connect(function()
        setGuiState(false)
    end)

    -- Toggle GUI and Cursor Lock with the F key
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
            setGuiState(not ScreenGui.Enabled)
        end
    end)

    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, -20, 1, -50)
    Container.Position = UDim2.new(0, 10, 0, 42)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.ScrollBarThickness = 4
    Container.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = Container

    local WindowObj = {}

    function WindowObj:AddTab(icon)
        local TabObj = {}

        function TabObj:AddToggle(text, desc, default, callback)
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, -6, 0, 40)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            ToggleFrame.BorderSizePixel = 0
            ToggleFrame.Parent = Container

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 6)
            ToggleCorner.Parent = ToggleFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 0, 20)
            Label.Position = UDim2.new(0, 10, 0, 4)
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(240, 240, 240)
            Label.TextSize = 14
            Label.Font = Enum.Font.SourceSansBold
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.BackgroundTransparency = 1
            Label.Parent = ToggleFrame

            local DescLabel = Instance.new("TextLabel")
            DescLabel.Size = UDim2.new(1, -60, 0, 14)
            DescLabel.Position = UDim2.new(0, 10, 0, 22)
            DescLabel.Text = desc or ""
            DescLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
            DescLabel.TextSize = 11
            DescLabel.Font = Enum.Font.SourceSans
            DescLabel.TextXAlignment = Enum.TextXAlignment.Left
            DescLabel.BackgroundTransparency = 1
            DescLabel.Parent = ToggleFrame

            local ToggleBtn = Instance.new("TextButton")
            ToggleBtn.Size = UDim2.new(0, 40, 0, 22)
            ToggleBtn.Position = UDim2.new(1, -48, 0, 9)
            ToggleBtn.Text = ""
            ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)
            ToggleBtn.BorderSizePixel = 0
            ToggleBtn.Parent = ToggleFrame

            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 11)
            BtnCorner.Parent = ToggleBtn

            local State = default or false

            ToggleBtn.MouseButton1Click:Connect(function()
                State = not State
                ToggleBtn.BackgroundColor3 = State and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 70)
                if callback then
                    task.spawn(callback, State)
                end
            end)
        end

        return TabObj
    end

    return WindowObj
end

-- ========================================================
-- 2. MAIN SCRIPT LOGIC & TOGGLES
-- ========================================================
local Window = Library.CreateWindow("wawa animal script")
local MainTab = Window:AddTab("rbxassetid://4483345998")

-- Sanity Toggle
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

-- Skip Heartbeat Toggle
MainTab:AddToggle(
    "Skip Heartbeat",
    "Automatically bypasses the Heartbeat minigame",
    false,
    function(Value)
        autoHeartbeatActive = Value
    end
)

-- Instant Proximity Prompts
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
