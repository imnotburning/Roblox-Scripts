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

-- --- CREATE GUI LAYOUT ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BurningsAdminPanelGui"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 270)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -135)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Tab Switch Logic
local pages = {}
local function makePage(name, visible)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, -40)
    page.Position = UDim2.new(0, 0, 0, 40)
    page.BackgroundTransparency = 1
    page.CanvasSize = UDim2.new(0, 0, 0, 280)
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

local BindBox = createInputRow(MiscPage, "Toggle Keybind:", "RightShift")

-- --- INTERACTION ACTION TRIGGERS ---
WalkBox.FocusLost:Connect(function()
    local n = tonumber(WalkBox.Text)
    TargetWalkSpeed = n and math.clamp(n, 0, 500) or TargetWalkSpeed
    WalkBox.Text = tostring(TargetWalkSpeed)
end)

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