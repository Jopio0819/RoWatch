local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local config = require(ReplicatedStorage:WaitForChild("Config"))

local GameUtilities = DataStoreService:GetDataStore("GameUtilities")
local SessionStore = DataStoreService:GetDataStore("SessionStore")

local JoinEvent = ReplicatedStorage:FindFirstChild("JoinEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
JoinEvent.Name = "JoinEvent"

-- Function to teleport player to a reported session
local function tryTeleportToSession(plr, targetUserId)
	local key = "ActiveSession_" .. tostring(targetUserId)
	local success, session = pcall(function()
		return SessionStore:GetAsync(key)
	end)

	if success and session and table.find(config.AllowedPlaces, session.placeId) then
		local tpOptions = Instance.new("TeleportOptions")
		-- Primary method: Set TeleportData
		tpOptions:SetTeleportData(tostring(targetUserId))

		-- Fallback method: Set manual session fallback
		local fallbackKey = "TeleportData_" .. tostring(plr.UserId)
		print("[DEBUG][Game1] Writing fallback key:", fallbackKey, "value:", targetUserId)
		SessionStore:SetAsync(fallbackKey, tostring(targetUserId))


		print("[DEBUG] Sending TeleportData:", targetUserId)
		print("[DEBUG] Teleporting", plr.Name, "to place:", session.placeId, "job:", session.jobId)

		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(session.placeId, session.jobId, plr, nil, tpOptions)
		end)

		if ok then
			JoinEvent:FireClient(plr, "Succes")
			return true
		else
			warn("[TELEPORT FAILED]", err)
		end
	end

	return false
end

-- Respond to JoinEvent from client
JoinEvent.OnServerEvent:Connect(function(plr)
	task.wait(1)

	local success, reports = pcall(function()
		return GameUtilities:GetAsync("Reports")
	end)

	if not success or not reports then
		JoinEvent:FireClient(plr, "Failed")
		return
	end

	local found = false

	if typeof(reports) == "table" then
		for _, uid in ipairs(reports) do
			if Players:GetPlayerByUserId(uid) ~= plr then
				if tryTeleportToSession(plr, uid) then
					found = true
					break
				end
			end
		end
	elseif typeof(reports) == "number" then
		if Players:GetPlayerByUserId(reports) ~= plr then
			found = tryTeleportToSession(plr, reports)
		end
	end

	if not found then
		JoinEvent:FireClient(plr, "Failed")
	end
end)
