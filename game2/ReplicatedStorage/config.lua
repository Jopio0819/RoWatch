local config = {}
--[[
Thanks for using RoWatch!
Let's get you started right away!
Please configure the settings below to your liking, and enjoy!
]]

function config.WhitelistCode(plr:Player)
	if plr.UserId == game.CreatorId then -- IF THE USER IS THE GAME OWNER
		return true -- RETURN TRUE TO MAKE THE USER A MODERATOR
	else
		return false -- RETURN FALSE TO CANCEL THE PROCCES
	end
end

function config.PunishmentCode(plr:Player,moderator:Player)
	print('Punished')
	plr:Kick()
	return true -- RETURN TRUE TO LET THE MODERATOR KNOW THE USER IS BANNED.
end

function config.getDataCodes(plr:Player)
	local DataCodes = {
		[1] = 'UserId: '..plr.UserId,
		[2] = 'Account Age: '..plr.AccountAge
	}

	return DataCodes
end

return config
