-- =====================================================
-- MeoXHub Extreme | Anti‑Cheat Max + Unlimited Features
-- =====================================================
-- Khởi tạo môi trường ẩn danh, xóa dấu vết
local OriginalEnv = getfenv()
local FakeEnv = setmetatable({}, { __index = OriginalEnv })
setfenv(0, FakeEnv)  -- ẩn script khỏi debug.getinfo

-- Ghi đè các hàm nguy hiểm để tránh bị phát hiện
local oldGetInfo = debug.getinfo
debug.getinfo = function(...)
    local args = {...}
    if args[2] and type(args[2]) == "number" and args[2] <= 2 then return nil end
    return oldGetInfo(...)
end

-- Biến toàn cục ẩn
getgenv().MeoX = getgenv().MeoX or {}
local MeoX = getgenv().MeoX
MeoX.Enabled = true

-- =================== HÀM VƯỢT TƯỜNG LỬA ===================
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CGui = game:GetService("CoreGui")
local Http = game:GetService("HttpService")
local WS = workspace
local Camera = WS.CurrentCamera

local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getRoot() return getChar():FindFirstChild("HumanoidRootPart") end
local function getHumanoid() return getChar():FindFirstChild("Humanoid") end

-- =================== ANTI‑CHEAT CỰC MẠNH ===================
local AntiCheat = {}

-- 1. Chặn gửi log, thông báo lỗi về server
local oldRemoteSend = nil
if game:GetService("ReplicatedStorage"):FindFirstChild("__REMOTES") then
    for _, rem in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
        if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
            local oldFire = rem.FireServer
            if oldFire then
                rem.FireServer = function(...)
                    local args = {...}
                    -- Nếu có từ khóa "cheat", "hack", "exploit" -> chặn
                    for _, v in ipairs(args) do
                        if type(v) == "string" and v:lower():match("cheat|hack|exploit|inject|script") then
                            return nil  -- ngăn gửi
                        end
                    end
                    return oldFire(...)
                end
            end
        end
    end
end

-- 2. Chặn hàm kick của game (nếu có)
local PlayersService = game:GetService("Players")
local oldKick = PlayersService.Kick
if oldKick then
    PlayersService.Kick = function() return nil end
end
local oldLocalKick = LP.Kick
if oldLocalKick then
    LP.Kick = function() return nil end
end

-- 3. Fake thông tin executor (ẩn dấu hiệu)
local execNames = {"Arceus X", "Hydrogen", "Codex", "Delta"}
setmetatable(_G, {
    __index = function(t, k)
        if k == "syn" or k == "krnl" or k == "fluxus" then
            return nil
        end
        return rawget(t, k)
    end
})

-- 4. Giám sát chat để phát hiện admin hoặc lệnh kick
AntiCheat.monitorChat = function()
    local chatEvent = game:GetService("ReplicatedStorage"):FindFirstChild("ChatEvent") 
        or game:GetService("ReplicatedFirst"):FindFirstChild("Chat")
    if chatEvent then
        chatEvent.OnClientEvent:Connect(function(msg, sender)
            if sender ~= LP.Name then
                if msg:lower():match("admin|mod|kick|ban|detect") then
                    warn("[AC] Nguy hiểm từ "..sender..": "..msg)
                    -- Tự động ẩn UI và tạm dừng script
                    if MeoX.UI then MeoX.UI.Enabled = false end
                    task.wait(10)
                    if MeoX.UI then MeoX.UI.Enabled = true end
                end
            end
        end)
    end
end

-- 5. Tự động re-execute nếu script bị xóa
local function selfHeal()
    local myScript = nil
    for _, v in ipairs(debug.getinfo(1).source:match("@?(.*)")) end -- lấy source
    local sourceCode = [[-- MeoX Extreme tự phục hồi
        if not getgenv().MeoX or not getgenv().MeoX.Enabled then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/MeoXHub_Extreme.lua"))()
        end
    ]]
    task.spawn(function()
        while MeoX.Enabled and task.wait(30) do
            -- Kiểm tra nếu script không còn hoạt động thì tải lại
            if not getgenv().MeoX or not getgenv().MeoX.Enabled then
                loadstring(sourceCode)()
            end
        end
    end)
end

-- 6. Chặn game ghi log ra console
local oldWrite = io.write
io.write = function(...) return nil end
local oldPrint = print
print = function(...) 
    local args = {...}
    for _, v in ipairs(args) do
        if type(v)=="string" and v:lower():match("exploit|cheat") then return nil end
    end
    return oldPrint(...)
end

-- =================== TÍNH NĂNG VÔ HẠN ===================
MeoX.Features = {
    Fly = false,
    Speed = false,
    Noclip = false,
    InfiniteJump = false,
    GodMode = false,
    ESP = false,
    Aimbot = false,
    AutoFarm = false,
    TeleportOnClick = false
}

MeoX.Settings = {
    FlySpeed = 150,
    WalkSpeed = 200,
    JumpPower = 120,
    AimbotFOV = 200,
    ESPColor = Color3.fromRGB(255,0,0)
}

-- Các kết nối để clean
local connections = {}
local function clearConnections()
    for _, c in pairs(connections) do if c then c:Disconnect() end end
    connections = {}
end

-- FLY siêu tốc
local flyBV = nil
local function startFly()
    if flyBV then flyBV:Destroy() end
    local root = getRoot()
    if not root then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
    flyBV.P = 1e6
    flyBV.Name = "ExtremeFly"
    flyBV.Parent = root
    local hum = getHumanoid()
    if hum then hum.PlatformStand = true end
    local function updateFly()
        if not MeoX.Features.Fly or not root.Parent then
            if flyBV then flyBV:Destroy() end
            if hum then hum.PlatformStand = false end
            return
        end
        local moveDir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0,0,-1) end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0,0,1) end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1,0,0) end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir + Vector3.new(0,-1,0) end
        local fwd = Camera.CFrame.LookVector
        local right = Camera.CFrame.RightVector
        local vel = (fwd * moveDir.Z + right * moveDir.X + Vector3.new(0, moveDir.Y, 0)) * MeoX.Settings.FlySpeed
        flyBV.Velocity = vel
    end
    if connections.fly then connections.fly:Disconnect() end
    connections.fly = RunS.RenderStepped:Connect(updateFly)
end

-- SPEED + JUMP POWER
local function applySpeedAndJump()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = MeoX.Features.Speed and MeoX.Settings.WalkSpeed or 16
        hum.JumpPower = MeoX.Features.InfiniteJump and MeoX.Settings.JumpPower or 50
    end
end

-- NOCLIP
local function noclipUpdate()
    if not MeoX.Features.Noclip then return end
    local char = getChar()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

-- GOD MODE (chặn sát thương)
local function godMode()
    local char = getChar()
    local hum = getHumanoid()
    if MeoX.Features.GodMode then
        hum.BreakJointsOnDeath = false
        hum.Health = hum.MaxHealth
        char:FindFirstChild("HumanoidRootPart").Anchored = false
        -- Hook xử lý sát thương
        local function onDamage(amt)
            if amt > 0 then return 0 end
            return amt
        end
        -- Override hàm TakeDamage
        local oldTakeDamage = hum.TakeDamage
        hum.TakeDamage = function(self, amt) return nil end
        connections.god = hum.HealthChanged:Connect(function(h)
            if h < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    else
        if hum.TakeDamage == (function() end) then hum.TakeDamage = oldTakeDamage end
        if connections.god then connections.god:Disconnect() end
    end
end

-- ESP (Box + Tên + Khoảng cách)
local espObjects = {}
local function updateESP()
    if not MeoX.Features.ESP then
        for _, obj in pairs(espObjects) do if obj and obj.Parent then obj:Destroy() end end
        espObjects = {}
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local box = espObjects[player.Name] or Instance.new("Frame")
                box.Size = UDim2.new(0, 100, 0, 200)
                box.BackgroundColor3 = MeoX.Settings.ESPColor
                box.BackgroundTransparency = 0.5
                box.BorderSizePixel = 0
                box.Parent = CGui
                local nameTag = Instance.new("TextLabel", box)
                nameTag.Size = UDim2.new(1,0,0,20)
                nameTag.Text = player.Name .. " | " .. math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude) .. "m"
                nameTag.TextColor3 = Color3.new(1,1,1)
                nameTag.BackgroundTransparency = 1
                box.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 100)
                espObjects[player.Name] = box
            else
                if espObjects[player.Name] then espObjects[player.Name]:Destroy() end
                espObjects[player.Name] = nil
            end
        end
    end
end

-- AIMBOT (tự động nhắm vào người chơi gần nhất)
local function aimbot()
    if not MeoX.Features.Aimbot then return end
    local closest = nil
    local minDist = MeoX.Settings.AimbotFOV
    local mousePos = UIS:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local screenPos, on = Camera:WorldToViewportPoint(root.Position)
            if on then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = root
                end
            end
        end
    end
    if closest then
        -- Nhắm camera vào vị trí đó
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
    end
end

-- AUTO FARM (ví dụ tự động tấn công quái hoặc thu thập)
local function autoFarm()
    if not MeoX.Features.AutoFarm then return end
    local nearestMob = nil
    local minDist = 50
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= getChar() then
            local dist = (getRoot().Position - obj.HumanoidRootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearestMob = obj
            end
        end
    end
    if nearestMob then
        getRoot().CFrame = nearestMob.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
        -- Giả lập đánh
        local hum = nearestMob:FindFirstChild("Humanoid")
        if hum then hum.Health = hum.Health - 10 end
    end
end

-- Teleport đến vị trí con trỏ chuột (click)
local function teleportToMouse()
    local mouse = LP:GetMouse()
    local target = mouse.Hit.p
    getRoot().CFrame = CFrame.new(target)
end

-- =================== GIAO DIỆN UI TỐI GIẢN NHƯNG MẠNH ===================
local function createExtremeUI()
    local sg = Instance.new("ScreenGui")
    sg.Name = "MeoX_Extreme"
    sg.ResetOnSpawn = false
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 600)
    frame.Position = UDim2.new(0.5, -250, 0.5, -300)
    frame.BackgroundColor3 = Color3.fromRGB(10,10,20)
    frame.BackgroundTransparency = 0.2
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,35)
    title.Text = "MeoX Extreme | Anti-Cheat MAX"
    title.BackgroundColor3 = Color3.fromRGB(100,0,0)
    title.TextColor3 = Color3.new(1,1,0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1,-20,1,-45)
    scroll.Position = UDim2.new(0,10,0,40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,800)
    scroll.ScrollBarThickness = 8
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 6)
    
    local function addBtn(text, cb)
        local b = Instance.new("TextButton", scroll)
        b.Size = UDim2.new(1,-10,0,45)
        b.BackgroundColor3 = Color3.fromRGB(40,40,60)
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.Gotham
        b.TextSize = 15
        b.MouseButton1Click:Connect(cb)
    end
    
    local function addToggle(text, key)
        local f = Instance.new("Frame", scroll)
        f.Size = UDim2.new(1,-10,0,40)
        f.BackgroundTransparency = 1
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(0.7,0,1,0)
        l.Text = text
        l.TextColor3 = Color3.new(0.8,0.8,0.8)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.BackgroundTransparency = 1
        local tb = Instance.new("TextButton", f)
        tb.Size = UDim2.new(0.25,0,0.8,0)
        tb.Position = UDim2.new(0.73,0,0.1,0)
        tb.BackgroundColor3 = Color3.fromRGB(70,70,90)
        tb.Text = MeoX.Features[key] and "ON" or "OFF"
        tb.TextColor3 = Color3.new(1,1,1)
        tb.MouseButton1Click:Connect(function()
            MeoX.Features[key] = not MeoX.Features[key]
            tb.Text = MeoX.Features[key] and "ON" or "OFF"
            if key == "Fly" then if MeoX.Features.Fly then startFly() else if flyBV then flyBV:Destroy() end end end
            if key == "Speed" or key == "InfiniteJump" then applySpeedAndJump() end
            if key == "Noclip" then 
                if MeoX.Features.Noclip then 
                    if connections.noclip then connections.noclip:Disconnect() end
                    connections.noclip = RunS.Stepped:Connect(noclipUpdate)
                else 
                    if connections.noclip then connections.noclip:Disconnect() end
                end
            end
            if key == "GodMode" then godMode() end
        end)
    end
    
    -- Thêm các toggle
    addToggle("✈️ Fly", "Fly")
    addToggle("⚡ Speed (200)", "Speed")
    addToggle("🛡️ Noclip", "Noclip")
    addToggle("🦘 Infinite Jump", "InfiniteJump")
    addToggle("💪 God Mode", "GodMode")
    addToggle("👁️ ESP (Box+Name+Dist)", "ESP")
    addToggle("🎯 Aimbot (Mouse)", "Aimbot")
    addToggle("🤖 Auto Farm (Mob)", "AutoFarm")
    addToggle("🔘 Teleport on Click", "TeleportOnClick")
    
    -- Slider đơn giản (dùng button +-)
    local speedFrame = Instance.new("Frame", scroll)
    speedFrame.Size = UDim2.new(1,-10,0,40)
    local speedLabel = Instance.new("TextLabel", speedFrame)
    speedLabel.Size = UDim2.new(0.5,0,1,0)
    speedLabel.Text = "Fly Speed: " .. MeoX.Settings.FlySpeed
    local plus = Instance.new("TextButton", speedFrame)
    plus.Size = UDim2.new(0.1,0,0.8,0)
    plus.Position = UDim2.new(0.6,0,0.1,0)
    plus.Text = "+"
    plus.MouseButton1Click:Connect(function()
        MeoX.Settings.FlySpeed = MeoX.Settings.FlySpeed + 10
        speedLabel.Text = "Fly Speed: " .. MeoX.Settings.FlySpeed
    end)
    local minus = Instance.new("TextButton", speedFrame)
    minus.Size = UDim2.new(0.1,0,0.8,0)
    minus.Position = UDim2.new(0.8,0,0.1,0)
    minus.Text = "-"
    minus.MouseButton1Click:Connect(function()
        MeoX.Settings.FlySpeed = math.max(10, MeoX.Settings.FlySpeed - 10)
        speedLabel.Text = "Fly Speed: " .. MeoX.Settings.FlySpeed
    end)
    
    addBtn("📍 Teleport to Mouse (Click)", function()
        teleportToMouse()
    end)
    addBtn("📌 Save Current Position", function()
        MeoX.SavedPos = getRoot().Position
        warn("Đã lưu vị trí")
    end)
    addBtn("📌 Teleport to Saved", function()
        if MeoX.SavedPos then getRoot().CFrame = CFrame.new(MeoX.SavedPos) end
    end)
    addBtn("🔄 Refresh Character", function()
        LP.Character:BreakJoints()
    end)
    addBtn("❌ Close UI", function()
        sg:Destroy()
        MeoX.UI = nil
    end)
    
    return sg
end

-- =================== KHỞI TẠO VÀ CHẠY NỀN ===================
local function startExtreme()
    MeoX.UI = createExtremeUI()
    MeoX.UI.Parent = CGui
    AntiCheat.monitorChat()
    selfHeal()
    
    -- ESP loop
    task.spawn(function()
        while MeoX.Enabled and task.wait(0.1) do
            if MeoX.Features.ESP then updateESP() end
            if MeoX.Features.Aimbot then aimbot() end
            if MeoX.Features.AutoFarm then autoFarm() end
            if MeoX.Features.TeleportOnClick and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                teleportToMouse()
                task.wait(0.5)
            end
        end
    end)
    
    -- Cập nhật khi nhân vật thay đổi
    LP.CharacterAdded:Connect(function()
        task.wait(0.3)
        applySpeedAndJump()
        if MeoX.Features.Fly then startFly() end
        if MeoX.Features.Noclip then 
            if connections.noclip then connections.noclip:Disconnect() end
            connections.noclip = RunS.Stepped:Connect(noclipUpdate)
        end
        if MeoX.Features.GodMode then godMode() end
    end)
    
    -- Phím tắt mở UI (RightShift)
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if MeoX.UI then
                MeoX.UI:Destroy()
                MeoX.UI = nil
            else
                MeoX.UI = createExtremeUI()
                MeoX.UI.Parent = CGui
            end
        end
    end)
    
    print("MeoX Extreme đã sẵn sàng! Nhấn RightShift để mở UI.")
end

startExtreme()