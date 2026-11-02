-- All tuning for Neon Gym Simulator lives here.
-- Numbers are first guesses and need a playtest (see README).

local Config = {}

---------------------------------------------------------------------------
-- Stats. Order matches the top bar in the reference video.
---------------------------------------------------------------------------
Config.Stats = {
	{ key = "stamina", name = "Выносливость", icon = "❤", color = Color3.fromRGB(255, 70, 110) },
	{ key = "chest", name = "Грудь", icon = "🛡", color = Color3.fromRGB(90, 230, 140) },
	{ key = "abs", name = "Пресс", icon = "🍫", color = Color3.fromRGB(255, 200, 90) },
	{ key = "back", name = "Спина", icon = "🦾", color = Color3.fromRGB(90, 170, 255) },
	{ key = "arms", name = "Руки", icon = "💪", color = Color3.fromRGB(255, 120, 60) },
	{ key = "legs", name = "Ноги", icon = "🦵", color = Color3.fromRGB(220, 90, 255) },
}

Config.StatByKey = {}
for _, s in ipairs(Config.Stats) do
	Config.StatByKey[s.key] = s
end

Config.Muscles = { "chest", "abs", "back", "arms", "legs" }

---------------------------------------------------------------------------
-- Machines. type = "weights" (tap reps with plates) or "cardio" (auto, speeds).
-- unlock = total Сила (sum of all stats) needed to use the machine.
-- mult = gain multiplier of this machine. repTime = animation length, seconds.
---------------------------------------------------------------------------
Config.Machines = {
	dumbbells = { name = "Гантели", type = "weights", stat = "arms", mult = 1, unlock = 0, repTime = 0.8 },
	treadmill = { name = "Беговая дорожка", type = "cardio", stat = "stamina", mult = 1, unlock = 0 },
	bench = { name = "Скамья для жима", type = "weights", stat = "chest", mult = 1, unlock = 150, repTime = 0.8 },
	abs = { name = "Скамья для пресса", type = "weights", stat = "abs", mult = 1, unlock = 600, repTime = 0.9 },
	legpress = { name = "Жим ногами", type = "weights", stat = "legs", mult = 1, unlock = 2000, repTime = 0.9 },
	pulldown = { name = "Тяга верхнего блока", type = "weights", stat = "back", mult = 1, unlock = 6000, repTime = 1.0 },
	rower = { name = "Гребной тренажёр", type = "cardio", stat = "stamina", mult = 2, unlock = 20000 },
	squat = { name = "Приседания со штангой", type = "weights", stat = "legs", mult = 2.5, unlock = 80000, repTime = 1.1 },
	cable = { name = "Кроссовер", type = "weights", stat = "chest", mult = 2.5, unlock = 300000, repTime = 1.0 },
	titan = { name = "Неоновый комплекс «Титан»", type = "weights", stat = "all", mult = 1.5, unlock = 1500000, repTime = 1.3 },
	-- Not a machine: a posing spot on the podium stage
	pose = { name = "Подиум", type = "pose", unlock = 0 },
}

---------------------------------------------------------------------------
-- Podium: players pose on stage and earn Слава (fame).
---------------------------------------------------------------------------
Config.CrowdInterval = 5 -- NPC spectators applaud every 5 seconds
Config.ApplauseFame = 5 -- one applause from a real player
Config.ApplauseCooldown = 3 -- seconds between applause from the same player

-- Bigger muscles, louder crowd: 1 fame at the start, ~8 at 10M Сила
function Config.crowdFame(sila)
	return 1 + math.floor(math.log10(math.max(sila, 0) + 1))
end

---------------------------------------------------------------------------
-- Weight plates (bottom bar on weight machines, like in the video).
---------------------------------------------------------------------------
Config.Plates = {
	{ weight = 1, color = Color3.fromRGB(70, 70, 80) },
	{ weight = 2, color = Color3.fromRGB(40, 200, 90) },
	{ weight = 5, color = Color3.fromRGB(40, 140, 255) },
	{ weight = 20, color = Color3.fromRGB(255, 210, 40) },
	{ weight = 50, color = Color3.fromRGB(240, 60, 50) },
	{ weight = 100, color = Color3.fromRGB(25, 25, 35) },
}
Config.MaxPlates = 10

function Config.totalWeight(counts)
	local total = 0
	for i, plate in ipairs(Config.Plates) do
		total += plate.weight * (counts[i] or 0)
	end
	return total
end

function Config.plateCount(counts)
	local n = 0
	for i = 1, #Config.Plates do
		n += counts[i] or 0
	end
	return n
end

-- Stat needed to lift a weight. 1 lb needs 0, 21 lb needs 400, 101 lb needs 10K.
function Config.requirement(weight)
	return (weight - 1) ^ 2
end

-- Base gain of one rep (before machine mult and bonuses).
function Config.repGain(weight)
	return 1 + weight * 0.3
end

-- Stamina spent per rep.
function Config.repCost(weight)
	return math.max(1, math.ceil(weight / 4))
end

---------------------------------------------------------------------------
-- Cardio speeds (bottom bar on treadmill / rower). req = stamina stat needed.
-- gain = stamina per second at mult 1.
---------------------------------------------------------------------------
Config.Speeds = {
	{ mph = 3, req = 0, gain = 1 },
	{ mph = 6, req = 100, gain = 3 },
	{ mph = 9, req = 350, gain = 5 },
	{ mph = 12, req = 800, gain = 7 },
	{ mph = 15, req = 1500, gain = 9 },
	{ mph = 18, req = 2200, gain = 11 },
	{ mph = 21, req = 3000, gain = 13 },
	{ mph = 25, req = 5200, gain = 16 },
	{ mph = 35, req = 15000, gain = 28 },
	{ mph = 50, req = 50000, gain = 50 },
}

---------------------------------------------------------------------------
-- Stamina as a resource (the ring over the head in the video).
-- Max = base + stamina stat. Reps spend it, rest refills it.
---------------------------------------------------------------------------
Config.EnergyBase = 50
Config.EnergyRegenDelay = 1.0 -- seconds without reps before refill starts
Config.EnergyRegenPct = 0.15 -- share of max refilled per second

function Config.energyMax(stats)
	return Config.EnergyBase + (stats.stamina or 0)
end

---------------------------------------------------------------------------
-- Reps
---------------------------------------------------------------------------
Config.RepCooldown = 0.3 -- server rate limit (GDD: no more than ~3.3 reps/s)
Config.AutoInterval = 0.5 -- auto-train: 2 reps/s, slower than tapping (GDD)

-- Own additions
Config.ComboWindow = 1.2 -- "Неоновый пампинг": reps closer than this keep the combo
Config.ComboStep = 0.02 -- +2% per rep in a combo
Config.ComboMax = 0.5 -- capped at +50%
Config.SweetRatio = 0.75 -- "Идеальный вес": requirement >= 75% of your stat...
Config.SweetBonus = 0.5 -- ...gives +50% to the rep

---------------------------------------------------------------------------
-- Ranks. Every stat must reach the requirement (like the video's profile).
-- Simulated perfect play: max rank in ~4 h (6-8 h of real play, as in the GDD).
---------------------------------------------------------------------------
Config.Ranks = {
	{ title = "Новичок", muscle = 0, stamina = 0, bonus = 0 },
	{ title = "Начинающий", muscle = 50, stamina = 20, bonus = 0.1 },
	{ title = "Любитель", muscle = 500, stamina = 150, bonus = 0.2 },
	{ title = "Сильный парень", muscle = 5000, stamina = 800, bonus = 0.3 },
	{ title = "Атлет", muscle = 25000, stamina = 2500, bonus = 0.4 },
	{ title = "Качок", muscle = 150000, stamina = 8000, bonus = 0.5 },
	{ title = "Чемпион зала", muscle = 800000, stamina = 25000, bonus = 0.6 },
	{ title = "Неоновый титан", muscle = 4000000, stamina = 80000, bonus = 0.8 },
}

function Config.rankRequirement(rankIndex, statKey)
	local r = Config.Ranks[rankIndex]
	if not r then
		return math.huge
	end
	return statKey == "stamina" and r.stamina or r.muscle
end

function Config.canRankUp(stats, rank)
	local nextRank = Config.Ranks[rank + 1]
	if not nextRank then
		return false
	end
	for _, s in ipairs(Config.Stats) do
		if (stats[s.key] or 0) < Config.rankRequirement(rank + 1, s.key) then
			return false
		end
	end
	return true
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function Config.sila(stats)
	local total = 0
	for _, s in ipairs(Config.Stats) do
		total += stats[s.key] or 0
	end
	return total
end

-- Stat used for a machine's requirement (titan uses the weakest muscle).
function Config.machineStat(stats, machine)
	if machine.stat == "all" then
		local lowest = math.huge
		for _, key in ipairs(Config.Muscles) do
			lowest = math.min(lowest, stats[key] or 0)
		end
		return lowest
	end
	return stats[machine.stat] or 0
end

function Config.format(n)
	n = math.floor(n or 0)
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if n >= u[1] then
			local v = n / u[1]
			return (v >= 100 and string.format("%d", v) or string.format("%.1f", v)) .. u[2]
		end
	end
	return tostring(n)
end

return Config
