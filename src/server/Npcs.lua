-- NPCs:
--   * receptionist who greets players (GDD)
--   * coach who walks the gym and cheers people on
--   * bodybuilders posing on the podium stage (like the reference video)
--   * spectators clapping along the red carpet
-- Posing and clapping are animated on clients by TrainAnimator (attribute "Pose").

local Players = game:GetService("Players")

local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)

local Npcs = {}

local GREETINGS = {
	"Добро пожаловать в Neon Gym!",
	"Зал справа, подиум слева",
	"Дорожка качает выносливость — без неё тяжёлый вес не поднять",
	"Накачался? Иди на подиум и покажи мышцы!",
	"Тапай по экрану на тренажёре, чтобы делать повторы",
}

local CHEERS = {
	"Давай, ещё разок!",
	"Ты лучший!",
	"Не бойся, тебе это легко!",
	"Держись, почти!",
	"Отличная техника!",
	"Вот это пампинг!",
}

local SKIN = {
	Color3.fromRGB(234, 184, 146),
	Color3.fromRGB(204, 142, 105),
	Color3.fromRGB(160, 105, 75),
	Color3.fromRGB(110, 72, 52),
}
local SHIRTS = {
	Color3.fromRGB(255, 80, 200),
	Color3.fromRGB(60, 190, 255),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(80, 230, 140),
}

local function makeRig(name, shirtColor, cf, width)
	local rig
	local ok = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		local skin = SKIN[math.random(1, #SKIN)]
		desc.HeadColor = skin
		desc.LeftArmColor = skin
		desc.RightArmColor = skin
		desc.LeftLegColor = Color3.fromRGB(30, 30, 40)
		desc.RightLegColor = desc.LeftLegColor
		desc.TorsoColor = shirtColor
		desc.WidthScale = width or 1.3
		desc.DepthScale = width or 1.3
		rig = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not rig then
		-- Fallback: a simple block figure so the game still runs
		rig = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name = "HumanoidRootPart"
		body.Size = Vector3.new(2, 5, 1)
		body.Color = shirtColor
		body.Parent = rig
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.2, 1.2, 1.2)
		head.CFrame = body.CFrame * CFrame.new(0, 3.1, 0)
		head.Parent = rig
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = head
		weld.Parent = body
		Instance.new("Humanoid").Parent = rig
		rig.PrimaryPart = body
	end

	rig.Name = name
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = name
		humanoid.NameDisplayDistance = 60
	end
	rig:PivotTo(cf)
	return rig
end

local function anchor(rig)
	local root = rig:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
	end
end

local function bubble(rig)
	local head = rig:FindFirstChild("Head")
	local gui = Instance.new("BillboardGui")
	gui.Name = "Bubble"
	gui.Size = UDim2.fromOffset(240, 50)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 60
	gui.Enabled = false
	gui.Parent = head

	local frame = Instance.new("TextLabel")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.TextColor3 = Color3.fromRGB(40, 20, 60)
	frame.Font = Enum.Font.GothamBold
	frame.TextScaled = true
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = frame
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = frame

	return function(text, seconds)
		frame.Text = text
		gui.Enabled = true
		task.delay(seconds or 3, function()
			if frame.Text == text then
				gui.Enabled = false
			end
		end)
	end
end

-- Overhead tag for a podium bodybuilder: Сила and name, like players have
local function strengthTag(rig, sila)
	local head = rig:FindFirstChild("Head")
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	if not head then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(200, 50)
	tag.StudsOffset = Vector3.new(0, 3, 0)
	tag.MaxDistance = 120
	tag.Parent = head
	local s = Instance.new("TextLabel")
	s.Size = UDim2.fromScale(1, 0.5)
	s.BackgroundTransparency = 1
	s.Text = "🏆 " .. Config.format(sila)
	s.TextScaled = true
	s.Font = Enum.Font.GothamBlack
	s.TextColor3 = Color3.fromRGB(255, 220, 90)
	s.TextStrokeTransparency = 0.3
	s.Parent = tag
	local n = Instance.new("TextLabel")
	n.Position = UDim2.fromScale(0, 0.5)
	n.Size = UDim2.fromScale(1, 0.5)
	n.BackgroundTransparency = 1
	n.Text = rig.Name
	n.TextScaled = true
	n.Font = Enum.Font.GothamBlack
	n.TextColor3 = Color3.new(1, 1, 1)
	n.TextStrokeTransparency = 0.3
	n.Parent = tag
end

-- layout: from World.build(); getTrainees() returns { { position } } of players on machines
function Npcs.start(parent, layout, getTrainees)
	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = parent

	-- Receptionist behind the desk, facing the spawn
	local a = layout.admin
	local admin = makeRig("Администратор Лана", SHIRTS[1], CFrame.lookAt(a.pos, a.pos + a.facing))
	admin.Parent = folder
	anchor(admin)
	local adminSay = bubble(admin)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(2)
			adminSay("Привет, " .. player.DisplayName .. "! " .. GREETINGS[1], 4)
			task.wait(4.5)
			adminSay(GREETINGS[2], 4)
		end)
	end)
	task.spawn(function()
		local i = 2
		while admin.Parent do
			task.wait(12)
			i = i % #GREETINGS + 1
			adminSay(GREETINGS[i], 5)
		end
	end)

	-- Bodybuilders posing on the stage
	for _, p in ipairs(layout.posers) do
		local rig = makeRig(p.name, SHIRTS[math.random(1, #SHIRTS)], CFrame.lookAt(p.pos, p.pos + p.facing), 1.7)
		rig.Parent = folder
		anchor(rig)
		rig:SetAttribute("Pose", "pose")
		strengthTag(rig, p.sila)
	end

	-- Spectators clapping along the carpet
	for i, s in ipairs(layout.spectators) do
		local rig = makeRig("Зритель " .. i, SHIRTS[math.random(1, #SHIRTS)], CFrame.lookAt(s.pos, s.pos + s.facing), 1.0)
		rig.Parent = folder
		anchor(rig)
		rig:SetAttribute("Pose", "clap")
		local humanoid = rig:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end

	-- Coach walks to trainees in the gym and cheers
	local area = layout.coachArea
	local start = Vector3.new((area.min.X + area.max.X) / 2, 3.2, 0)
	local coach = makeRig("Тренер Макс", SHIRTS[2], CFrame.new(start))
	coach.Parent = folder
	local coachRoot = coach:FindFirstChild("HumanoidRootPart")
	local coachHumanoid = coach:FindFirstChildOfClass("Humanoid")
	if coachRoot and coachRoot:CanSetNetworkOwnership() then
		coachRoot:SetNetworkOwner(nil)
	end
	local coachSay = bubble(coach)

	task.spawn(function()
		while coach.Parent and coachHumanoid and coachRoot do
			local trainees = getTrainees()
			local target
			if #trainees > 0 then
				local pick = trainees[math.random(1, #trainees)]
				target = pick.position + Vector3.new(math.random(-4, 4), 0, 6)
			else
				target = Vector3.new(math.random(area.min.X, area.max.X), 3, math.random(area.min.Y, area.max.Y))
			end
			coachHumanoid:MoveTo(target)
			coachHumanoid.MoveToFinished:Wait()
			if #trainees > 0 then
				coachSay(CHEERS[math.random(1, #CHEERS)], 3)
			end
			task.wait(math.random(3, 6))
		end
	end)
end

return Npcs
