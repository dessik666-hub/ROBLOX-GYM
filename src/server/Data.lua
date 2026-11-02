-- Player profile load/save with retries.
-- If loading fails, the profile is marked unsaveable so we never overwrite real data with zeros.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)

local Data = {}

local STORE_NAME = "NeonGymProfiles_v1"
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Data] DataStore unavailable (publish the place and enable Studio API access):", result)
	end
end

local function withRetries(fn)
	local lastErr
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(attempt)
	end
	return false, lastErr
end

function Data.defaultProfile()
	local stats = {}
	for _, s in ipairs(Config.Stats) do
		stats[s.key] = 0
	end
	return {
		stats = stats,
		rank = 1,
		plates = { 1, 0, 0, 0, 0, 0 },
		speed = 1,
	}
end

-- Copies only known fields with sane types, so a corrupted save can't break the game.
local function sanitize(raw)
	local profile = Data.defaultProfile()
	if typeof(raw) ~= "table" then
		return profile
	end
	if typeof(raw.stats) == "table" then
		for key in pairs(profile.stats) do
			local v = tonumber(raw.stats[key])
			if v and v >= 0 and v < 1e300 then
				profile.stats[key] = v
			end
		end
	end
	local rank = tonumber(raw.rank)
	if rank and Config.Ranks[math.floor(rank)] then
		profile.rank = math.floor(rank)
	end
	if typeof(raw.plates) == "table" then
		local plates = {}
		for i = 1, #Config.Plates do
			plates[i] = math.clamp(math.floor(tonumber(raw.plates[i]) or 0), 0, Config.MaxPlates)
		end
		local n = Config.plateCount(plates)
		if n >= 1 and n <= Config.MaxPlates then
			profile.plates = plates
		end
	end
	local speed = tonumber(raw.speed)
	if speed and Config.Speeds[math.floor(speed)] then
		profile.speed = math.floor(speed)
	end
	return profile
end

-- Returns profile, canSave
function Data.load(player)
	if not store then
		return Data.defaultProfile(), false
	end
	local ok, raw = withRetries(function()
		return store:GetAsync("p_" .. player.UserId)
	end)
	if not ok then
		warn("[Data] Load failed for", player.Name, raw)
		return Data.defaultProfile(), false
	end
	return sanitize(raw), true
end

function Data.save(player, profile)
	if not store then
		return false
	end
	local payload = {
		v = 1,
		stats = profile.stats,
		rank = profile.rank,
		plates = profile.plates,
		speed = profile.speed,
	}
	local ok, err = withRetries(function()
		store:SetAsync("p_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[Data] Save failed for", player.Name, err)
	end
	return ok
end

-- In Studio without API access the store call errors; that's expected.
Data.isStudio = RunService:IsStudio()

return Data
