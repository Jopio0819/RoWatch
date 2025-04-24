local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local GameUtilities = DataStoreService:GetDataStore("GameUtilities")
local SessionStore = DataStoreService:GetDataStore("SessionStore")

local config = require(ReplicatedStorage:WaitForChild("Config"))

-- Events
local JoinEvent = ReplicatedStorage:FindFirstChild("JoinEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
JoinEvent.Name = "JoinEvent"
JoinEvent.Parent = ReplicatedStorage

local NotifyEvent = ReplicatedStorage:FindFirstChild("NotifyEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
NotifyEvent.Name = "NotifyEvent"
NotifyEvent.Parent = ReplicatedStorage

local ShadowEvent = ReplicatedStorage:FindFirstChild("ShadowModeUpdate") or Instance.new("RemoteEvent", ReplicatedStorage)
ShadowEvent.Name = "ShadowModeUpdate"
ShadowEvent.Parent = ReplicatedStorage

-- Helper: activate shadowmode for a player
local function enableShadowMode(player)
	if player.Character then
		player.Character:Destroy()
	end
	ShadowEvent:FireAllClients("Enable", player)
	print("[SHADOWMODE] Enabled for", player.Name)
end

-- Helper: fallback + GUI + shadowmode
function setupSpectate(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	local targetUserId = tonumber(teleportData)

	if not targetUserId then
		local fallbackKey = "TeleportData_" .. tostring(player.UserId)
		local success, fallback = pcall(function()
			return SessionStore:GetAsync(fallbackKey)
		end)
		if success then
			targetUserId = tonumber(fallback)
		end
	end

	if not targetUserId then
		warn("[SPECTATE] No teleportData or fallback for", player.Name)
		return
	end

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("SpectateHacker")

	local targetPlayer = nil
	for i = 1, 10 do
		targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if targetPlayer then break end
		task.wait(1)
	end

	if not targetPlayer then
		warn("[SPECTATE] Target not found in Players:", targetUserId)
		return
	end

	-- Setup GUI
	local DataCodes = config.getDataCodes(game.Players:GetPlayerByUserId(targetUserId))
	local frame:Frame = gui:WaitForChild('Frame')
	for i,v in DataCodes do
		local textLabel = frame:FindFirstChild(tostring(i))
		if textLabel and textLabel:IsA('TextLabel') then
			textLabel.Text = v
		end
	end
	for i,v in ipairs(script:WaitForChild('Plugins'):GetChildren()) do
		local required = require(v)
		if required then
			required.ModJoined(player)
		end
	end
	gui.Enabled = true
	gui.Frame.ProfilePic.Image = Players:GetUserThumbnailAsync(
		targetUserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size420x420
	)
	gui.Frame.Username.Text = "@" .. targetPlayer.Name
	gui.Frame.Displayname.Text = targetPlayer.DisplayName
	gui.Frame.Player.Value = targetPlayer

	enableShadowMode(player)
end

-- PLAYER JOINS
Players.PlayerAdded:Connect(function(player)
	-- Session opslaan
	local key = "ActiveSession_" .. tostring(player.UserId)
	local data = {
		placeId = game.PlaceId,
		jobId = game.JobId
	}
	pcall(function()
		SessionStore:SetAsync(key, data)
	end)

	-- Spectate setup + shadowmode als TeleportData aanwezig is
	task.defer(function()
		player.CharacterAdded:Wait()
		if config.WhitelistCode(player) then
			setupSpectate(player)
		end
	end)
end)

-- PLAYER VERLAAT
Players.PlayerRemoving:Connect(function(player)
	local key = "ActiveSession_" .. tostring(player.UserId)
	pcall(function()
		SessionStore:RemoveAsync(key)
	end)
	ShadowEvent:FireAllClients("Disable", player)
end)

-- MOD ACTIONS
NotifyEvent.OnServerEvent:Connect(function(player, action, targetUserId)
	if not config.WhitelistCode(player) then
		warn("[SECURITY] Blocked NotifyEvent from", player.Name)
		return
	end
	local success, reports = pcall(function()
		return GameUtilities:GetAsync("Reports")
	end)
	if not success then return end

	-- Verwijder uit reports
	if typeof(reports) == "table" then
		local newReports = {}
		for _, id in ipairs(reports) do
			if tonumber(id) ~= tonumber(targetUserId) then
				table.insert(newReports, id)
			end
		end
		GameUtilities:SetAsync("Reports", newReports)
	elseif tonumber(reports) == tonumber(targetUserId) then
		GameUtilities:SetAsync("Reports", nil)
	end

	if action == "Punish" then
		print("[MOD ACTION]", player.Name, "punished", targetUserId)
		require(game.ReplicatedStorage:WaitForChild('Config')).PunishmentCode(game.Players:GetPlayerByUserId(targetUserId),player)
		for i,v in ipairs(script:WaitForChild('Plugins'):GetChildren()) do
			local required = require(v)
			if required then
				required.Punished(targetUserId,player)
			end
		end
	elseif action == "Innocent" then
		print("[MOD ACTION]", player.Name, "cleared", targetUserId)
		for i,v in ipairs(script:WaitForChild('Plugins'):GetChildren()) do
			local required = require(v)
			if required then
				required.Innocent(targetUserId,player)
			end
		end
	elseif action == 'Skipped' then
		for i,v in ipairs(script:WaitForChild('Plugins'):GetChildren()) do
			local required = require(v)
			if required then
				required.Skipped(targetUserId,player)
			end
		end
	end
	local frame = player.PlayerGui:WaitForChild('SpectateHacker'):WaitForChild('Frame')
	frame:WaitForChild('Innocent').Visible = false
	frame:WaitForChild('Punish').Visible = false
	frame:WaitForChild('Skip').Visible = false
	frame:WaitForChild('Next').Visible = true
end)

-- SKIP / NEXT
JoinEvent.OnServerEvent:Connect(function(player)
	if not config.WhitelistCode(player) then
		warn("[SECURITY] Blocked JoinEvent from", player.Name)
		return
	end

	local success, reports = pcall(function()
		return GameUtilities:GetAsync("Reports")
	end)
	if not success or not reports then
		NotifyEvent:FireClient(player, "Failed")
		return
	end

	local function tryTeleportTo(userId)
		local key = "ActiveSession_" .. tostring(userId)
		local ok, session = pcall(function()
			return SessionStore:GetAsync(key)
		end)
		if ok and session and table.find(config.AllowedPlaces, session.placeId) then
			local tpOptions = Instance.new("TeleportOptions")
			tpOptions:SetTeleportData(tostring(userId))
			TeleportService:TeleportToPlaceInstance(session.placeId, session.jobId, player, nil, tpOptions)
			NotifyEvent:FireClient(player, "Succes")
			print("[TELEPORT] Skipped to new target:", userId)
			return true
		end
		return false
	end

	local found = false

	if typeof(reports) == "table" then
		for _, uid in ipairs(reports) do
			if Players:GetPlayerByUserId(uid) ~= player then
				if tryTeleportTo(uid) then
					found = true
					break
				end
			end
		end
	elseif typeof(reports) == "number" then
		if Players:GetPlayerByUserId(reports) ~= player then
			found = tryTeleportTo(reports)
		end
	end

	if not found then
		NotifyEvent:FireClient(player, "Failed")
	end
end)


-- REPORTS
ReplicatedStorage:WaitForChild("API").Event:Connect(function(data, userId)
	if data == "Report" then
		local success, old = pcall(function()
			return GameUtilities:GetAsync("Reports")
		end)
		if not success then return end

		if typeof(old) == "table" then
			if not table.find(old, userId) then
				table.insert(old, userId)
				GameUtilities:SetAsync("Reports", old)
			end
		elseif old then
			GameUtilities:SetAsync("Reports", { old, userId })
		else
			GameUtilities:SetAsync("Reports", userId)
		end
	end
end)

