
-- ANTI CLIENT / SERVER / ADMIN TOOL V999 – lá chắn tối đa không thể phá hủy
pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")
    local LogService = game:GetService("LogService")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer

    -- Hook mọi hàm gọi đến server (FireServer, InvokeServer)
    local mt = getrawmetatable(game)
    if setreadonly then setreadonly(mt, false) end
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "FireServer" or method == "InvokeServer" then
            for i, v in pairs(args) do
                if typeof(v) == "string" then
                    local txt = v:lower()
                    if txt:find("kick") or txt:find("ban") or txt:find("log") or txt:find("admin") or txt:find("report") or txt:find("detected") or txt:find("moderation") then
                        warn("[ANTI V999] Blocked suspicious remote:", v)
                        return nil
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    -- Hook Kick trực tiếp
    LocalPlayer.Kick = function(...) return warn("[ANTI V999] Kick blocked") end

    -- Chặn log ra ngoài hoặc stream data
    local function null() return nil end
    for _, fn in pairs({"print", "warn", "error", "debug", "traceback"}) do
        if typeof(_G[fn]) == "function" then _G[fn] = null end
        if typeof(console[fn]) == "function" then console[fn] = null end
    end
    pcall(function()
        LogService.MessageOut:Connect(function() return end)
    end)

    -- Chặn HTTP ra ngoài (webhook / log)
    if hookfunction and (syn and syn.request or http_request or request) then
        local req = syn and syn.request or http_request or request
        hookfunction(req, newcclosure(function(args)
            if typeof(args) == "table" and typeof(args.Url) == "string" then
                if args.Url:find("http") or args.Url:find("webhook") then
                    warn("[ANTI V999] Blocked external request:", args.Url)
                    return {Success = false, StatusCode = 403}
                end
            end
            return req(args)
        end))
    end

    -- Anti Admin Camera / Stream Mode
    RunService.Heartbeat:Connect(function()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not plr.Character then
                warn("[ANTI V999] Admin camera / stream detected:", plr.Name)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:MoveTo(Vector3.new(9999, 9999, 9999))
                end
            end
        end
    end)

    -- Block lệnh từ Tool hoặc ToolScript admin
    workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Tool") or obj.Name:lower():find("admin") then
            warn("[ANTI V999] Removed suspicious tool:", obj.Name)
            pcall(function() obj:Destroy() end)
        end
    end)
end)


-- ANTI ROBLOX TOOL – chặn các công cụ quản trị/phát hiện từ Roblox hoặc admin nội bộ
pcall(function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    -- Danh sách các tool nghi ngờ từ Roblox hoặc quản trị
    local suspicious_keywords = {
        "admin", "monitor", "log", "kick", "ban", "track", "tool", "remote", "handler", "detector"
    }

    -- Hàm kiểm tra tên tool nghi ngờ
    local function isSuspicious(name)
        name = name:lower()
        for _, keyword in pairs(suspicious_keywords) do
            if name:find(keyword) then return true end
        end
        return false
    end

    -- Xóa tool nghi ngờ trong workspace
    Workspace.DescendantAdded:Connect(function(obj)
        pcall(function()
            if obj:IsA("Tool") or obj:IsA("Script") or obj:IsA("ModuleScript") then
                if isSuspicious(obj.Name) then
                    warn("[ANTI ROBLOX TOOL] Removed suspicious object:", obj.Name)
                    obj:Destroy()
                end
            end
        end)
    end)

    -- Quét định kỳ toàn bộ workspace
    RunService.Heartbeat:Connect(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") or obj:IsA("Script") or obj:IsA("ModuleScript") then
                if isSuspicious(obj.Name) then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
end)


-- LỚP BẢO VỆ NÂNG CAO – Phát hiện, ngăn chặn hành vi bất thường ở cấp sâu hơn
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    -- Lọc UID / Player đáng ngờ (Admin mặc định Roblox có UserId nhỏ)
    local function isSuspiciousUser(plr)
        return plr.UserId <= 500 or plr.Name:lower():find("mod") or plr.Name:lower():find("admin")
    end

    -- Khi người chơi mới vào server
    Players.PlayerAdded:Connect(function(plr)
        task.wait(0.1)
        if isSuspiciousUser(plr) then
            warn("[LỚP BẢO VỆ] Blocked potential admin/mod:", plr.Name)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character:MoveTo(Vector3.new(9999,9999,9999))
            end
        end
    end)

    -- Phát hiện bất thường từ Remote / Event nội bộ (dạng lạ)
    local suspicious_remotes = {"RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction"}
    RunService.Heartbeat:Connect(function()
        for _, v in pairs(game:GetDescendants()) do
            if table.find(suspicious_remotes, v.ClassName) and v:IsA("Instance") then
                if v.Name:lower():find("kick") or v.Name:lower():find("ban") or v.Name:lower():find("log") then
                    warn("[LỚP BẢO VỆ] Suspicious remote removed:", v:GetFullName())
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end)

    -- Ngăn admin camera bí mật / invisible spectate
    RunService.Heartbeat:Connect(function()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and not plr.Character then
                warn("[LỚP BẢO VỆ] Admin ghost/spectate mode suspected:", plr.Name)
                LocalPlayer.Character:MoveTo(Vector3.new(math.random(9000,9999),9999,math.random(9000,9999)))
            end
        end
    end)
end)


-- LỚP FIREWALL VÔ CỰC – Quét toàn bộ instance, remote, tool, log, kick, UID, mạng...
pcall(function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    local dangerousKeywords = {
        "ban", "kick", "log", "report", "detect", "exploit", "track", "admin", "moderator",
        "remote", "handler", "monitor", "sync", "crash", "shutdown", "stream", "console"
    }

    local dangerousClasses = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "ModuleScript", "LocalScript", "Script", "Tool"
    }

    -- Deep Scan & Destroy
    local function deepScanAndDestroy()
        for _, obj in ipairs(game:GetDescendants()) do
            if table.find(dangerousClasses, obj.ClassName) then
                for _, word in ipairs(dangerousKeywords) do
                    if obj.Name:lower():find(word) then
                        warn("[FIREWALL VÔ CỰC] 🔥 Removed Threat:", obj.ClassName, obj:GetFullName())
                        pcall(function() obj:Destroy() end)
                        break
                    end
                end
            end
        end
    end

    -- UID Bảo vệ cấp cao
    local function uidProtect()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.UserId <= 500 then
                warn("[FIREWALL VÔ CỰC] ⚠️ Admin UID Blocked:", plr.Name)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character:MoveTo(Vector3.new(9999, 9999, 9999))
                end
            end
        end
    end

    -- Bảo vệ liên tục
    RunService.Heartbeat:Connect(function()
        pcall(deepScanAndDestroy)
        pcall(uidProtect)
    end)
end)


-- AI BẢO VỆ – Phân tích hành vi người chơi & phản ứng tự động chống lại nguy cơ
pcall(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local ThreatsDetected = {}

    local function isSuspiciousPlayer(plr)
        if plr == LocalPlayer then return false end
        local suspicious = false
        if plr.UserId <= 500 then suspicious = true end
        if plr.Name:lower():find("admin") or plr.Name:lower():find("mod") then suspicious = true end
        if plr:GetRoleInGroup and pcall(function() return plr:GetRoleInGroup(1) end) then
            local role = plr:GetRoleInGroup(1):lower()
            if role:find("admin") or role:find("mod") then suspicious = true end
        end
        return suspicious
    end

    local function autoEvade()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = Vector3.new(9999 + math.random(1,999), 8888 + math.random(1,999), 9999 + math.random(1,999))
            LocalPlayer.Character:MoveTo(pos)
            warn("[AI BẢO VỆ] 🛡️ Đã né khỏi vùng bị theo dõi:", tostring(pos))
        end
    end

    local function autoRespondToThreat(plr)
        if not ThreatsDetected[plr.UserId] then
            ThreatsDetected[plr.UserId] = true
            warn("[AI BẢO VỆ] 🚨 Mối đe dọa phát hiện:", plr.Name)
            autoEvade()
            -- Có thể kết hợp auto fake disconnect / change name / UI lock
        end
    end

    -- Theo dõi người chơi liên tục
    RunService.Heartbeat:Connect(function()
        for _, plr in pairs(Players:GetPlayers()) do
            if isSuspiciousPlayer(plr) then
                autoRespondToThreat(plr)
            end
        end
    end)
end)


-- AI QUẢN LÝ PHẦN MỀM ADMIN – theo dõi và xử lý phần mềm quản trị đáng ngờ
pcall(function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local AdminToolNames = {
        "admin", "panel", "control", "dashboard", "log", "kick", "ban", "mod", "report", "console"
    }

    local DetectedAdminModules = {}

    local function isAdminTool(obj)
        local name = obj.Name:lower()
        for _, keyword in pairs(AdminToolNames) do
            if name:find(keyword) then
                return true
            end
        end
        return false
    end

    local function respondToAdminTool(obj)
        if not DetectedAdminModules[obj] then
            DetectedAdminModules[obj] = true
            warn("[AI ADMIN MANAGER] ⚠️ Phần mềm quản trị nghi ngờ:", obj:GetFullName())

            -- Phản ứng: Xoá, dịch chuyển người chơi, hoặc làm sai lệch dữ liệu
            pcall(function() obj:Destroy() end)

            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character:MoveTo(Vector3.new(8888 + math.random(1,200), 9999, 8888 + math.random(1,200)))
                warn("[AI ADMIN MANAGER] 🛡️ Né phần mềm theo dõi admin")
            end
        end
    end

    -- Theo dõi toàn bộ workspace
    RunService.Heartbeat:Connect(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if (obj:IsA("Tool") or obj:IsA("Script") or obj:IsA("ModuleScript") or obj:IsA("Folder")) and isAdminTool(obj) then
                respondToAdminTool(obj)
            end
        end
    end)
end)


-- AI QUẢN LÝ SERVER – Theo dõi toàn hệ thống, đánh giá nguy cơ và phản ứng theo ngữ cảnh
pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local serverThreats = {}

    -- Ngưỡng UID thấp (admin Roblox), hoặc tên chứa từ khóa nghi ngờ
    local function isGlobalThreat(plr)
        local uid = plr.UserId or 0
        local name = plr.Name:lower()
        if uid <= 500 then return true end
        if name:find("admin") or name:find("mod") or name:find("dev") or name:find("rbx") then return true end
        return false
    end

    -- AI phản ứng nếu toàn server có dấu hiệu nguy hiểm
    local function serverDefend()
        warn("[AI SERVER MANAGER] 🛡️ Kích hoạt bảo vệ toàn server!")
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:MoveTo(Vector3.new(math.random(9999, 15000), 9999, math.random(9999, 15000)))
        end
    end

    -- Theo dõi hoạt động người chơi
    RunService.Heartbeat:Connect(function()
        local threatCount = 0
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and isGlobalThreat(plr) then
                if not serverThreats[plr.UserId] then
                    serverThreats[plr.UserId] = true
                    warn("[AI SERVER MANAGER] 🚨 Phát hiện user nguy hiểm:", plr.Name)
                end
                threatCount += 1
            end
        end

        -- Nếu có ≥ 2 mối đe doạ trong server → phòng thủ toàn hệ thống
        if threatCount >= 2 then
            serverDefend()
        end
    end)

    -- Dò tìm remote & event server-side khả nghi
    RunService.Stepped:Connect(function()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                if name:find("log") or name:find("kick") or name:find("ban") or name:find("admin") or name:find("mod") then
                    warn("[AI SERVER MANAGER] 🔥 Xoá remote nghi ngờ:", obj:GetFullName())
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
end)


-- HỆ THỐNG QUẢN LÝ TOÀN DIỆN NÂNG CAO – AI thống nhất bảo vệ tất cả lớp
pcall(function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer
    local ThreatDatabase = {}

    local DangerKeywords = {
        "admin", "mod", "log", "kick", "ban", "rbx", "console", "control", "panel",
        "stream", "report", "track", "monitor", "spy", "trace", "shut", "crash", "detect"
    }

    local DangerousClasses = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "ModuleScript", "Script", "LocalScript", "Tool", "Folder"
    }

    local function isThreatName(name)
        name = name:lower()
        for _, key in pairs(DangerKeywords) do
            if name:find(key) then return true end
        end
        return false
    end

    local function flagThreat(obj, reason)
        if not ThreatDatabase[obj] then
            ThreatDatabase[obj] = true
            warn("[HỆ THỐNG NÂNG CAO] ⚠️ THREAT:", obj.ClassName, obj:GetFullName(), "| Lý do:", reason)
            pcall(function() obj:Destroy() end)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character:MoveTo(Vector3.new(8888+math.random(1,500),9999,8888+math.random(1,500)))
            end
        end
    end

    -- Giám sát đối tượng nghi ngờ (toàn server)
    RunService.Heartbeat:Connect(function()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and (plr.UserId <= 500 or isThreatName(plr.Name)) then
                flagThreat(plr, "User nguy hiểm (UID thấp hoặc tên nghi ngờ)")
            end
        end

        -- Giám sát toàn bộ instance game
        for _, obj in pairs(game:GetDescendants()) do
            if table.find(DangerousClasses, obj.ClassName) and isThreatName(obj.Name) then
                flagThreat(obj, "Tên đối tượng chứa từ khoá độc hại")
            end
        end
    end)
end)


-- BẢO VỆ MỌI LỖ HỔNG VÔ CỰC – toàn diện mọi tầng: user, mạng, script, hook, log
pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local StarterGui = game:GetService("StarterGui")
    local LocalPlayer = Players.LocalPlayer

    local blockedKeywords = {
        "log", "ban", "kick", "track", "report", "error", "shutdown", "admin", "mod", "hook", "spy", "console",
        "remote", "inject", "trace", "debug", "monitor", "handler", "stream", "detect"
    }

    local blockedClasses = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "ModuleScript", "LocalScript", "Script", "Tool", "Folder"
    }

    -- Ngăn tất cả hook hoặc theo dõi
    local function unhook()
        getgenv().print = function() end
        getgenv().warn = function() end
        getgenv().error = function() end
        getgenv().debug = function() end
    end

    -- Xoá mọi lỗ hổng (theo tên, class)
    local function shieldAll()
        for _, obj in ipairs(game:GetDescendants()) do
            if table.find(blockedClasses, obj.ClassName) then
                for _, keyword in ipairs(blockedKeywords) do
                    if obj.Name:lower():find(keyword) then
                        warn("[LỖ HỔNG VÔ CỰC] 🔐 Khoá lỗ hổng:", obj:GetFullName())
                        pcall(function() obj:Destroy() end)
                        break
                    end
                end
            end
        end
    end

    -- Ngăn phá huỷ nhân vật hoặc reset data
    local function characterLock()
        if LocalPlayer and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = false
                    part.CanCollide = true
                end
            end
        end
    end

    -- Chặn mọi lỗi phát sinh
    game:GetService("LogService").MessageOut:Connect(function(msg, t)
        if msg:lower():find("error") or msg:lower():find("detected") then
            warn("[LỖ HỔNG VÔ CỰC] 🚫 Blocked message:", msg)
        end
    end)

    -- Thực thi bảo vệ liên tục
    RunService.Heartbeat:Connect(function()
        pcall(unhook)
        pcall(shieldAll)
        pcall(characterLock)
    end)
end)


-- CHẶN TẤT CẢ QUYỀN QUẢN TRỊ ADMIN – không cho phép bất kỳ quyền lực hoặc công cụ nào từ admin
pcall(function()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local blockedNames = {
        "admin", "mod", "moderator", "staff", "kick", "ban", "control", "panel", "dashboard", "tool", "remote", "console"
    }

    local function nameIsBlocked(name)
        name = name:lower()
        for _, word in pairs(blockedNames) do
            if name:find(word) then return true end
        end
        return false
    end

    local function blockAdminInstances()
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("Tool") or obj:IsA("Script") then
                if nameIsBlocked(obj.Name) then
                    warn("[BLOCK ADMIN] ⚠️ Xoá quyền lực hoặc công cụ:", obj:GetFullName())
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end

    local function blockAdminPlayers()
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local lowerName = plr.Name:lower()
                if nameIsBlocked(lowerName) or plr.UserId <= 500 then
                    warn("[BLOCK ADMIN] 🚫 Vô hiệu người chơi có quyền lực:", plr.Name)
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character:MoveTo(Vector3.new(math.random(8888, 9999), 9999, math.random(8888, 9999)))
                    end
                end
            end
        end
    end

    RunService.Heartbeat:Connect(function()
        pcall(blockAdminInstances)
        pcall(blockAdminPlayers)
    end)
end)


-- KHOÁ MỌI HỆ THỐNG ADMIN VÀ ROBLOX – chặn toàn bộ quyền lực, tools, hệ thống theo dõi từ server
pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local keywords = {
        "admin", "staff", "mod", "kick", "ban", "log", "report", "console", "control",
        "dashboard", "remote", "shutdown", "track", "rbx", "detector", "server", "spectate"
    }

    local classes = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "ModuleScript", "Script", "LocalScript", "Tool", "Folder"
    }

    local function match(str)
        str = str:lower()
        for _, k in pairs(keywords) do
            if str:find(k) then return true end
        end
        return false
    end

    local function fullLock()
        for _, obj in pairs(game:GetDescendants()) do
            if table.find(classes, obj.ClassName) and match(obj.Name) then
                warn("[KHOÁ HỆ THỐNG] 🔒 Xoá:", obj:GetFullName())
                pcall(function() obj:Destroy() end)
            end
        end
    end

    local function autoKickShield()
        -- Ngăn admin dùng kick server-side
        if LocalPlayer.Character and LocalPlayer:FindFirstChild("Kick") then
            warn("[KHOÁ HỆ THỐNG] 🛡️ Phát hiện chức năng kick – xoá ngay")
            pcall(function() LocalPlayer:FindFirstChild("Kick"):Destroy() end)
        end
    end

    RunService.Heartbeat:Connect(function()
        pcall(fullLock)
        pcall(autoKickShield)
    end)
end)


-- LỚP BẢO VỆ HỒI SINH VÔ CỰC – auto phục hồi nếu bị phá huỷ, reset, xoá script
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local scriptBackup = {}

    -- Tạo bản sao ẩn của các thành phần chính để hồi sinh khi bị xoá
    local function backupScriptElements()
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("LocalScript") or obj:IsA("Script") or obj:IsA("ModuleScript")) and not obj:IsDescendantOf(game:GetService("CoreGui")) then
                local clone = obj:Clone()
                scriptBackup[obj] = clone
            end
        end
    end

    -- Tự động phục hồi nếu bị xoá hoặc phá huỷ
    local function monitorDestruction()
        for original, clone in pairs(scriptBackup) do
            if not original:IsDescendantOf(game) then
                local parent = clone.Parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
                warn("[HỒI SINH] 🔄 Khôi phục script bị gỡ:", clone.Name)
                clone.Parent = parent
                scriptBackup[clone] = clone
                scriptBackup[original] = nil
            end
        end
    end

    -- Tự động xoá Hook phá hoặc log
    local function antiHookKill()
        getgenv().warn = function() end
        getgenv().print = function() end
        getgenv().error = function() end
        getgenv().debug = function() end
    end

    backupScriptElements()

    RunService.Heartbeat:Connect(function()
        pcall(monitorDestruction)
        pcall(antiHookKill)
    end)
end)


-- BẢO VỆ GUI TOÀN DIỆN – bảo vệ giao diện khỏi mọi hành vi phá hoại, xoá hoặc ghi đè
pcall(function()
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local protectedGuis = {}

    -- Sao lưu GUI để phục hồi nếu bị xóa
    local function backupGuis()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
                    local clone = gui:Clone()
                    protectedGuis[gui] = clone
                end
            end
        end
    end

    -- Phục hồi GUI nếu bị xoá hoặc phá
    local function restoreGui()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for gui, clone in pairs(protectedGuis) do
                if not gui:IsDescendantOf(LocalPlayer.PlayerGui) then
                    local restored = clone:Clone()
                    restored.Parent = LocalPlayer.PlayerGui
                    protectedGuis[restored] = restored
                    protectedGuis[gui] = nil
                    warn("[GUI PROTECTION] 🔄 Phục hồi giao diện:", restored.Name)
                end
            end
        end
    end

    -- Khoá các hành vi xoá GUI từ StarterGui và CoreGui
    local function blockExternalGuiDestruction()
        for _, gui in pairs(CoreGui:GetDescendants()) do
            if gui:IsA("ScreenGui") or gui:IsA("BillboardGui") then
                gui.ResetOnSpawn = false
            end
        end
    end

    backupGuis()

    RunService.Heartbeat:Connect(function()
        pcall(restoreGui)
        pcall(blockExternalGuiDestruction)
    end)
end)


-- BYPASS MỌI TOOL, WEB, VÀ CONSOLE TỪ ADMIN & ROBLOX – Toàn diện tuyệt đối
pcall(function()
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local blockKeywords = {
        "tool", "console", "log", "spy", "track", "ban", "kick", "rbx", "shutdown", "report", "dashboard",
        "monitor", "trace", "inject", "debug", "stream", "admin", "panel", "webhook", "hook", "client", "event"
    }

    local blockClasses = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "ModuleScript", "LocalScript", "Script", "Tool", "Folder", "Message", "Hint"
    }

    -- Bypass tất cả các công cụ theo tên và class
    local function bypassAllTools()
        for _, obj in ipairs(game:GetDescendants()) do
            if table.find(blockClasses, obj.ClassName) then
                local name = obj.Name:lower()
                for _, keyword in ipairs(blockKeywords) do
                    if name:find(keyword) then
                        warn("[BYPASS TOOLS] 🛡️ Vô hiệu hoá:", obj:GetFullName())
                        pcall(function() obj:Destroy() end)
                        break
                    end
                end
            end
        end
    end

    -- Chặn console log/report từ admin/roblox
    local function blockConsoleMessages()
        local logService = game:GetService("LogService")
        logService.MessageOut:Connect(function(msg, msgType)
            local lower = msg:lower()
            for _, keyword in ipairs(blockKeywords) do
                if lower:find(keyword) then
                    warn("[BYPASS CONSOLE] 🚫 Đã ngăn log:", msg)
                    return
                end
            end
        end)
    end

    -- Bảo vệ web request nghi ngờ
    if setreadonly and getrawmetatable then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local old = mt.__namecall

        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if method == "PostAsync" or method == "GetAsync" or method == "InvokeServer" then
                local full = tostring(self)
                for _, keyword in ipairs(blockKeywords) do
                    if full:lower():find(keyword) then
                        warn("[BYPASS WEB/API] ❌ Ngăn truy vấn tới:", full)
                        return nil
                    end
                end
            end
            return old(self, ...)
        end)
    end

    RunService.Heartbeat:Connect(function()
        pcall(bypassAllTools)
        pcall(blockConsoleMessages)
    end)
end)


-- BẢO VỆ BẰNG KEY – Chặn truy cập nếu không nhập đúng mã
pcall(function()
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local StarterGui = game:GetService("StarterGui")

    local correctKey = "VANISKING9999" -- KEY TUỲ CHỈNH CỦA BẠN
    local enteredKey = nil
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.ResetOnSpawn = false
    gui.Name = "KeyProtectionGUI"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0

    local textbox = Instance.new("TextBox", frame)
    textbox.PlaceholderText = "Nhập KEY để mở khoá"
    textbox.Size = UDim2.new(1, -20, 0, 40)
    textbox.Position = UDim2.new(0, 10, 0, 20)
    textbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    textbox.TextColor3 = Color3.new(1, 1, 1)
    textbox.TextScaled = true
    textbox.ClearTextOnFocus = false

    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -20, 0, 40)
    button.Position = UDim2.new(0, 10, 0, 80)
    button.Text = "Xác Nhận"
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextScaled = true

    local function deny()
        textbox.Text = ""
        textbox.PlaceholderText = "KEY sai! Vui lòng thử lại."
    end

    button.MouseButton1Click:Connect(function()
        enteredKey = textbox.Text
        if enteredKey == correctKey then
            gui:Destroy()
            warn("[KEY SYSTEM] ✅ KEY chính xác – đã mở khoá script")
        else
            deny()
        end
    end)

    -- Ngăn chạy code bên dưới nếu chưa nhập đúng key
    repeat task.wait() until enteredKey == correctKey
end)


-- 🛡️ ANTI BAN / KICK / ERROR / CRASH VÔ CỰC
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")

    -- Chặn mọi lệnh kick hoặc ban
    local function protectCharacter()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) and not isexecutorclosure(v) then
                local info = debug.getinfo(v)
                if info.name and (info.name:lower():find("kick") or info.name:lower():find("ban")) then
                    hookfunction(v, function(...) return nil end)
                    warn("✅ [ANTI BAN/KICK] Hooked: ", info.name)
                end
            end
        end
    end

    -- Bảo vệ nhân vật khi có remote kick
    local mt = getrawmetatable(game)
    if setreadonly then setreadonly(mt, false) end
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if (method == "Kick" or method == "kick") or tostring(self):lower():find("ban") then
            warn("⛔ [ANTI BAN/KICK] Blocked:", tostring(self))
            return nil
        end
        return oldNamecall(self, ...)
    end)

    -- Ngăn lỗi crash do code hoặc API
    local oldError = error
    error = function(...)
        warn("⚠️ [ANTI ERROR] Lỗi đã bị chặn:", ...)
        return nil
    end

    local oldWarn = warn
    warn = function(...)
        local msg = tostring(...)
        if msg:lower():find("crash") or msg:lower():find("ban") or msg:lower():find("kick") then
            return nil
        end
        return oldWarn(...)
    end

    -- Chống crash từ các loop hoặc overload
    RunService.Heartbeat:Connect(function()
        if not LocalPlayer or not LocalPlayer.Character then return end
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then
            hum.Health = hum.MaxHealth
            warn("🧬 [ANTI CRASH] Hồi phục nhân vật")
        end
    end)

    protectCharacter()
end)


-- 🛡️ ANTI BLOCK TOÀN DIỆN – Ngăn bị block, xoá, gỡ quyền, block GUI/Control
pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local StarterGui = game:GetService("StarterGui")
    local Lighting = game:GetService("Lighting")
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService")

    -- Chặn block UI, GUI hoặc xoá GUI
    local guiNames = {"ScreenGui", "BillboardGui", "SurfaceGui"}
    RunService.Stepped:Connect(function()
        for _, guiType in ipairs(guiNames) do
            for _, gui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
                if gui:IsA(guiType) and not gui.Enabled then
                    gui.Enabled = true
                    warn("🛡️ [ANTI BLOCK GUI] Đã bật lại:", gui.Name)
                end
            end
        end
    end)

    -- Chặn block bởi admin hoặc lệnh gỡ control
    local function hookBlock()
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) and not isexecutorclosure(v) then
                local info = debug.getinfo(v)
                if info.name and (info.name:lower():find("block") or info.name:lower():find("disable")) then
                    hookfunction(v, function(...) return nil end)
                    warn("✅ [ANTI BLOCK] Hooked:", info.name)
                end
            end
        end
    end

    -- Chặn xoá phần tử quan trọng
    LocalPlayer.Character.DescendantRemoving:Connect(function(desc)
        if desc:IsA("Humanoid") or desc:IsA("Script") or desc:IsA("LocalScript") then
            warn("🛡️ [ANTI DELETE] Đã chặn xoá:", desc.Name)
            desc:Clone().Parent = LocalPlayer.Character
        end
    end)

    -- Chặn block ánh sáng, camera, UI core
    RunService.RenderStepped:Connect(function()
        if Lighting.Brightness < 1 then Lighting.Brightness = 2 end
        if CoreGui:FindFirstChild("DevConsole") then
            CoreGui:FindFirstChild("DevConsole").Enabled = false
            warn("🛡️ [ANTI CONSOLE BLOCK] Đã tắt DevConsole")
        end
    end)

    hookBlock()
end)


-- 🛡️ ANTI LAG: Dọn rác, mesh, hiệu ứng gây lag
task.spawn(function()
    while task.wait(5) do
        for _,v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("Decal") or v:IsA("Texture") or v:IsA("MeshPart") then
                v:Destroy()
            end
        end
    end
end)

-- ❄️ ANTI FREEZE
pcall(function()
    local RunService = game:GetService("RunService")
    RunService.Stepped:Connect(function()
        if not workspace:IsAncestorOf(game.Players.LocalPlayer.Character) then
            game.Players.LocalPlayer.Character.Parent = workspace
            warn("🧊 [ANTI FREEZE] Nhân vật bị đóng băng đã được khôi phục")
        end
    end)
end)

-- 🎥 ANTI CAMERA TRACKING / STREAM MODE
pcall(function()
    local Camera = workspace.CurrentCamera
    task.spawn(function()
        while task.wait(1) do
            if Camera.CameraSubject ~= game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                warn("🎥 [ANTI CAM] Đã khôi phục camera tránh theo dõi")
            end
        end
    end)
end)

-- 🕵️ ANTI CHECK ACCOUNT / INFO / ALT
pcall(function()
    local mt = getrawmetatable(game)
    if setreadonly then setreadonly(mt, false) end
    local old = mt.__index
    mt.__index = newcclosure(function(t, k)
        if tostring(k):lower():find("userid") or tostring(k):lower():find("account") then
            return 999999999
        end
        return old(t, k)
    end)
end)

-- 🧩 ANTI GUI CLOSE / DESTROY
pcall(function()
    local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    pg.ChildRemoved:Connect(function(c)
        warn("🧱 [ANTI GUI] Đã khôi phục GUI:", c.Name)
        c:Clone().Parent = pg
    end)
end)

-- 🛑 ANTI REMOTEEVENT NGHI NGỜ
task.spawn(function()
    while task.wait(2) do
        for _,v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) and not isexecutorclosure(v) then
                local info = debug.getinfo(v)
                if info.name and info.name:lower():find("remote") then
                    hookfunction(v, function(...) return nil end)
                    warn("🔌 [ANTI REMOTE] Blocked:", info.name)
                end
            end
        end
    end
end)

-- 🌐 ANTI WEBHOOK / HTTP LOGGING
pcall(function()
    if hookfunction and request then
        hookfunction(request, function(tbl)
            if tbl.Url and (tbl.Url:lower():find("discord") or tbl.Url:lower():find("webhook")) then
                return nil
            end
            return request(tbl)
        end)
    end
end)

-- 🔁 AUTO RECONNECT
pcall(function()
    game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.Failed then
            warn("🔁 [RECONNECT] Đang tự động kết nối lại...")
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end
    end)
end)



-- 🤖 AI QUẢN LÝ TOÀN DIỆN – ĐƯỢC THÊM VÀO GUI
task.spawn(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")

    local AI_MODULE = {
        Log = function(msg) print("🤖 [AI]: " .. msg) end,
        DetectSuspicious = function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local n = plr.Name:lower()
                    if n:find("admin") or n:find("mod") or n:find("owner") then
                        AI_MODULE.Log("Phát hiện người có quyền: " .. plr.Name)
                        if LocalPlayer:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.HumanoidRootPart.CFrame = CFrame.new(0,9999,0)
                            AI_MODULE.Log("Di chuyển để tránh bị theo dõi.")
                        end
                    end
                end
            end
        end,
        AutoDefense = function()
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                if character.Humanoid.Health <= 50 then
                    character.Humanoid.Health = character.Humanoid.MaxHealth
                    AI_MODULE.Log("Tự động hồi máu do nguy hiểm.")
                end
            end
        end,
        CleanMemory = function()
            collectgarbage("collect")
            AI_MODULE.Log("Đã dọn bộ nhớ RAM")
        end,
        AntiSurveillance = function()
            local cam = workspace.CurrentCamera
            if cam.CameraSubject ~= LocalPlayer.Character:FindFirstChild("Humanoid") then
                cam.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
                AI_MODULE.Log("Camera bị chỉnh, đã reset về mặc định")
            end
        end
    }

    -- Chu kỳ AI chạy mỗi 5 giây
    while task.wait(5) do
        AI_MODULE.DetectSuspicious()
        AI_MODULE.AutoDefense()
        AI_MODULE.CleanMemory()
        AI_MODULE.AntiSurveillance()
    end
end)



-- 🤖 AI SERVER – TỰ ĐỘNG QUẢN LÝ HOẠT ĐỘNG SERVER TOÀN DIỆN
task.spawn(function()
    local Players = game:GetService("Players")
    local ServerStorage = game:GetService("ServerStorage")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")

    local function log(msg)
        print("🧠 [AI SERVER]: " .. msg)
    end

    local function cleanSuspiciousObjects()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local name = obj.Name:lower()
                if name:find("log") or name:find("admin") or name:find("ban") or name:find("track") then
                    log("Đã xóa script nghi ngờ: " .. obj:GetFullName())
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end

    local function monitorServerHealth()
        if Lighting.ClockTime > 20 or Lighting.Brightness < 1 then
            Lighting.ClockTime = 14
            Lighting.Brightness = 2
            log("Khôi phục ánh sáng máy chủ")
        end
    end

    local function monitorReplicatedStorage()
        for _, item in pairs(ReplicatedStorage:GetDescendants()) do
            if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                if item.Name:lower():find("ban") or item.Name:lower():find("log") then
                    log("Block remote nghi ngờ: " .. item.Name)
                    pcall(function() item:Destroy() end)
                end
            end
        end
    end

    -- Chạy AI mỗi 10 giây
    while task.wait(10) do
        cleanSuspiciousObjects()
        monitorServerHealth()
        monitorReplicatedStorage()
    end
end)


-- 🛡️ ANTI RAGDOLL / STUN / BAN SIÊU CẤP
pcall(function()
    local lp = game:GetService("Players").LocalPlayer
    local char = lp.Character or lp.CharacterAdded:Wait()

    -- Chặn Ragdoll
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BallSocketConstraint") or d.Name:lower():find("ragdoll") then
            warn("🛡️ [ANTI RAGDOLL] Đã xoá:", d:GetFullName())
            d:Destroy()
        end
    end)

    -- Chặn Stun
    char.DescendantAdded:Connect(function(obj)
        if obj:IsA("BoolValue") and obj.Name:lower():find("stun") then
            warn("🛡️ [ANTI STUN] Đã phát hiện stun - xoá ngay:", obj.Name)
            obj:Destroy()
        end
    end)

    -- Kiểm tra loop chặn Humanoid bị Ragdoll
    task.spawn(function()
        while task.wait(2) do
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid.PlatformStand = false
                if char:FindFirstChild("Ragdoll") then
                    char.Ragdoll:Destroy()
                    warn("🛡️ [ANTI RAGDOLL] Xoá node Ragdoll gốc")
                end
            end
        end
    end)

    -- Chống bị ban bất ngờ (hook thêm toàn bộ lệnh kick/ban)
    for _, f in pairs(getgc(true)) do
        if typeof(f) == "function" and islclosure(f) and not isexecutorclosure(f) then
            local info = debug.getinfo(f)
            if info.name and (info.name:lower():find("ban") or info.name:lower():find("kick")) then
                hookfunction(f, function(...) return nil end)
                warn("🛡️ [ANTI BAN] Hooked function:", info.name)
            end
        end
    end
end)


-- ☁️ INFINITY JUMP – Nhảy vô hạn hỗ trợ mọi nơi
pcall(function()
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    UserInputService.JumpRequest:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    warn("☁️ [INFINITY JUMP] Đã bật nhảy vô hạn.")
end)
