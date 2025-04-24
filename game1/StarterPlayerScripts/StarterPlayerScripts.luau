local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local Icon = require(Workspace.TopbarPlus.Icon)
local config = require(ReplicatedStorage.Config)
local localPlayer = Players.LocalPlayer

-- Alleen beschikbaar voor whitelisted users
if config.WhitelistCode(localPlayer) then
	local JoinHacker = Icon.new()
		:setLabel("Watch Hacker")
		:setImage(12967712847, "Deselected")
		:setImage(13537913116, "Selected")
		:oneClick()

	JoinHacker.selected:Connect(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Searching",
			Text = "Please wait... We're searching an online reported user.",
			Duration = 5 
		})
		ReplicatedStorage.JoinEvent:FireServer()
	end)
end

ReplicatedStorage.JoinEvent.OnClientEvent:Connect(function(status)
	if status == "Failed" then
		StarterGui:SetCore("SendNotification", {
			Title = "Failed to Teleport",
			Text = "No reports found or no online reported user.",
			Duration = 5
		})
	elseif status == "Succes" then
		StarterGui:SetCore("SendNotification", {
			Title = "You're getting teleported",
			Text = "You should get teleported shortly.",
			Duration = 5
		})
	else
		warn("[ROWATCH] Unexpected status received from server:", status)
	end
end)
