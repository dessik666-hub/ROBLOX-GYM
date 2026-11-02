-- NPCs: the receptionist who greets players (GDD) and a coach who walks
-- the gym and cheers people on (like the trainers in the reference video).

local Players = game:GetService("Players")

local Npcs = {}

local GREETINGS = {
	"Привет! Добро пожаловать в Neon Gym!",
	"Начни с гантелей и беговой дорожки",
	"Дорожка качает выносливость — без неё тяжёлый вес не поднять",
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

local function makeRig(name, shirtColor, position, facing)
	local rig
	local ok = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		desc.HeadColor = Color3.fromRGB(234, 184, 146)
		desc.LeftArmColor = desc.HeadColor
		desc.RightArmColor = desc.HeadColor
		desc.LeftLegColor = Color3.fromRGB(30, 30, 40)
		desc.RightLegColor = desc.LeftLegColor
		desc.TorsoColor = shirtColor
		desc.WidthScale = 1.3
		desc.DepthScale = 1.3
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
	rig:PivotTo(CFrame.lookAt(position, position + facing))
	return rig
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

-- getTrainees() returns a list of { position } for players currently on a machine
function Npcs.start(parent, getTrainees)
	local folder = Instance.new("Folder")
	folder.Name = "NPCs"
	folder.Parent = parent

	-- Receptionist behind the desk, facing the spawn
	local admin = makeRig("Администратор Лана", Color3.fromRGB(255, 80, 200), Vector3.new(0, 3.2, 91), Vector3.new(0, 0, -1))
	admin.Parent = folder
	local adminRoot = admin:FindFirstChild("HumanoidRootPart")
	if adminRoot then
		adminRoot.Anchored = true
	end
	local adminSay = bubble(admin)

	-- Greet each player shortly after they spawn
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

	-- Coach walks to trainees and cheers
	local coach = makeRig("Тренер Макс", Color3.fromRGB(60, 190, 255), Vector3.new(0, 3.2, 30), Vector3.new(0, 0, -1))
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
				target = pick.position + Vector3.new(math.random(-4, 4), 0, 5)
			else
				target = Vector3.new(math.random(-40, 40), 3, math.random(-10, 25))
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
