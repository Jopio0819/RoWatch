local Players = game:GetService("Players")


local playersFolder = script:WaitForChild("Players")


local function isValidObjectValue(objectValue)
	return objectValue and objectValue:IsA("ObjectValue") and objectValue.Value and objectValue.Value:IsA("Player")
end

local function hidePlayer(objectValue)
	print('[ROWATCH] Test Print')
	if not isValidObjectValue(objectValue) then return end

	local player = objectValue.Value

	if player == Players.LocalPlayer then return end

	player.Parent = nil
end

local function showPlayer(objectValue)
	print("show player")
	if not isValidObjectValue(objectValue) then return end
	print("is valid")
	local player = objectValue.Value

	if player == Players.LocalPlayer then return end
	print("player isn't local player")
	-- TODO: Possibly add case for player leaving and player object meant to be destroyed
	print("player isn't locked")
	objectValue.Value.Parent = Players
end


for _, objectValue in ipairs(playersFolder:GetChildren()) do
	hidePlayer(objectValue)
end
playersFolder.ChildAdded:Connect(hidePlayer)

playersFolder.ChildRemoved:Connect(showPlayer)
