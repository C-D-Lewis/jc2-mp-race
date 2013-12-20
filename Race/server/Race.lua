-- Configuration
announceColour = Color(255, 0, 255, 255)
serverColour = Color(255, 200, 200, 200)

-- Globals
contenders = {}	-- Players in the race (i, name)
wins = {}	-- Number of wins (name, wins)

-- Race status
raceInProgress = false

--------------------------------------- Event Functions ---------------------------------------

-- When the module is loaded
onModuleLoad = function(args)
	print("---------------------------------------")
	print("Setting up...")

	-- Setup race wins for all current players
	for player in Server:GetPlayers() do
		wins[player:GetName()] = 0
	end
	print("Scoreboard created.")

	-- Notify
	announce("Race Module Reloaded.", announceColour)
	print("Race setup complete.")
	print("---------------------------------------")
end

-- When a player joins the game
onPlayerJoin = function(args)
	-- Notify
	respond(args.player, "Type '/racehelp' for Race commands.", serverColour)
end

-- Player leaves
onPlayerQuit = function(args)
	local playerName = args.player:GetName()

	-- If the player leaves mid race
	if raceInProgress then
		if isInRace(playerName) then
			announce(playerName .. " left the race.", joinColour)
			table.remove(contenders, playerName)
		end
	end
end

-- When a player chats a message
onPlayerChat = function(args)
	local player = args.player
	local playerName = args.player:GetName()
	local position = args.player:GetPosition()
	local message = args.text

	-- Reset RNG
	math.randomseed(os.time())

	-- Show help
	if message == "/racehelp" then
		respond(player, "Race commands:", serverColour)
		Chat:Send(player, "/enterrace /leaverace /startrace", serverColour)

		return false
	end

	-- If player joins
	if message == "/enterrace" then
		-- If race is not in progress
		if raceInProgress == false then
			if isInRace(playerName) then
				respond(player, "You are already entered in the race!", serverColour)
			else
				enterInRace(playerName)
				respond(player, "You have been entered into the next race. Use '/leaverace' to leave the race.", serverColour)
			end
		else
			respond(player, "A race is currently in progress. Wait for the next one.", serverColour)
		end

		return false
	end

	-- If a player leaves the race
	if message == "/leaverace" then
		-- If race is not in progress
		if raceInProgress == false then
			if isInRace(playerName) then
				removeFromRace(playerName)
				respond(player, "You have been removed from the next race.", serverColour)
			else
				respond(player, "You are not currently entered into the race.", serverColour)
			end
		else
			respond(player, "You are racing! Get to the finish!", serverColour)
		end

		return false
	end

	-- Player requests race start
	if message == "/startrace" then
		-- If race is not in progress
		if raceInProgress == false then
			-- If enough players entered
			if #contenders > 1 then
				announce(playerName .. " started the race!", announceColour)
				startRace()
			else
				announce("Not enough players to start race. Minimum is 2.", announceColour)
			end
		else
			respond(player, "Race already in progress!", serverColour)
		end

		return false
	end

	-- Save current position
	if message == "/saveposition" then
		savePosition(player:GetPosition())

		return false
	end

	-- It is chat
	return true
end

-- Player dies
onPlayerDeath = function(args)
	local player = args.player
	local playerName = args.player:GetName()

	-- If player was in race
	if isInRace(playerName) then
		announce(playerName .. " died and is no longer in the race!", announceColour)
		removeFromRace(playerName)
	end
end

--------------------------------------- Race Functions ---------------------------------------

-- Player starts the race
startRace = function()
	raceInProgress = true

	announce("Race would happen here.", serverColour)

	raceInProgress = false
end

-- Add a player to the race
enterInRace = function(playerName)
	contenders[playerName] = playerName

	-- Show remaining contenders
	for key, name in pairs(contenders) do
		print(key, name)
	end
end

-- Remove a player from the race
removeFromRace = function(playerName)
	contenders[playerName] = nil

	-- Show remaining contenders
	for key, name in pairs(contenders) do
		print(key, name)
	end
end

-- Is a player in the race?
isInRace = function(playerName)
	for key, name in pairs(contenders) do
		if name == playerName then
			return true
		end
	end

	-- No match, player is not in race
	return false
end

--------------------------------------- General Functions ---------------------------------------

-- Issue a response seperated by a newline (\n causes graphical overlap of chat messages)
respond = function(player, message, colour)
	Chat:Send(player, " ", colour)
	Chat:Send(player, message, colour)
end

-- Like respond, but for broadcasts
announce = function(message, colour)
	Chat:Broadcast(" ", colour)
	Chat:Broadcast(message, colour)
end

-- Match a name to a user entered query
getPlayerFromName = function(query)
	-- Get all players matching target description
	local results = Player.Match(query)

	-- For all matching players, find exact name match
	for index, player in ipairs(results) do -- 'pairs' not 'ipairs'?
		if player:GetName() == query then
			return player
		end
	end

	return nil	-- Java-like return null (here 'nil') if no result
end

-- Save a location to the 'locations.txt' file
savePosition = function(position)
	-- Open file
	local file = io.open("locations.txt", "a+")	-- Append + mode, only at the end of file

	file:write("\n")
	file:write(tostring(position))
	file:write("\n")

	-- Finish
	file:flush()
	file:close() 
end

--------------------------------------- Main Execution ---------------------------------------

-- Subscribe to game events
Events:Subscribe("ModuleLoad", onModuleLoad)
Events:Subscribe("PlayerJoin", onPlayerJoin)
Events:Subscribe("PlayerQuit", onPlayerQuit)
Events:Subscribe("PlayerChat", onPlayerChat)
Events:Subscribe("PlayerDeath", onPlayerDeath)