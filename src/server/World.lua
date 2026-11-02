-- Builds the club in code: everything stands outdoors on an open grass field.
--
-- Top view (the player spawns facing -Z):
--
--      PODIUM HALL        |   LOBBY    |          GYM HALL
--   x -280 ... -60        | -60 ... 60 |       60 ... 400
--   stage, star, carpet   | reception  |  cardio, strength, titan
--                         |   spawn    |
--
-- The gym is to the right of the spawn, the podium to the left.

local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS.Shared.Config)
local MachineModels = require(script.Parent.MachineModels)

local World = {}

local FLOOR = Color3.fromRGB(28, 18, 48)
local WALL = Color3.fromRGB(22, 14, 40)
local CARDIO = Color3.fromRGB(60, 190, 255)
local STRENGTH = Color3.fromRGB(170, 90, 255)
local PINK = Color3.fromRGB(255, 80, 200)
local GOLD = Color3.fromRGB(255, 200, 60)
local RED = Color3.fromRGB(190, 25, 55)

-- Banner font: Oswald (narrow, sporty, supports Cyrillic) with a neon outline.
-- Many decorative Roblox fonts have no Cyrillic glyphs and silently fall back.
local SIGN_FONT = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)

local MIN_X, MAX_X = -280, 400
local MIN_Z, MAX_Z = -130, 130
local HEIGHT = 40
local CENTER_X = (MIN_X + MAX_X) / 2
local WIDTH_X = MAX_X - MIN_X
local DEPTH_Z = MAX_Z - MIN_Z

-- Facing helpers for signs (text is on the part's Back face = local +Z)
local FACE_PLUS_Z = CFrame.new()
local FACE_MINUS_X = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_PLUS_X = CFrame.Angles(0, math.pi / 2, 0)

---------------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------------
local function part(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Text styled like a neon tube: bright core, colored glow outline
local function neonText(label, color, glow)
	label.FontFace = SIGN_FONT
	label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.55)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = glow or 4
	stroke.Transparency = 0.1
	stroke.Parent = label
end

-- Two dark posts from the ground up to the bottom of a board
local function posts(parent, cf, width, bottomY)
	if bottomY <= 0.5 then
		return
	end
	for _, side in ipairs({ -1, 1 }) do
		local base = cf * CFrame.new(side * (width / 2 - 1), 0, 0)
		part(parent, "Post", Vector3.new(0.8, bottomY, 0.8), CFrame.new(base.Position.X, bottomY / 2, base.Position.Z), Color3.fromRGB(35, 30, 45), Enum.Material.Metal)
	end
end

local function sign(parent, text, pos, facing, color, width, height)
	local board = part(parent, "Sign", Vector3.new(width or 24, height or 5, 0.4), CFrame.new(pos) * facing, Color3.fromRGB(12, 8, 22))
	board.CanCollide = false
	posts(parent, CFrame.new(pos) * facing, width or 24, pos.Y - (height or 5) / 2)
	-- Neon frame around the board
	local w, h = width or 24, height or 5
	local frameCF = CFrame.new(pos) * facing
	for _, e in ipairs({
		{ Vector3.new(w, 0.25, 0.5), CFrame.new(0, h / 2, 0) },
		{ Vector3.new(w, 0.25, 0.5), CFrame.new(0, -h / 2, 0) },
		{ Vector3.new(0.25, h, 0.5), CFrame.new(w / 2, 0, 0) },
		{ Vector3.new(0.25, h, 0.5), CFrame.new(-w / 2, 0, 0) },
	}) do
		local edge = part(parent, "SignFrame", e[1], frameCF * e[2], color, Enum.Material.Neon)
		edge.CanCollide = false
	end

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 30
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Parent = gui
	neonText(label, color, 5)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = label
	return board
end

local function zone(parent, name, center, size, color)
	part(parent, name, Vector3.new(size.X, 0.1, size.Y), CFrame.new(center.X, 0.05, center.Y), color:Lerp(FLOOR, 0.82))
	local half = size / 2
	local edges = {
		{ Vector3.new(size.X, 0.15, 0.4), Vector3.new(center.X, 0.08, center.Y - half.Y) },
		{ Vector3.new(size.X, 0.15, 0.4), Vector3.new(center.X, 0.08, center.Y + half.Y) },
		{ Vector3.new(0.4, 0.15, size.Y), Vector3.new(center.X - half.X, 0.08, center.Y) },
		{ Vector3.new(0.4, 0.15, size.Y), Vector3.new(center.X + half.X, 0.08, center.Y) },
	}
	for _, e in ipairs(edges) do
		part(parent, name .. "Edge", e[1], CFrame.new(e[2]), color, Enum.Material.Neon)
	end
end

-- A board with a title and N text lines, for leaderboards and the stage screen
local function screen(parent, name, size, cf, face, title, lineCount, accent)
	local board = part(parent, name, size, cf, Color3.fromRGB(12, 8, 22))
	board.CanCollide = false
	-- Posts along the board's long side
	local postCF = size.X >= size.Z and cf or cf * CFrame.Angles(0, math.pi / 2, 0)
	posts(parent, postCF, math.max(size.X, size.Z), cf.Position.Y - size.Y / 2)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 25
	gui.Parent = board

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.03, 0)
	pad.PaddingRight = UDim.new(0.03, 0)
	pad.PaddingTop = UDim.new(0.03, 0)
	pad.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	local function line(text, h, color, order)
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, h)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextScaled = true
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.LayoutOrder = order
		l.Parent = frame
		return l
	end

	local titleLabel = line(title, 0.2, accent, 0)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	neonText(titleLabel, accent, 3)
	local lines = {}
	for i = 1, lineCount do
		lines[i] = line("", 0.74 / lineCount, Color3.new(1, 1, 1), i)
	end
	return { board = board, lines = lines }
end

local function setupLighting()
	-- Sunny afternoon over the field
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(70, 70, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 135)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 2
	bloom.Parent = Lighting
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.3
		atmosphere.Haze = 1
		atmosphere.Color = Color3.fromRGB(199, 220, 255)
		atmosphere.Decay = Color3.fromRGB(106, 140, 180)
		atmosphere.Parent = Lighting
	end
	if not workspace.Terrain:FindFirstChildOfClass("Clouds") then
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.5
		clouds.Density = 0.6
		clouds.Parent = workspace.Terrain
	end
end

---------------------------------------------------------------------------
-- Station layout: { kind, x, z, y?, yaw? }. Machines face -Z unless yaw is set.
---------------------------------------------------------------------------
local function row(list, kind, count, x0, step, z)
	for i = 0, count - 1 do
		table.insert(list, { kind, x0 + i * step, z })
	end
end

local function buildLayout()
	local L = {}
	-- Cardio zone (blue), near the gym entrance
	row(L, "treadmill", 8, 95, 16, 80)
	row(L, "rower", 4, 100, 35, 108)
	-- Strength zone (purple): one row per machine
	row(L, "dumbbells", 8, 100, 22, 30)
	row(L, "bench", 8, 100, 22, 8)
	row(L, "abs", 6, 100, 22, -14)
	row(L, "legpress", 6, 100, 22, -36)
	row(L, "pulldown", 6, 100, 22, -58)
	row(L, "squat", 6, 100, 22, -80)
	row(L, "cable", 6, 100, 22, -104)
	-- Titan arena (pink)
	table.insert(L, { "titan", 350, -75 })
	table.insert(L, { "titan", 350, -35 })
	-- Podium: three posing spots on the stage, facing the audience (+X)
	for _, z in ipairs({ -14, 0, 14 }) do
		table.insert(L, { "pose", -252, z, 3, -math.pi / 2 })
	end
	return L
end

---------------------------------------------------------------------------
-- Areas
---------------------------------------------------------------------------
-- Open grass field instead of a building, with trees around the edge
local function buildField(hall)
	local terrain = workspace.Terrain
	-- Grass top sits exactly at y = 0 (terrain voxels are 4 studs)
	terrain:FillBlock(CFrame.new(60, -8, 0), Vector3.new(1600, 16, 1200), Enum.Material.Grass)

	-- Trees around the play area
	local rng = Random.new(42)
	local placed = 0
	while placed < 70 do
		local x = rng:NextNumber(-560, 680)
		local z = rng:NextNumber(-520, 520)
		local insidePlay = x > -320 and x < 440 and z > -165 and z < 165
		if not insidePlay then
			placed += 1
			local height = rng:NextNumber(10, 18)
			part(hall, "TreeTrunk", Vector3.new(1.6, height, 1.6), CFrame.new(x, height / 2, z), Color3.fromRGB(105, 70, 45), Enum.Material.Wood)
			local crown = rng:NextNumber(10, 16)
			local leaves = part(hall, "TreeLeaves", Vector3.new(crown, crown, crown), CFrame.new(x, height + crown * 0.3, z), Color3.fromRGB(60, 140 + rng:NextInteger(0, 40), 60), Enum.Material.Grass)
			leaves.Shape = Enum.PartType.Ball
		end
	end

	-- Signposts pointing to the gym area and the podium
	sign(hall, "ТРЕНАЖЁРНЫЙ ЗАЛ →", Vector3.new(40, 9, -6), FACE_PLUS_Z, STRENGTH, 30, 6)
	sign(hall, "← ПОДИУМ", Vector3.new(-40, 9, -6), FACE_PLUS_Z, PINK, 24, 6)
end

local function buildLobby(hall)
	part(hall, "ReceptionDesk", Vector3.new(18, 4, 3), CFrame.new(0, 2, 25), Color3.fromRGB(50, 30, 80), Enum.Material.Glass)
	part(hall, "ReceptionGlow", Vector3.new(18.2, 0.4, 3.2), CFrame.new(0, 4.1, 25), PINK, Enum.Material.Neon)
	sign(hall, "NEON GYM", Vector3.new(0, 14, 14), FACE_PLUS_Z, PINK, 40, 9)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, 45) -- front (-Z) faces the reception
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = hall

	-- Glowing paths from the spawn to both arches
	part(hall, "PathGym", Vector3.new(60, 0.12, 3), CFrame.new(30, 0.06, 0), STRENGTH, Enum.Material.Neon)
	part(hall, "PathPodium", Vector3.new(60, 0.12, 3), CFrame.new(-30, 0.06, 0), PINK, Enum.Material.Neon)
	part(hall, "PathCenter", Vector3.new(3, 0.12, 45), CFrame.new(0, 0.06, 22), GOLD, Enum.Material.Neon)

	return screen(hall, "TopBoard", Vector3.new(50, 22, 1), CFrame.new(0, 15, -60), Enum.NormalId.Back, "🏆 ТОП ПО СИЛЕ", 10, GOLD)
end

local function buildGym(hall)
	zone(hall, "CardioZone", Vector2.new(155, 95), Vector2.new(150, 60), CARDIO)
	zone(hall, "StrengthZone", Vector2.new(178, -37), Vector2.new(196, 170), STRENGTH)
	zone(hall, "TitanZone", Vector2.new(350, -55), Vector2.new(50, 90), PINK)
	zone(hall, "VipZone", Vector2.new(330, 95), Vector2.new(100, 50), GOLD)

	sign(hall, "КАРДИО", Vector3.new(80, 9, 95), FACE_MINUS_X, CARDIO, 30, 6)
	sign(hall, "СИЛОВАЯ ЗОНА", Vector3.new(80, 9, -37), FACE_MINUS_X, STRENGTH, 40, 6)
	sign(hall, "ТИТАН", Vector3.new(322, 9, -55), FACE_MINUS_X, PINK, 24, 6)
	sign(hall, "VIP-ЗАЛ · скоро", Vector3.new(282, 9, 95), FACE_MINUS_X, GOLD, 36, 6)
end

local function buildPodium(hall)
	zone(hall, "PodiumZone", Vector2.new(-170, 0), Vector2.new(212, 250), PINK)

	-- Backdrop with a giant star (like the stage in the reference video)
	local backdrop = part(hall, "Backdrop", Vector3.new(1, 34, 100), CFrame.new(-278, 17, 0), Color3.fromRGB(25, 15, 60))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.PixelsPerStud = 15
	gui.Parent = backdrop
	local star = Instance.new("TextLabel")
	star.AnchorPoint = Vector2.new(0.5, 0)
	star.Position = UDim2.fromScale(0.5, 0.02)
	star.Size = UDim2.fromScale(0.5, 0.75)
	star.BackgroundTransparency = 1
	star.Text = "★"
	star.TextScaled = true
	star.TextColor3 = GOLD
	star.Font = Enum.Font.GothamBlack
	star.Parent = gui
	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromScale(0, 0.76)
	title.Size = UDim2.fromScale(1, 0.18)
	title.BackgroundTransparency = 1
	title.Text = "NEON STAGE"
	title.TextScaled = true
	title.Parent = gui
	neonText(title, PINK, 6)
	for _, z in ipairs({ -50, 50 }) do
		part(hall, "BackdropGlow", Vector3.new(1.4, 34, 1), CFrame.new(-277.5, 17, z), PINK, Enum.Material.Neon)
	end
	part(hall, "BackdropGlowTop", Vector3.new(1.4, 1, 100), CFrame.new(-277.5, 34, 0), PINK, Enum.Material.Neon)

	-- Stage
	part(hall, "Stage", Vector3.new(40, 3, 100), CFrame.new(-257, 1.5, 0), Color3.fromRGB(30, 18, 45), Enum.Material.Glass)
	part(hall, "StageEdge", Vector3.new(0.6, 3.1, 100), CFrame.new(-237, 1.55, 0), GOLD, Enum.Material.Neon)
	part(hall, "Steps", Vector3.new(6, 1.5, 36), CFrame.new(-234, 0.75, 0), Color3.fromRGB(40, 25, 60))
	part(hall, "StepsGlow", Vector3.new(0.4, 1.6, 36), CFrame.new(-231, 0.8, 0), GOLD, Enum.Material.Neon)

	-- Red carpet with golden stars from the stage toward the lobby
	part(hall, "Carpet", Vector3.new(160, 0.2, 16), CFrame.new(-151, 0.1, 0), RED, Enum.Material.Fabric)
	for x = -225, -77, 12 do
		for _, z in ipairs({ -5.5, 5.5 }) do
			local s = part(hall, "CarpetStar", Vector3.new(1.4, 0.25, 1.4), CFrame.new(x, 0.22, z) * CFrame.Angles(0, math.rad(45), 0), GOLD, Enum.Material.Neon)
			s.CanCollide = false
		end
	end

	-- Rope barriers along the carpet
	for _, z in ipairs({ -12, 12 }) do
		for x = -226, -78, 16 do
			part(hall, "RopePost", Vector3.new(0.6, 3, 0.6), CFrame.new(x, 1.5, z), GOLD, Enum.Material.Metal)
		end
		local rope = part(hall, "Rope", Vector3.new(148, 0.3, 0.3), CFrame.new(-152, 2.6, z), PINK, Enum.Material.Neon)
		rope.CanCollide = false
	end

	-- Screen above the carpet with the current posers
	local stageScreen = screen(hall, "StageScreen", Vector3.new(1, 14, 44), CFrame.new(-200, 20, 0), Enum.NormalId.Right, "🌟 СЕЙЧАС НА ПОДИУМЕ", 3, PINK)

	return stageScreen
end

---------------------------------------------------------------------------
-- Build everything
---------------------------------------------------------------------------
function World.build()
	setupLighting()

	local gym = Instance.new("Folder")
	gym.Name = "Gym"
	gym.Parent = workspace

	local hall = Instance.new("Folder")
	hall.Name = "Hall"
	hall.Parent = gym

	buildField(hall)
	local topBoard = buildLobby(hall)
	buildGym(hall)
	local stageScreen = buildPodium(hall)

	-- Stations
	local stationsFolder = Instance.new("Folder")
	stationsFolder.Name = "Stations"
	stationsFolder.Parent = gym

	local stations = {}
	local counter = {}
	for _, entry in ipairs(buildLayout()) do
		local kind, x, z, y, yaw = entry[1], entry[2], entry[3], entry[4] or 0, entry[5] or 0
		local cfg = Config.Machines[kind]
		counter[kind] = (counter[kind] or 0) + 1
		local id = kind .. "_" .. counter[kind]

		local pivot = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
		local model, rootCF, exitCF = MachineModels.build(kind, pivot)
		model.Name = id
		model:SetAttribute("Kind", kind)
		model.Parent = stationsFolder

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TrainPrompt"
		if cfg.type == "cardio" then
			prompt.ActionText = "Начать"
		elseif cfg.type == "pose" then
			prompt.ActionText = "Выйти на подиум"
		else
			prompt.ActionText = "Тренироваться"
		end
		prompt.ObjectText = cfg.name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = model.PrimaryPart

		local station = {
			id = id,
			kind = kind,
			cfg = cfg,
			model = model,
			rootCF = rootCF,
			exitCF = exitCF,
			prompt = prompt,
			occupant = nil,
		}

		if cfg.type == "pose" then
			local anchor = model:FindFirstChild("ApplaudAnchor")
			local applaud = Instance.new("ProximityPrompt")
			applaud.Name = "ApplaudPrompt"
			applaud.ActionText = "Аплодировать 👏"
			applaud.ObjectText = "Подиум"
			applaud.KeyboardKeyCode = Enum.KeyCode.F
			applaud.HoldDuration = 0
			applaud.MaxActivationDistance = 60
			applaud.RequiresLineOfSight = false
			applaud.Enabled = false
			applaud.Parent = anchor
			station.applaudPrompt = applaud
			station.light = model:FindFirstChild("Spot") and model.Spot:FindFirstChild("Light")
			station.ring = model:FindFirstChild("Ring")
		end

		table.insert(stations, station)
	end

	-- Where NPCs go (used by Npcs.lua)
	local npcLayout = {
		admin = { pos = Vector3.new(0, 3.2, 21), facing = Vector3.new(0, 0, 1) },
		coachArea = { min = Vector2.new(90, -110), max = Vector2.new(270, 110) },
		posers = {
			{ name = "Рекс", sila = 120000, pos = Vector3.new(-264, 6.2, -30), facing = Vector3.new(1, 0, 0.3) },
			{ name = "Бетон", sila = 450000, pos = Vector3.new(-264, 6.2, 30), facing = Vector3.new(1, 0, -0.3) },
			{ name = "Молния", sila = 1300000, pos = Vector3.new(-248, 6.2, -42), facing = Vector3.new(1, 0, 0.2) },
			{ name = "Гриф", sila = 5200000, pos = Vector3.new(-248, 6.2, 42), facing = Vector3.new(1, 0, -0.2) },
		},
		spectators = {},
	}
	for _, x in ipairs({ -205, -170, -135, -100 }) do
		table.insert(npcLayout.spectators, { pos = Vector3.new(x, 3.2, -17), facing = Vector3.new(0, 0, 1) })
		table.insert(npcLayout.spectators, { pos = Vector3.new(x + 8, 3.2, 17), facing = Vector3.new(0, 0, -1) })
	end

	return {
		stations = stations,
		stageScreen = stageScreen,
		topBoard = topBoard,
		npcLayout = npcLayout,
	}
end

return World
