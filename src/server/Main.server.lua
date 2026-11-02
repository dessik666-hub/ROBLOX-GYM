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

local function notify(player, text, kind)
	local s = sessions[player]
	local now = os.clock()
	if s then
		-- Don't spam the same message
		if s.lastNotify[text] and now - s.lastNotify[text] < 1.5 then
			return
		end
		s.lastNotify[text] = now
	end
	NotifyRemote:FireClient(player, text, kind or "info")
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
local stations = World.build()

local function leaveStation(player, placeOutside)
	local s = sessions[player]
	if not s or not s.station then
		return
	end
	local station = s.station
	station.occupant = nil
	station.model:SetAttribute("Occupant", nil)
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
		notify(player, "Тренажёр занят, найди свободный", "warn")
		return
	end
	local sila = Config.sila(s.profile.stats)
	if sila < station.cfg.unlock then
		notify(player, "🔒 Откроется при Силе " .. Config.format(station.cfg.unlock), "warn")
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
	end
	-- Set Kind before Station: the client starts animating when Station appears
	character:SetAttribute("Kind", station.kind)
	character:SetAttribute("Station", station.id)
end

for _, station in ipairs(stations) do
	station.prompt.Triggered:Connect(function(player)
		enterStation(player, station)
	end)
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
		notify(player, "Слишком тяжело! Нужно " .. Config.format(req) .. ", у тебя " .. Config.format(have), "warn")
		return
	end
	if s.energy < cost then
		s.combo = 0
		RepFxRemote:FireAllClients(player, station.id, false, machine.stat, 0, false)
		notify(player, "Нет выносливости! Отдохни или побегай на дорожке", "warn")
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
		notify(player, "Слишком быстро — скорость снижена", "warn")
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
		notify(player, "Можно от 1 до " .. Config.MaxPlates .. " блинов", "warn")
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
		notify(player, "Нужно " .. Config.format(sp.req) .. " выносливости", "warn")
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
		notify(player, "Новый ранг: " .. r.title .. "! Бонус +" .. math.floor(r.bonus * 100) .. "%", "good")
	end
end)

---------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------
local function onPlayerAdded(player)
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
		lastNotify = {},
	}
	if not canSave and not Data.isStudio then
		notify(player, "Не удалось загрузить прогресс — он не будет сохранён в этой сессии", "warn")
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
		end
	end
end)

---------------------------------------------------------------------------
-- NPCs
---------------------------------------------------------------------------
Npcs.start(workspace:WaitForChild("Gym"), function()
	local list = {}
	for _, station in ipairs(stations) do
		if station.occupant then
			table.insert(list, { position = station.rootCF.Position })
		end
	end
	return list
end)
