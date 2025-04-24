--[[
---------------------------------
ExamplePlugin - By @Jopio0819
Create your own plugins for others to use!
Warning: RoWatch will completely crash if not all functions are found. Even if you dont use a function, you still need to have it in the script.
---------------------------------
]]
local ExamplePlugin = {}

function ExamplePlugin.Punished(VictimID:number,moderator:Player)
	--print('Punished. Victim: '..VictimID)
end

function ExamplePlugin.ModJoined(moderator:Player)
	-- Add your code for when a moderator joins.
end

function ExamplePlugin.Innocent(VictimID:number,moderator:Player)
	--print(VictimID..' is doomed innocent by '..moderator.Name..'!')
end

function ExamplePlugin.Skipped(VictimID:number,moderator:Player)
	--print(VictimID..' has been skipped by '..moderator.Name)
end

return ExamplePlugin
