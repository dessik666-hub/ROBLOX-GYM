-- Server authority for Neon Gym Simulator.
-- Stats, stamina, reps, running, ranks and saving are decided here.
-- Clients only send intents (tap, choose plates/speed, leave) and draw the result.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(RS.Shared.Config)
local World = require(script.Parent.World)
local Data = require(script.Parent.Data)
local Body = require(script.Parent.Body)
local Npcs = require(script.Parent.Npcs)

---------------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = RS

local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local SyncRemote = remote("Sync") -- S->C  own state for the HUD
local RepFxRemote = remote("RepFx") -- S->all rep happened: animation + popup
local RunFxRemote = remote("RunFx") -- S->all cardio tick: heart popup
local FameFxRemote = remote("FameFx") -- S->all podium fame: star popup (+ applauder)
local NotifyRemote = remote("Notify") -- S->C  toast
local RepRemote = remote("Rep") -- C->S  tap
local SetPlatesRemote = remote("SetPlates") -- C->S  plate counts
local SetSpeedRemote = remote("SetSpeed") -- C->S  cardio speed index
local SetAutoRemote = remote("SetAuto") -- C->S  auto-train on/off
local LeaveRemote = remote("Leave") -- C->S  leave the machine
local RankUpRemote = remote("RankUp") -- C->S  claim next rank

---------------------------------------------------------------------------
-- Sessions
---------------------------------------------------------------------------
local sessions = {} -- [player] = session

-- Sends a Strings key; the client shows it in the player's language.
-- args may include { rank = i } to be resolved to a localized rank title.
local function notify(player, key, kind, args)
	local s = sessions[player]
	local now = os.clock()
	if s then
		-- Don't spam the same message
		if s.lastNotify[key] and now - s.lastNotify[key] < 1.5 then
			return
		end
		s.lastNotify[key] = now
	end
	NotifyRemote:FireClient(player, key, kind or "info", args or {})
end

local function getAlive(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return character, humanoid, root
	end
	return nil
end

local function bestSpeed(stamina)
	local best = 1
	for i, sp in ipairs(Config.Speeds) do
		if stamina >= sp.req then
			best = i
		end
	end
	return best
end

local function rankBonus(s)
	return Config.Ranks[s.profile.rank].bonus
end

---------------------------------------------------------------------------
-- Stations
---------------------------------------------------------------------------
local world = World.build()
local stations = world.stations
local poseStations = {}
for _, station in ipairs(stations) do
	if station.cfg.type == "pose" then
		table.insert(poseStations, station)
	end
end

local function setSpotlight(station, on)
	if station.light then
		station.light.Enabled = on
	end
	if station.ring then
		station.ring.Transparency = on and 0 or 0.4
	end
end

local function leaveStation(player, placeOutside)
	local s = sessions[player]
	if not s or not s.station then
		return
	end
	local station = s.station
	station.occupant = nil
	station.model:SetAttribute("Occupant", nil)
	if station.cfg.type == "pose" then
		setSpotlight(station, false)
		station.applauded = nil
	end
	s.station = nil
	s.auto = false

	local character = player.Character
	if character then
		character:SetAttribute("Station", nil)
		character:SetAttribute("Kind", nil)
		character:SetAttribute("RunSpeed", nil)
	end

	local alive, humanoid, root = getAlive(player)
	if alive and placeOutside ~= false then
		root.Anchored = false
		humanoid.PlatformStand = false
		alive:PivotTo(station.exitCF)
	end
end

local function enterStation(player, station)
	local s = sessions[player]
	if not s or s.station then
		return
	end
	if station.occupant then
		notify(player, station.cfg.type == "pose" and "n.stageTaken" or "n.taken", "warn")
		return
	end
	local sila = Config.sila(s.profile.stats)
	if sila < station.cfg.unlock then
		notify(player, "n.locked", "warn", { Config.format(station.cfg.unlock) })
		return
	end
	local character, humanoid, root = getAlive(player)
	if not character then
		return
	end

	station.occupant = player
	station.model:SetAttribute("Occupant", player.UserId)
	s.station = station
	s.combo = 0
	s.runAcc = 0
	s.poseAcc = 0

	humanoid.Sit = false
	humanoid.PlatformStand = true
	root.Anchored = true
	character:PivotTo(station.rootCF)

	if station.cfg.type == "cardio" then
		-- Never start faster than the player can handle
		if s.profile.stats.stamina < Config.Speeds[s.profile.speed].req then
			s.profile.speed = bestSpeed(s.profile.stats.stamina)
		end
		character:SetAttribute("RunSpeed", Config.Speeds[s.profile.speed].mph)
	elseif station.cfg.type == "pose" then
		station.applauded = {}
		setSpotlight(station, true)
		notify(player, "n.onStage", "good")
	end
	-- Set Kind before Station: the client starts animating when Station appears
	character:SetAttribute("Kind", station.kind)
	character:SetAttribute("Station", station.id)
end

---------------------------------------------------------------------------
-- Podium applause: one per spectator per appearance, never for yourself
---------------------------------------------------------------------------
local function applaud(player, station)
	local poser = station.occupant
	local s = sessions[player]
	local ps = poser and sessions[poser]
	if not s or not ps or poser == player then
		return
	end
	if s.station then
		notify(player, "n.leaveFirst", "warn")
		return
	end
	local now = os.clock()
	if now - (s.lastApplause or 0) < Config.ApplauseCooldown then
		return
	end
	station.applauded = station.applauded or {}
	if station.applauded[player.UserId] then
		notify(player, "n.alreadyApplauded", "warn")
		return
	end
	station.applauded[player.UserId] = true
	s.lastApplause = now
	ps.profile.fame += Config.ApplauseFame
	FameFxRemote:FireAllClients(poser, Config.ApplauseFame, player)
	notify(poser, "n.applauded", "good", { player.DisplayName, Config.ApplauseFame })
end

for _, station in ipairs(stations) do
	station.prompt.Triggered:Connect(function(player)
		enterStation(player, station)
	end)
	if station.applaudPrompt then
		station.applaudPrompt.Triggered:Connect(function(player)
			applaud(player, station)
		end)
	end
end

---------------------------------------------------------------------------
-- Reps (weight machines)
---------------------------------------------------------------------------
local function doRep(player, isAuto)
	local s = sessions[player]
	local station = s and s.station
	if not station or station.cfg.type ~= "weights" then
		return
	end

	local now = os.clock()
	if now - s.lastRep < Config.RepCooldown then
		return
	end

	local machine = station.cfg
	local stats = s.profile.stats
	local weight = Config.totalWeight(s.profile.plates)
	local req = Config.requirement(weight)
	local have = Config.machineStat(stats, machine)
	local cost = Config.repCost(weight)

	-- Auto-train waits quietly for stamina instead of failing
	if isAuto and s.energy < cost then
		return
	end

	local gap = now - s.lastRep
	s.lastRep = now

	if have < req then
		s.combo = 0
		RepFxRemote:FireAllClients(player, station.id, false, machine.stat, 0, false)
		notify(player, "n.tooHeavy", "warn", { Config.format(req), Config.format(have) })
		return
	end
	if s.energy < cost then
		s.combo = 0
		RepFxRemote:FireAllClients(player, station.id, false, machine.stat, 0, false)
		notify(player, "n.noStamina", "warn")
		return
	end

	s.energy -= cost
	s.idle = 0

	-- Own addition 1: "Неоновый пампинг" — steady reps build a combo
	if gap <= Config.ComboWindow then
		s.combo = math.min(s.combo + Config.ComboStep, Config.ComboMax)
	else
		s.combo = 0
	end

	-- Own addition 2: "Идеальный вес" — lifting near your limit pays more
	local sweet = weight > 1 and req >= have * Config.SweetRatio

	-- Bonuses add up (GDD: no multiplying bonuses)
	local bonus = rankBonus(s) + s.combo + (sweet and Config.SweetBonus or 0)
	local gain = Config.repGain(weight) * machine.mult * (1 + bonus)

	if machine.stat == "all" then
		for _, key in ipairs(Config.Muscles) do
			stats[key] += gain
		end
	else
		stats[machine.stat] += gain
	end

	RepFxRemote:FireAllClients(player, station.id, true, machine.stat, gain, sweet)
end

---------------------------------------------------------------------------
-- Cardio tick (treadmill / rower), once per second
---------------------------------------------------------------------------
local function cardioTick(player, s)
	local station = s.station
	local stats = s.profile.stats
	local speedIndex = s.profile.speed
	if stats.stamina < Config.Speeds[speedIndex].req then
		speedIndex = bestSpeed(stats.stamina)
		s.profile.speed = speedIndex
		notify(player, "n.tooFast", "warn")
		if player.Character then
			player.Character:SetAttribute("RunSpeed", Config.Speeds[speedIndex].mph)
		end
	end

	local gain = Config.Speeds[speedIndex].gain * station.cfg.mult * (1 + rankBonus(s))
	stats.stamina += gain
	-- Max stamina grows, so current stamina grows with it
	s.energy = math.min(Config.energyMax(stats), s.energy + gain)
	RunFxRemote:FireAllClients(player, gain)
end

---------------------------------------------------------------------------
-- Client requests
---------------------------------------------------------------------------
RepRemote.OnServerEvent:Connect(function(player)
	doRep(player, false)
end)

SetPlatesRemote.OnServerEvent:Connect(function(player, counts)
	local s = sessions[player]
	if not s or typeof(counts) ~= "table" then
		return
	end
	local clean = {}
	for i = 1, #Config.Plates do
		local v = counts[i]
		if typeof(v) ~= "number" or v ~= v then
			return
		end
		clean[i] = math.clamp(math.floor(v), 0, Config.MaxPlates)
	end
	local n = Config.plateCount(clean)
	if n < 1 or n > Config.MaxPlates then
		notify(player, "n.plates", "warn", { Config.MaxPlates })
		return
	end
	s.profile.plates = clean
end)

SetSpeedRemote.OnServerEvent:Connect(function(player, index)
	local s = sessions[player]
	local sp = typeof(index) == "number" and Config.Speeds[index]
	if not s or not sp then
		return
	end
	if s.profile.stats.stamina < sp.req then
		notify(player, "n.needStamina", "warn", { Config.format(sp.req) })
		return
	end
	s.profile.speed = index
	if s.station and s.station.cfg.type == "cardio" and player.Character then
		player.Character:SetAttribute("RunSpeed", sp.mph)
	end
end)

SetAutoRemote.OnServerEvent:Connect(function(player, on)
	local s = sessions[player]
	if not s then
		return
	end
	s.auto = on == true and s.station ~= nil and s.station.cfg.type == "weights"
end)

LeaveRemote.OnServerEvent:Connect(function(player)
	leaveStation(player, true)
end)

RankUpRemote.OnServerEvent:Connect(function(player)
	local s = sessions[player]
	if not s then
		return
	end
	if Config.canRankUp(s.profile.stats, s.profile.rank) then
		s.profile.rank += 1
		local r = Config.Ranks[s.profile.rank]
		notify(player, "n.rankUp", "good", { { rank = s.profile.rank }, math.floor(r.bonus * 100) })
	end
end)

---------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------

-- Machine poses need elbows and knees, so R6 characters are rebuilt as R15
local function ensureR15(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or humanoid.RigType == Enum.HumanoidRigType.R15 then
		return
	end
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(math.max(player.UserId, 1))
	end)
	if not ok or not desc then
		desc = Instance.new("HumanoidDescription")
	end
	local built, newCharacter = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not built or not newCharacter or character.Parent == nil then
		warn("[R15] Could not rebuild character for", player.Name)
		return
	end
	newCharacter.Name = player.Name
	local pivot = character:GetPivot()
	player.Character = newCharacter
	newCharacter:PivotTo(pivot)
	newCharacter.Parent = workspace
	character:Destroy()
end

local function makeLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local sila = Instance.new("IntValue")
	sila.Name = "Strength"
	sila.Parent = folder
	local fame = Instance.new("IntValue")
	fame.Name = "Fame"
	fame.Parent = folder
	folder.Parent = player
	return sila, fame
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		ensureR15(player, character)
	end)
	if player.Character then
		task.spawn(ensureR15, player, player.Character)
	end

	local profile, canSave = Data.load(player)
	if not player.Parent then
		return
	end
	sessions[player] = {
		profile = profile,
		canSave = canSave,
		energy = Config.energyMax(profile.stats),
		station = nil,
		lastRep = 0,
		combo = 0,
		auto = false,
		nextAuto = 0,
		runAcc = 0,
		idle = 0,
		poseAcc = 0,
		lastApplause = 0,
		lastNotify = {},
	}
	local silaValue, fameValue = makeLeaderstats(player)
	sessions[player].leaderSila = silaValue
	sessions[player].leaderFame = fameValue
	if not canSave and not Data.isStudio then
		notify(player, "n.loadFail", "warn")
	end

	player.CharacterRemoving:Connect(function()
		leaveStation(player, false)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

local function savePlayer(player)
	local s = sessions[player]
	if s and s.canSave then
		Data.save(player, s.profile)
	end
end

Players.PlayerRemoving:Connect(function(player)
	leaveStation(player, false)
	savePlayer(player)
	sessions[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(120)
		for player in pairs(sessions) do
			task.spawn(savePlayer, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(sessions) do
		pending += 1
		task.spawn(function()
			savePlayer(player)
			pending -= 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait(0.2)
	end
end)

---------------------------------------------------------------------------
-- Simulation loop
---------------------------------------------------------------------------
local function snapshot(s)
	return {
		stats = s.profile.stats,
		rank = s.profile.rank,
		plates = s.profile.plates,
		speed = s.profile.speed,
		energy = s.energy,
		energyMax = Config.energyMax(s.profile.stats),
		combo = s.combo,
		auto = s.auto,
		kind = s.station and s.station.kind or nil,
		fame = s.profile.fame,
	}
end

local syncAcc, bodyAcc = 0, 0
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	for player, s in pairs(sessions) do
		local maxEnergy = Config.energyMax(s.profile.stats)

		-- Stamina refills after a short rest
		s.idle += dt
		if s.idle >= Config.EnergyRegenDelay then
			s.energy = math.min(maxEnergy, s.energy + maxEnergy * Config.EnergyRegenPct * dt)
		end

		if s.combo > 0 and now - s.lastRep > Config.ComboWindow then
			s.combo = 0
		end

		if s.station then
			if s.station.cfg.type == "cardio" then
				s.runAcc += dt
				if s.runAcc >= 1 then
					s.runAcc -= 1
					cardioTick(player, s)
				end
			elseif s.station.cfg.type == "pose" then
				-- NPC spectators applaud: bigger muscles, more fame
				s.poseAcc += dt
				if s.poseAcc >= Config.CrowdInterval then
					s.poseAcc -= Config.CrowdInterval
					local sila = Config.sila(s.profile.stats)
					local gain = math.floor(Config.crowdFame(sila) * (1 + rankBonus(s)))
					s.profile.fame += gain
					FameFxRemote:FireAllClients(player, gain, nil)
				end
			elseif s.auto and now >= s.nextAuto then
				s.nextAuto = now + Config.AutoInterval
				doRep(player, true)
			end
		end
	end

	syncAcc += dt
	if syncAcc >= 0.2 then
		syncAcc = 0
		for player, s in pairs(sessions) do
			SyncRemote:FireClient(player, snapshot(s))
		end
	end

	bodyAcc += dt
	if bodyAcc >= 1 then
		bodyAcc = 0
		for player, s in pairs(sessions) do
			Body.update(player, s.profile)
			if s.leaderSila then
				s.leaderSila.Value = math.floor(Config.sila(s.profile.stats))
				s.leaderFame.Value = math.floor(s.profile.fame)
			end
		end
	end
end)

---------------------------------------------------------------------------
-- Screens: who is on the podium now, and the server's top by Сила
---------------------------------------------------------------------------
local function updateScreens()
	for i, station in ipairs(poseStations) do
		local line = world.stageScreen.lines[i]
		if line then
			local poser = station.occupant
			local s = poser and sessions[poser]
			if s then
				line.Text = string.format("%d. %s — 🏆 %s · ⭐ %s", i, poser.DisplayName, Config.format(Config.sila(s.profile.stats)), Config.format(s.profile.fame))
			else
				line.Text = i .. ". Free — step up and flex!"
			end
		end
	end

	local list = {}
	for player, s in pairs(sessions) do
		table.insert(list, { player = player, sila = Config.sila(s.profile.stats), fame = s.profile.fame })
	end
	table.sort(list, function(a, b)
		return a.sila > b.sila
	end)
	for i, line in ipairs(world.topBoard.lines) do
		local e = list[i]
		line.Text = e and string.format("%d. %s — 🏆 %s   ⭐ %s", i, e.player.DisplayName, Config.format(e.sila), Config.format(e.fame)) or ""
	end
end

task.spawn(function()
	while true do
		updateScreens()
		task.wait(2)
	end
end)

---------------------------------------------------------------------------
-- NPCs
---------------------------------------------------------------------------
Npcs.start(workspace:WaitForChild("Gym"), world.npcLayout, function()
	-- The coach only visits people in the gym, not on the podium
	local list = {}
	for _, station in ipairs(stations) do
		if station.occupant and station.cfg.type ~= "pose" then
			table.insert(list, { position = station.rootCF.Position })
		end
	end
	return list
end)
