-- Destroy old GUI to prevent overlapping
if game.CoreGui:FindFirstChild("BurningsAdminPanelGui") then
    game.CoreGui.BurningsAdminPanelGui:Destroy()
end

-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Global Configuration & States
local AuthorizedUsername = "NotBurning2000"
local TargetWalkSpeed = 16
local TargetFlySpeed = 50
local IsFlying = false
local IsNoclipping = false
local ToggleKey = Enum.KeyCode.RightShift
local EspActive = false
local SelectedTeams = {} 
local ActiveEspConnections = {} 
local flightConnection, noclipConnection, bodyGyro, bodyVel

-- Fling Target Storage
local SelectedFlingTarget = ""

-- --- CREATE GUI LAYOUT ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BurningsAdminPanelGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

-- --- SLEEK LOADING FRAME ---
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(0, 260, 0, 130)
LoadingFrame.Position = UDim2.new(0.5, -130, 0.4, -65)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui
Instance.new("UICorner", LoadingFrame).CornerRadius = UDim.new(0, 8)

local LoadTitle = Instance.new("TextLabel")
LoadTitle.Size = UDim2.new(1, 0, 0, 30)
LoadTitle.Position = UDim2.new(0, 0, 0.15, 0)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "Verifying Credentials..."
LoadTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
LoadTitle.Font = Enum.Font.SourceSansBold
LoadTitle.TextSize = 14
LoadTitle.Parent = LoadingFrame

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(1, 0, 0, 20)
LoadStatus.Position = UDim2.new(0, 0, 0.4, 0)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "Checking User Identity..."
LoadStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
LoadStatus.Font = Enum.Font.SourceSans
LoadStatus.TextSize = 12
LoadStatus.Parent = LoadingFrame

local BarBG = Instance.new("Frame")
BarBG.Size = UDim2.new(0.8, 0, 0, 6)
BarBG.Position = UDim2.new(0.1, 0, 0.65, 0)
BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
BarBG.BorderSizePixel = 0
BarBG.Parent = LoadingFrame
Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBG
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

-- --- MAIN ADMIN PANEL ---
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 270)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false -- Starts hidden during verification
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Tab Switch Logic
local pages = {}
local function makePage(name, visible)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, -40)
    page.Position = UDim2.new(0, 0, 0, 40)
    page.BackgroundTransparency = 1
    page.CanvasSize = UDim2.new(0, 0, 0, 360) -- Tall canvas to scroll both Server utility & new Fling sections
    page.ScrollBarThickness = 3
    page.Visible = visible
    page.Parent = MainFrame
    local lay = Instance.new("UIListLayout")
    lay.Parent = page
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 6)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    pages[name] = page
    return page
end

local MovePage = makePage("Move", true)
local CombatPage = makePage("Combat", false)
local AdminPage = makePage("Admin", false)
local MiscPage = makePage("Misc", false)

-- Navigation Buttons
local nav = Instance.new("Frame")
nav.Size = UDim2.new(1, 0, 0, 35)
nav.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
nav.Parent = MainFrame
Instance.new("UICorner", nav).CornerRadius = UDim.new(0, 8)

local function tabBtn(text, pos, pageName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.2, 0, 0, 25)
    btn.Position = pos
    btn.BackgroundColor3 = pageName == "Move" and Color3.fromRGB(40, 40, 55) or Color3.fromRGB(20, 20, 28)
    btn.Text = text
    btn.TextColor3 = pageName == "Move" and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = nav
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        for pName, pObj in pairs(pages) do pObj.Visible = (pName == pageName) end
        for _, otherBtn in ipairs(nav:GetChildren()) do
            if otherBtn:IsA("TextButton") and otherBtn.Text ~= "[-]" then
                otherBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
                otherBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        btn.TextColor3 = Color3.fromRGB(255, 60, 60)
    end)
end

tabBtn("Move", UDim2.new(0, 5, 0, 5), "Move")
tabBtn("Combat", UDim2.new(0.2, 10, 0, 5), "Combat")
tabBtn("Admins", UDim2.new(0.4, 15, 0, 5), "Admin")
tabBtn("Misc", UDim2.new(0.6, 20, 0, 5), "Misc")

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -30, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MinBtn.Text = "[-]"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.Parent = nav
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

local isMin = false
MinBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    MainFrame:TweenSize(isMin and UDim2.new(0, 260, 0, 35) or UDim2.new(0, 260, 0, 270), "Out", "Quart", 0.2, true)
    MinBtn.Text = isMin and "[+]" or "[-]"
    for _, p in pairs(pages) do p.Visible = not isMin and (p.Parent.Name == p.Name) or false end
end)

-- --- PAGE ELEMENTS ---
-- Status Text (Global Layout Header)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(0.9, 0, 0, 20)
status.BackgroundTransparency = 1
status.Text = "Status: Online"
status.TextColor3 = Color3.fromRGB(150, 255, 150)
status.Font = Enum.Font.SourceSansBold
status.TextSize = 12
status.Parent = MovePage

-- Inputs Utility
local function createInputRow(parent, labelText, defaultVal)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(0.9, 0, 0, 25)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.45, 0, 1, 0)
    box.Position = UDim2.new(0.55, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    box.Text = defaultVal
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.SourceSansBold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    return box
end

local WalkBox = createInputRow(MovePage, "Walk Speed:", "16")
local FlyBox = createInputRow(MovePage, "Fly Speed:", "50")

-- Action Buttons Utility
local function quickBtn(parent, text, bgCol, clickCallback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.BackgroundColor3 = bgCol
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() clickCallback(btn) end)
    return btn
end

-- Teleport Tool
local TpRow = Instance.new("Frame")
TpRow.Size = UDim2.new(0.9, 0, 0, 26)
TpRow.BackgroundTransparency = 1
TpRow.Parent = MovePage

local TpInput = Instance.new("TextBox")
TpInput.Size = UDim2.new(0.6, 0, 1, 0)
TpInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TpInput.PlaceholderText = "Username..."
TpInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
TpInput.Text = ""
TpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TpInput.Font = Enum.Font.SourceSansBold
TpInput.TextSize = 12
TpInput.Parent = TpRow
Instance.new("UICorner", TpInput).CornerRadius = UDim.new(0, 4)

local TpBtn = Instance.new("TextButton")
TpBtn.Size = UDim2.new(0.35, 0, 1, 0)
TpBtn.Position = UDim2.new(0.65, 0, 0, 0)
TpBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
TpBtn.Text = "Teleport"
TpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TpBtn.Font = Enum.Font.SourceSansBold
TpBtn.TextSize = 12
TpBtn.Parent = TpRow
Instance.new("UICorner", TpBtn).CornerRadius = UDim.new(0, 4)

-- Combat ESP Elements
local EspBtn = quickBtn(CombatPage, "ESP: OFF", Color3.fromRGB(180, 40, 40), function(btn)
    EspActive = not EspActive
    btn.Text = EspActive and "ESP: ACTIVE" or "ESP: OFF"
    btn.BackgroundColor3 = EspActive and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(180, 40, 40)
end)

local TeamScroll = Instance.new("ScrollingFrame")
TeamScroll.Size = UDim2.new(0.9, 0, 0, 120)
TeamScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TeamScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TeamScroll.ScrollBarThickness = 2
TeamScroll.Parent = CombatPage
local TeamLay = Instance.new("UIListLayout")
TeamLay.Parent = TeamScroll
TeamLay.Padding = UDim.new(0, 4)

-- Admins Elements
local AdminCard = Instance.new("Frame")
AdminCard.Size = UDim2.new(0.9, 0, 0, 60)
AdminCard.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
AdminCard.Parent = AdminPage
Instance.new("UICorner", AdminCard).CornerRadius = UDim.new(0, 6)

local Profile = Instance.new("ImageLabel")
Profile.Size = UDim2.new(0, 46, 0, 46)
Profile.Position = UDim2.new(0, 8, 0.5, -23)
Profile.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
Profile.Parent = AdminCard
Instance.new("UICorner", Profile).CornerRadius = UDim.new(0, 23)

local AdminName = Instance.new("TextLabel")
AdminName.Size = UDim2.new(1, -65, 0, 20)
AdminName.Position = UDim2.new(0, 60, 0.15, 0)
AdminName.BackgroundTransparency = 1
AdminName.Text = "User: " .. AuthorizedUsername
AdminName.TextColor3 = Color3.fromRGB(255, 255, 255)
AdminName.Font = Enum.Font.SourceSansBold
AdminName.TextSize = 12
AdminName.TextXAlignment = Enum.TextXAlignment.Left
AdminName.Parent = AdminCard

local AdminId = Instance.new("TextLabel")
AdminId.Size = UDim2.new(1, -65, 0, 20)
AdminId.Position = UDim2.new(0, 60, 0.5, 0)
AdminId.BackgroundTransparency = 1
AdminId.Text = "Role: Panel Creator | Owner"
AdminId.TextColor3 = Color3.fromRGB(255, 60, 60)
AdminId.Font = Enum.Font.SourceSansBold
AdminId.TextSize = 11
AdminId.TextXAlignment = Enum.TextXAlignment.Left
AdminId.Parent = AdminCard

-- Setup profile image asynchronously
task.spawn(function()
    pcall(function()
        local id = Players:GetUserIdFromNameAsync(AuthorizedUsername)
        local thumb, ready = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        if ready then Profile.Image = thumb end
    end)
end)

-- --- FLIGHT & NOCLIP CONTROLLERS ---
local function handleNoclip()
    if IsNoclipping then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end

local function cleanFlight(hrp)
    if not hrp then return end
    for _, child in ipairs(hrp:GetChildren()) do
        if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then child:Destroy() end
    end
end

local function startFlight()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    cleanFlight(hrp)
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.cframe = hrp.CFrame
    bodyGyro.Parent = hrp
    
    bodyVel = Instance.new("BodyVelocity")
    bodyVel.velocity = Vector3.new(0, 0.1, 0)
    bodyVel.maxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Parent = hrp
    
    flightConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if not camera or not hrp or not bodyVel or not bodyGyro then return end
        
        local moveDir = Vector3.new(0, 0, 0)
        local uis = UserInputService
        
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        bodyVel.velocity = moveDir.Magnitude > 0 and moveDir.Unit * TargetFlySpeed or Vector3.new(0, 0, 0)
        bodyGyro.cframe = camera.CFrame
    end)
end

local function stopFlight()
    if flightConnection then flightConnection:Disconnect() end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    cleanFlight(hrp)
end

-- --- MOVEMENT BUTTON CALLS ---
local FlyBtn = quickBtn(MovePage, "FLY: OFF", Color3.fromRGB(180, 40, 40), function(btn)
    IsFlying = not IsFlying
    btn.Text = IsFlying and "FLY: ACTIVE" or "FLY: OFF"
    btn.BackgroundColor3 = IsFlying and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(180, 40, 40)
    if IsFlying then startFlight() else stopFlight() end
end)

local NoclipBtn = quickBtn(MovePage, "NOCLIP: OFF", Color3.fromRGB(180, 40, 40), function(btn)
    IsNoclipping = not IsNoclipping
    btn.Text = IsNoclipping and "NOCLIP: ACTIVE" or "NOCLIP: OFF"
    btn.BackgroundColor3 = IsNoclipping and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(180, 40, 40)
    if IsNoclipping then
        noclipConnection = RunService.Stepped:Connect(handleNoclip)
    elseif noclipConnection then
        noclipConnection:Disconnect()
    end
end)

-- --- ESP SYSTEM CORE ---
local function cleanESP(character)
    if not character then return end
    local hl = character:FindFirstChild("EspHighlight")
    local bill = character:FindFirstChild("EspBillboard")
    if hl then hl:Destroy() end
    if bill then bill:Destroy() end
end

local function applyESP(player)
    if player == LocalPlayer then return end
    if ActiveEspConnections[player.UserId] then
        ActiveEspConnections[player.UserId]:Disconnect()
        ActiveEspConnections[player.UserId] = nil
    end
    
    local function setup(char)
        if not EspActive then cleanESP(char) return end
        local t = player.Team
        if t and SelectedTeams[t] == false then cleanESP(char) return end
        
        local hrp = char:WaitForChild("HumanoidRootPart", 4)
        local head = char:WaitForChild("Head", 4)
        if not hrp or not head then return end
        
        local col = t and t.TeamColor.Color or Color3.fromRGB(0, 255, 100)
        
        local hl = char:FindFirstChild("EspHighlight") or Instance.new("Highlight")
        hl.Name = "EspHighlight"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.5
        hl.FillColor = col
        hl.OutlineColor = col
        hl.Parent = char
        
        local bill = char:FindFirstChild("EspBillboard") or Instance.new("BillboardGui")
        bill.Name = "EspBillboard"
        bill.AlwaysOnTop = true
        bill.Size = UDim2.new(0, 150, 0, 30)
        bill.StudsOffset = Vector3.new(0, 2.5, 0)
        bill.Adornee = head
        bill.Parent = char
        
        local lbl = bill:FindFirstChild("EspLabel") or Instance.new("TextLabel")
        lbl.Name = "EspLabel"
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = col
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextSize = 12
        lbl.Parent = bill
        
        ActiveEspConnections[player.UserId] = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not LocalPlayer.Character then return end
            local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp and hrp then
                local dist = math.round((myHrp.Position - hrp.Position).Magnitude)
                lbl.Text = player.Name .. " [" .. tostring(dist) .. "m]"
            end
        end)
    end
    
    if player.Character then setup(player.Character) end
    player.CharacterAdded:Connect(setup)
end

local function loopAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        applyESP(p)
    end
end

RunService.Heartbeat:Connect(function()
    if EspActive then loopAllPlayers() else
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then cleanESP(p.Character) end
        end
    end
end)

-- --- TEAM SELECTION INTERFACE ---
local function buildTeams()
    for _, old in ipairs(TeamScroll:GetChildren()) do
        if not old:IsA("UIListLayout") then old:Destroy() end
    end
    for _, t in ipairs(Teams:GetTeams()) do
        if SelectedTeams[t] == nil then SelectedTeams[t] = true end
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, 0, 0, 22)
        r.BackgroundTransparency = 1
        r.Parent = TeamScroll
        
        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 6, 0, 12)
        ind.Position = UDim2.new(0, 4, 0.5, -6)
        ind.BackgroundColor3 = t.TeamColor.Color
        ind.Parent = r
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 15, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = t.Name
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = r
        
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0, 35, 0, 16)
        cb.Position = UDim2.new(1, -40, 0.5, -8)
        cb.BackgroundColor3 = SelectedTeams[t] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(150, 40, 40)
        cb.Text = SelectedTeams[t] and "ON" or "OFF"
        cb.TextColor3 = Color3.fromRGB(255, 255, 255)
        cb.Font = Enum.Font.SourceSansBold
        cb.TextSize = 9
        cb.Parent = r
        Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 3)
        
        cb.MouseButton1Click:Connect(function()
            SelectedTeams[t] = not SelectedTeams[t]
            cb.BackgroundColor3 = SelectedTeams[t] and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(150, 40, 40)
            cb.Text = SelectedTeams[t] and "ON" or "OFF"
        end)
    end
end
Teams.ChildAdded:Connect(buildTeams)
Teams.ChildRemoved:Connect(buildTeams)
buildTeams()

-- --- MISC ENGINE ACTIONS ---
local Rejoin = quickBtn(MiscPage, "Rejoin Server", Color3.fromRGB(40, 40, 55), function()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait(0.2)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end)

local Hop = quickBtn(MiscPage, "Server Hop", Color3.fromRGB(40, 40, 55), function()
    local success, response = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if success and response then
        local data = game:GetService("HttpService"):JSONDecode(response)
        if data and data.data then
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and tonumber(s.playing) < tonumber(s.maxPlayers) then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
    end
end)

-- --- THE PHYSICAL FLING PHYSICS ENGINE ---
local function FlingPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then return end
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    
    local targetChar = targetPlayer.Character
    local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    
    if not myHrp or not myHum or not targetHrp then return end
    
    -- Secure & Cache Local Physics States
    local oldVelocity = myHrp.AssemblyLinearVelocity
    local oldCFrame = myHrp.CFrame
    
    -- Disable custom speed loop momentarily during flight
    local speedOverridden = TargetWalkSpeed
    TargetWalkSpeed = 0
    myHum.WalkSpeed = 0
    
    -- Strip Collisions
    local noclipLoop = RunService.Stepped:Connect(function()
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
    
    -- Spin & Fling Loop Execution
    local forceTime = 1.5 -- Spin target for 1.5s
    local start = os.clock()
    
    local flingVelocity = Vector3.new(99999, 99999, 99999)
    local flingRot = Vector3.new(0, 99999, 0)
    
    while os.clock() - start < forceTime do
        RunService.RenderStepped:Wait()
        if not targetHrp or not targetHrp.Parent or not myHrp then break end
        
        -- Orbit and ram the target physics block
        myHrp.CFrame = targetHrp.CFrame * CFrame.new(math.random(-1, 1), 0, math.random(-1, 1))
        myHrp.AssemblyLinearVelocity = flingVelocity
        myHrp.AssemblyAngularVelocity = flingRot
    end
    
    -- Clean & Re-align Local Physics States
    noclipLoop:Disconnect()
    myHrp.AssemblyLinearVelocity = oldVelocity
    myHrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    myChar:PivotTo(oldCFrame)
    
    -- Restore Movement speeds
    TargetWalkSpeed = speedOverridden
    myHum.WalkSpeed = TargetWalkSpeed
end

-- --- DROPDOWN & FLING INTERFACES ---
local DropdownHeader = Instance.new("TextLabel")
DropdownHeader.Size = UDim2.new(0.9, 0, 0, 20)
DropdownHeader.BackgroundTransparency = 1
DropdownHeader.Text = "Fling Engine (Username Dropdown):"
DropdownHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
DropdownHeader.Font = Enum.Font.SourceSansBold
DropdownHeader.TextSize = 12
DropdownHeader.TextXAlignment = Enum.TextXAlignment.Left
DropdownHeader.Parent = MiscPage

-- Selection Button (Displays current selected target)
local SelectBtn = Instance.new("TextButton")
SelectBtn.Size = UDim2.new(0.9, 0, 0, 25)
SelectBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SelectBtn.Text = "Select Target: [None]"
SelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectBtn.Font = Enum.Font.SourceSansBold
SelectBtn.TextSize = 11
SelectBtn.Parent = MiscPage
Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 4)

-- Scrolling list containing other players
local DropList = Instance.new("ScrollingFrame")
DropList.Size = UDim2.new(0.9, 0, 0, 100)
DropList.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
DropList.BorderSizePixel = 0
DropList.CanvasSize = UDim2.new(0, 0, 0, 0)
DropList.ScrollBarThickness = 3
DropList.Visible = false
DropList.Parent = MiscPage
Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 4)

local DropLayout = Instance.new("UIListLayout")
DropLayout.Parent = DropList
DropLayout.Padding = UDim.new(0, 3)

local function updateDropdown()
    for _, old in ipairs(DropList:GetChildren()) do
        if not old:IsA("UIListLayout") then old:Destroy() end
    end
    
    local canvasSize = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, 0, 0, 20)
            option.BackgroundTransparency = 1
            option.Text = p.Name
            option.TextColor3 = Color3.fromRGB(180, 180, 190)
            option.Font = Enum.Font.SourceSans
            option.TextSize = 11
            option.Parent = DropList
            canvasSize = canvasSize + 23
            
            option.MouseButton1Click:Connect(function()
                SelectedFlingTarget = p.Name
                SelectBtn.Text = "Select Target: " .. p.Name
                DropList.Visible = false
            end)
        end
    end
    DropList.CanvasSize = UDim2.new(0, 0, 0, canvasSize)
end

SelectBtn.MouseButton1Click:Connect(function()
    DropList.Visible = not DropList.Visible
    if DropList.Visible then updateDropdown() end
end)

Players.PlayerAdded:Connect(updateDropdown)
Players.PlayerRemoving:Connect(updateDropdown)

-- Run Fling on Dropdown Selected Player
local ExecuteFlingBtn = quickBtn(MiscPage, "Fling Selected Player", Color3.fromRGB(220, 40, 40), function()
    local target = Players:FindFirstChild(SelectedFlingTarget)
    if target then FlingPlayer(target) end
end)

-- Team Fling Interface Row
local TeamFlingRow = Instance.new("Frame")
TeamFlingRow.Size = UDim2.new(0.9, 0, 0, 26)
TeamFlingRow.BackgroundTransparency = 1
TeamFlingRow.Parent = MiscPage

local TeamFlingInput = Instance.new("TextBox")
TeamFlingInput.Size = UDim2.new(0.6, 0, 1, 0)
TeamFlingInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TeamFlingInput.PlaceholderText = "Team Name..."
TeamFlingInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
TeamFlingInput.Text = ""
TeamFlingInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TeamFlingInput.Font = Enum.Font.SourceSansBold
TeamFlingInput.TextSize = 12
TeamFlingInput.Parent = TeamFlingRow
Instance.new("UICorner", TeamFlingInput).CornerRadius = UDim.new(0, 4)

local TeamFlingBtn = Instance.new("TextButton")
TeamFlingBtn.Size = UDim2.new(0.35, 0, 1, 0)
TeamFlingBtn.Position = UDim2.new(0.65, 0, 0, 0)
TeamFlingBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
TeamFlingBtn.Text = "Fling Team"
TeamFlingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeamFlingBtn.Font = Enum.Font.SourceSansBold
TeamFlingBtn.TextSize = 11
TeamFlingBtn.Parent = TeamFlingRow
Instance.new("UICorner", TeamFlingBtn).CornerRadius = UDim.new(0, 4)

TeamFlingBtn.MouseButton1Click:Connect(function()
    local q = string.lower(TeamFlingInput.Text)
    local targetTeam = nil
    for _, t in ipairs(Teams:GetTeams()) do
        if string.sub(string.lower(t.Name), 1, #q) == q then
            targetTeam = t
            break
        end
    end
    if targetTeam then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team == targetTeam then
                FlingPlayer(p)
                task.wait(0.2)
            end
        end
    end
end)

-- Fling All System Button
local FlingAllBtn = quickBtn(MiscPage, "Fling All Players", Color3.fromRGB(160, 20, 20), function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            FlingPlayer(p)
            task.wait(0.2) -- Tiny safety delay between flings
        end
    end
end)

local BindBox = createInputRow(MiscPage, "Toggle Keybind:", "RightShift")

-- --- INTERACTION ACTION TRIGGERS ---
WalkBox.FocusLost:Connect(function()
    local n = tonumber(WalkBox.Text)
    TargetWalkSpeed = n and math.clamp(n, 0, 500) or TargetWalkSpeed
    WalkBox.Text = tostring(TargetWalkSpeed)
end)

-- Fly settings update
FlyBox.FocusLost:Connect(function()
    local n = tonumber(FlyBox.Text)
    TargetFlySpeed = n and math.clamp(n, 0, 500) or TargetFlySpeed
    FlyBox.Text = tostring(TargetFlySpeed)
end)

BindBox.FocusLost:Connect(function()
    local success, key = pcall(function() return Enum.KeyCode[BindBox.Text] end)
    if success and key then ToggleKey = key else BindBox.Text = tostring(ToggleKey.Name) end
end)

UserInputService.InputBegan:Connect(function(inp, proc)
    if not proc and inp.KeyCode == ToggleKey then MainFrame.Visible = not MainFrame.Visible end
end)

-- Teleport Logic
TpBtn.MouseButton1Click:Connect(function()
    local partial = string.lower(TpInput.Text)
    if partial == "" then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (string.sub(string.lower(p.Name), 1, #partial) == partial or string.sub(string.lower(p.DisplayName), 1, #partial) == partial) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                LocalPlayer.Character:PivotTo(p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3))
                status.Text = "Status: Teleported to " .. p.Name
                task.wait(1)
                status.Text = "Status: Online"
            end
            break
        end
    end
end)

-- Core Speed Tick Frame Loop
task.spawn(function()
    while task.wait(0.1) do
        if not IsFlying then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = TargetWalkSpeed end
        end
    end
end)

-- --- VERIFICATION AND ANIMATED LOADING SEQUENCE ---
task.spawn(function()
    task.wait(0.5)
    
    -- Step 1: Loading Assets
    LoadStatus.Text = "Initializing Interface Assets..."
    local fill1 = TweenService:Create(BarFill, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0.4, 0, 1, 0)})
    fill1:Play()
    fill1.Completed:Wait()
    task.wait(0.3)
    
    -- Step 2: Verification Check
    LoadStatus.Text = "Checking User Authorization..."
    local fill2 = TweenService:Create(BarFill, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0.7, 0, 1, 0)})
    fill2:Play()
    fill2.Completed:Wait()
    
    -- AUTHENTICATION LOGIC
    if LocalPlayer.Name == AuthorizedUsername then
        -- Access Granted
        LoadStatus.Text = "Access Granted! Loading Panel..."
        LoadStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        local fill3 = TweenService:Create(BarFill, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
        fill3:Play()
        fill3.Completed:Wait()
        task.wait(0.4)
        
        -- Fade loading screen out and open main panel
        local fadeOut = TweenService:Create(LoadingFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        TweenService:Create(LoadTitle, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(LoadStatus, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(BarBG, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        TweenService:Create(BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
        
        fadeOut:Play()
        fadeOut.Completed:Wait()
        LoadingFrame:Destroy()
        
        -- Show Main Admin Panel
        MainFrame.Visible = true
    else
        -- Access Denied (Non-Authorized User)
        LoadStatus.Text = "Access Denied: Unauthorized User!"
        LoadStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        BarFill.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(1.5)
        
        -- Kick the player from the game
        LocalPlayer:Kick("\n[Burnings Admin Panel]\n\nSecurity System Triggered: Access Denied.")
    end
end)