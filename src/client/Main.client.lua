-- Client entry: HUD, input, machine name tags, popups and animations.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local TrainAnimator = require(script.Parent:WaitForChild("TrainAnimator"))
local Popups = require(script.Parent:WaitForChild("Popups"))

local player = Players.LocalPlayer
local remotes = RS:WaitForChild("Remotes")
local function r(name)
	return remotes:WaitForChild(name)
end
local SyncRemote, RepFxRemote, RunFxRemote, NotifyRemote = r("Sync"), r("RepFx"), r("RunFx"), r("Notify")
local FameFxRemote = r("FameFx")
local RepRemote, SetPlatesRemote, SetSpeedRemote, SetAutoRemote, LeaveRemote, RankUpRemote =
	r("Rep"), r("SetPlates"), r("SetSpeed"), r("SetAuto"), r("Leave"), r("RankUp")

local state = nil -- last snapshot from the server
local pendingPlates = nil -- local plate edits not yet confirmed
local pendingUntil = 0

local function currentPlates()
	if pendingPlates and os.clock() < pendingUntil then
		return pendingPlates
	end
	return state and state.plates or { 1, 0, 0, 0, 0, 0 }
end

local function refresh()
	if state then
		Hud.update(state, currentPlates())
	end
end

---------------------------------------------------------------------------
-- HUD callbacks
---------------------------------------------------------------------------
Hud.build({
	plate = function(i, delta)
		local plates = table.clone(currentPlates())
		local nextValue = (plates[i] or 0) + delta
		if nextValue < 0 then
			return
		end
		plates[i] = nextValue
		local n = Config.plateCount(plates)
		if n > Config.MaxPlates then
			Hud.toast("Максимум блинов — " .. Config.MaxPlates, "warn")
			return
		end
		if n < 1 then
			Hud.toast("Нужен хотя бы один блин", "warn")
			return
		end
		pendingPlates = plates
		pendingUntil = os.clock() + 1
		SetPlatesRemote:FireServer(plates)
		refresh()
	end,
	speed = function(i)
		SetSpeedRemote:FireServer(i)
	end,
	auto = function()
		SetAutoRemote:FireServer(not (state and state.auto))
	end,
	leave = function()
		LeaveRemote:FireServer()
	end,
	rankUp = function()
		RankUpRemote:FireServer()
	end,
})

---------------------------------------------------------------------------
-- Machine name tags (local, so each player sees their own lock state)
---------------------------------------------------------------------------
local tags = {} -- [model] = { lock = TextLabel, prompt = ProximityPrompt, unlock = number }

local function addTag(model)
	local kind = model:GetAttribute("Kind")
	local machine = kind and Config.Machines[kind]
	local anchor = model.PrimaryPart or model:WaitForChild("PromptAnchor", 5)
	if not machine or not anchor then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 40)
	gui.StudsOffset = Vector3.new(0, machine.type == "pose" and 9 or 6, 0)
	gui.MaxDistance = machine.type == "pose" and 60 or 28
	gui.Adornee = anchor
	gui.Parent = anchor

	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.55)
	name.BackgroundTransparency = 1
	name.Text = machine.name
	name.TextScaled = true
	name.Font = Enum.Font.GothamBlack
	name.TextColor3 = Color3.fromRGB(255, 150, 235)
	name.TextStrokeTransparency = 0.3
	name.Parent = gui

	local lock = Instance.new("TextLabel")
	lock.Position = UDim2.fromScale(0, 0.55)
	lock.Size = UDim2.fromScale(1, 0.45)
	lock.BackgroundTransparency = 1
	lock.TextScaled = true
	lock.Font = Enum.Font.GothamBold
	lock.TextStrokeTransparency = 0.3
	lock.Parent = gui

	local applaudAnchor = model:FindFirstChild("ApplaudAnchor")
	tags[model] = {
		lock = lock,
		prompt = anchor:WaitForChild("TrainPrompt", 5),
		applaud = applaudAnchor and applaudAnchor:WaitForChild("ApplaudPrompt", 5),
		unlock = machine.unlock,
		machine = machine,
	}
end

task.spawn(function()
	local stations = workspace:WaitForChild("Gym"):WaitForChild("Stations")
	for _, model in ipairs(stations:GetChildren()) do
		task.spawn(addTag, model)
	end
	stations.ChildAdded:Connect(function(model)
		task.spawn(addTag, model)
	end)
end)

local function updateTags()
	if not state then
		return
	end
	local sila = Config.sila(state.stats)
	local training = state.kind ~= nil
	for model, tag in pairs(tags) do
		local unlocked = sila >= tag.unlock
		local occupantId = model:GetAttribute("Occupant")
		local busy = occupantId ~= nil
		if tag.machine.type == "pose" then
			local occupant = busy and Players:GetPlayerByUserId(occupantId)
			if occupant then
				tag.lock.Text = "🌟 " .. occupant.DisplayName
				tag.lock.TextColor3 = Color3.fromRGB(255, 220, 120)
			else
				tag.lock.Text = "Свободно — покажи мышцы!"
				tag.lock.TextColor3 = Color3.fromRGB(150, 240, 170)
			end
		elseif not unlocked then
			tag.lock.Text = "🔒 Сила " .. Config.format(tag.unlock)
			tag.lock.TextColor3 = Color3.fromRGB(255, 110, 110)
		elseif busy then
			tag.lock.Text = "Занято"
			tag.lock.TextColor3 = Color3.fromRGB(255, 200, 90)
		else
			local stat = tag.machine.stat == "all" and "🔥 всё тело" or (Config.StatByKey[tag.machine.stat].icon .. " " .. Config.StatByKey[tag.machine.stat].name)
			tag.lock.Text = stat
			tag.lock.TextColor3 = Color3.fromRGB(150, 240, 170)
		end
		-- Prompts are hidden locally while training or when the machine is taken
		if tag.prompt then
			tag.prompt.Enabled = not training and not busy
		end
		if tag.applaud then
			tag.applaud.Enabled = busy and occupantId ~= player.UserId and not training
		end
	end
end

---------------------------------------------------------------------------
-- Server -> client
---------------------------------------------------------------------------
SyncRemote.OnClientEvent:Connect(function(snapshot)
	state = snapshot
	if pendingPlates and table.concat(pendingPlates, ",") == table.concat(snapshot.plates, ",") then
		pendingPlates = nil
	end
	refresh()
	updateTags()
end)

RepFxRemote.OnClientEvent:Connect(function(who, _stationId, ok, statKey, gain, sweet)
	if not who then
		return
	end
	TrainAnimator.onRep(who, ok)
	local character = who.Character
	if ok and gain > 0 then
		local stat = statKey == "all" and { icon = "🔥", color = Color3.fromRGB(255, 120, 60) } or Config.StatByKey[statKey]
		Popups.show(character, "+" .. Config.format(gain) .. " " .. stat.icon, stat.color, who == player)
		if sweet and who == player then
			Popups.show(character, "Идеальный вес!", Color3.fromRGB(255, 230, 120), true)
		end
	elseif not ok and who == player then
		Popups.show(character, "✖", Color3.fromRGB(255, 80, 90), false)
	end
end)

RunFxRemote.OnClientEvent:Connect(function(who, gain)
	if who and who.Character then
		Popups.show(who.Character, "+" .. Config.format(gain) .. " ❤", Config.StatByKey.stamina.color, who == player)
	end
end)

FameFxRemote.OnClientEvent:Connect(function(poser, gain, applauder)
	if poser and poser.Character then
		Popups.show(poser.Character, "+" .. Config.format(gain) .. " ⭐", Color3.fromRGB(255, 215, 80), poser == player)
	end
	if applauder and applauder.Character then
		Popups.show(applauder.Character, "👏", Color3.new(1, 1, 1), false)
	end
end)

NotifyRemote.OnClientEvent:Connect(function(text, kind)
	Hud.toast(text, kind)
end)

---------------------------------------------------------------------------
-- Input: tap/click = rep on weight machines, Q = leave
---------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not state or not state.kind then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		LeaveRemote:FireServer()
		return
	end
	local machine = Config.Machines[state.kind]
	if machine and machine.type == "weights" then
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonR2 then
			RepRemote:FireServer()
		end
	end
end)
