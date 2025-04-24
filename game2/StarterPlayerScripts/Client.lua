local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local localPlayer = Players.LocalPlayer

-- GUI: Spectate
local gui = localPlayer:WaitForChild("PlayerGui"):WaitForChild("SpectateHacker")
gui.Enabled = false
local camera = workspace.CurrentCamera

local function focusOnTarget()
	local targetPlayer = gui.Frame.Player.Value
	if targetPlayer and targetPlayer.Character then
		local head = targetPlayer.Character:FindFirstChild("Head")
		if head then
			camera.CameraSubject = head
			camera.CameraType = Enum.CameraType.Custom
			print("[CAMERA] Focused on", targetPlayer.Name)
		end
	end
end


-- RemoteEvents
local NotifyEvent = ReplicatedStorage:WaitForChild("NotifyEvent")
local JoinEvent = ReplicatedStorage:WaitForChild("JoinEvent")
local ShadowEvent = ReplicatedStorage:WaitForChild("ShadowModeUpdate")

-- Knopfunctionaliteit
gui.Frame.Punish.MouseButton1Click:Connect(function()
	local target = gui.Frame.Player.Value
	if target then
		NotifyEvent:FireServer("Punish", target.UserId)
	end
end)

gui.Frame.Innocent.MouseButton1Click:Connect(function()
	local target = gui.Frame.Player.Value
	if target then
		NotifyEvent:FireServer("Innocent", target.UserId)
	end
end)

gui.Frame.Skip.MouseButton1Click:Connect(function()
	
end)

gui.Frame.Next.MouseButton1Click:Connect(function()
	JoinEvent:FireServer()
end)

-- Meldingen van server
NotifyEvent.OnClientEvent:Connect(function(status)
	local messages = {
		Succes = {Title = "Teleporting", Text = "You are now spectating a reported player."},
		Failed = {Title = "No Reported Player", Text = "No valid report found."},
		Skip = {Title = "Skipped", Text = "Searching for next reported player..."}
	}

	local msg = messages[status]
	if msg then
		StarterGui:SetCore("SendNotification", {
			Title = msg.Title,
			Text = msg.Text,
			Duration = 5
		})
	else
		warn("[CLIENT] Unknown NotifyEvent status:", status)
	end
end)

-- SHADOWMODE: volledig onzichtbaar maken
local function fullyRemoveCharacter(targetPlayer)
	if not targetPlayer then return end
	local char = targetPlayer.Character
	if char then
		char:Destroy()
	end
end

-- ShadowEvent ontvangen van server
ShadowEvent.OnClientEvent:Connect(function(mode, targetPlayer)
	if not targetPlayer then return end

	if mode == "Enable" then
		fullyRemoveCharacter(targetPlayer)
	elseif mode == "Disable" then
		-- Niets doen voor nu; Roblox maakt character vanzelf opnieuw
	end
end)

gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if gui.Enabled then
		task.wait(1) -- even wachten tot character er is
		focusOnTarget()
	end
end)
