-- Builds the neon club in code: hall, zones, reception (spawn), glass wall,
-- podium and all training stations.

local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS.Shared.Config)
local MachineModels = require(script.Parent.MachineModels)

local World = {}

local FLOOR = Color3.fromRGB(28, 18, 48)
local WALL = Color3.fromRGB(22, 14, 40)
local CARDIO = Color3.fromRGB(60, 190, 255)
local STRENGTH = Color3.fromRGB(170, 90, 255)
local PODIUM = Color3.fromRGB(255, 80, 200)

-- Station layout: { kind, x, z }. The user of each station faces -Z (toward the podium).
local LAYOUT = {
	-- Cardio zone (blue)
	{ "treadmill", -92, -8 },
	{ "treadmill", -84, -8 },
	{ "treadmill", -76, -8 },
	{ "treadmill", -68, -8 },
	{ "rower", -90, 18 },
	{ "rower", -80, 18 },
	{ "rower", -70, 18 },
	-- Strength zone (purple): one column per machine, two rows
	{ "dumbbells", -42, -10 },
	{ "dumbbells", -42, 14 },
	{ "bench", -28, -10 },
	{ "bench", -28, 14 },
	{ "abs", -14, -10 },
	{ "abs", -14, 14 },
	{ "legpress", 0, -10 },
	{ "legpress", 0, 14 },
	{ "pulldown", 14, -10 },
	{ "pulldown", 14, 14 },
	{ "squat", 28, -10 },
	{ "squat", 28, 14 },
	{ "cable", 44, -10 },
	{ "cable", 44, 14 },
	-- Titan arena (pink)
	{ "titan", 80, 0 },
}

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

local function sign(parent, text, cf, color, width)
	local board = part(parent, "Sign", Vector3.new(width or 24, 5, 0.4), cf, Color3.fromRGB(15, 10, 25))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.Parent = gui
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

local function setupLighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(95, 70, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 60, 120)
	Lighting.EnvironmentDiffuseScale = 0.4
	Lighting.EnvironmentSpecularScale = 0.6
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.6
		bloom.Size = 30
		bloom.Threshold = 1.6
		bloom.Parent = Lighting
	end
end

-- Returns a list of stations: { id, kind, cfg, model, rootCF, exitCF, prompt }
function World.build()
	setupLighting()

	local gym = Instance.new("Folder")
	gym.Name = "Gym"
	gym.Parent = workspace

	local hall = Instance.new("Folder")
	hall.Name = "Hall"
	hall.Parent = gym

	-- Shell: hall from z = -60 (glass wall) to z = 100 (reception), x from -110 to 110
	part(hall, "Floor", Vector3.new(220, 1, 240), CFrame.new(0, -0.5, 10), FLOOR, Enum.Material.Glass)
	part(hall, "WallBack", Vector3.new(220, 32, 2), CFrame.new(0, 16, 101), WALL)
	part(hall, "WallLeft", Vector3.new(2, 32, 240), CFrame.new(-111, 16, 10), WALL)
	part(hall, "WallRight", Vector3.new(2, 32, 240), CFrame.new(111, 16, 10), WALL)
	part(hall, "WallFar", Vector3.new(220, 32, 2), CFrame.new(0, 16, -111), WALL)
	part(hall, "Roof", Vector3.new(220, 1, 240), CFrame.new(0, 32.5, 10), WALL)

	-- Ceiling light strips with real lights
	for _, x in ipairs({ -80, -40, 0, 40, 80 }) do
		local strip = part(hall, "LightStrip", Vector3.new(2, 0.4, 150), CFrame.new(x, 31.8, 10), x < -50 and CARDIO or STRENGTH, Enum.Material.Neon)
		for _, z in ipairs({ -30, 10, 50 }) do
			local holder = part(hall, "LightPoint", Vector3.new(0.5, 0.5, 0.5), CFrame.new(x, 31, z), strip.Color, Enum.Material.Neon)
			holder.Transparency = 1
			holder.CanCollide = false
			local light = Instance.new("PointLight")
			light.Range = 45
			light.Brightness = 1.2
			light.Color = strip.Color:Lerp(Color3.new(1, 1, 1), 0.5)
			light.Parent = holder
		end
	end

	-- Zones
	zone(hall, "CardioZone", Vector2.new(-80, 5), Vector2.new(46, 56), CARDIO)
	zone(hall, "StrengthZone", Vector2.new(1, 2), Vector2.new(104, 56), STRENGTH)
	zone(hall, "TitanZone", Vector2.new(80, 0), Vector2.new(20, 20), PODIUM)
	sign(hall, "КАРДИО", CFrame.new(-80, 14, 33), CARDIO, 26)
	sign(hall, "СИЛОВАЯ ЗОНА", CFrame.new(1, 14, 33), STRENGTH, 34)
	sign(hall, "ТИТАН", CFrame.new(80, 14, 13), PODIUM, 18)

	-- Glass wall and podium behind it (podium gameplay comes later)
	local glass = part(hall, "GlassWall", Vector3.new(220, 30, 1), CFrame.new(0, 15, -60), Color3.fromRGB(180, 160, 255), Enum.Material.Glass)
	glass.Transparency = 0.7
	part(hall, "GlassFrame", Vector3.new(220, 0.6, 1.2), CFrame.new(0, 0.3, -60), PODIUM, Enum.Material.Neon)
	part(hall, "Runway", Vector3.new(14, 1.5, 40), CFrame.new(0, 0.75, -85), Color3.fromRGB(40, 20, 50))
	part(hall, "RunwayGlowL", Vector3.new(0.5, 1.6, 40), CFrame.new(-7, 0.8, -85), PODIUM, Enum.Material.Neon)
	part(hall, "RunwayGlowR", Vector3.new(0.5, 1.6, 40), CFrame.new(7, 0.8, -85), PODIUM, Enum.Material.Neon)
	sign(hall, "ПОДИУМ · скоро", CFrame.new(0, 10, -105), PODIUM, 30)

	-- Reception (spawn point, GDD: player starts inside the club at the desk)
	part(hall, "ReceptionDesk", Vector3.new(18, 4, 3), CFrame.new(0, 2, 88), Color3.fromRGB(50, 30, 80), Enum.Material.Glass)
	part(hall, "ReceptionGlow", Vector3.new(18.2, 0.4, 3.2), CFrame.new(0, 4.1, 88), PODIUM, Enum.Material.Neon)
	sign(hall, "NEON GYM", CFrame.new(0, 14, 99.5) * CFrame.Angles(0, math.pi, 0), PODIUM, 36)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, 78) -- front (-Z) faces into the hall
	spawn.Neutral = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = hall

	-- Stations
	local stationsFolder = Instance.new("Folder")
	stationsFolder.Name = "Stations"
	stationsFolder.Parent = gym

	local stations = {}
	local counter = {}
	for _, entry in ipairs(LAYOUT) do
		local kind, x, z = entry[1], entry[2], entry[3]
		local cfg = Config.Machines[kind]
		counter[kind] = (counter[kind] or 0) + 1
		local id = kind .. "_" .. counter[kind]

		local model, rootCF, exitCF = MachineModels.build(kind, CFrame.new(x, 0, z))
		model.Name = id
		model:SetAttribute("Kind", kind)
		model.Parent = stationsFolder

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TrainPrompt"
		prompt.ActionText = cfg.type == "cardio" and "Начать" or "Тренироваться"
		prompt.ObjectText = cfg.name
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = model.PrimaryPart

		table.insert(stations, {
			id = id,
			kind = kind,
			cfg = cfg,
			model = model,
			rootCF = rootCF,
			exitCF = exitCF,
			prompt = prompt,
			occupant = nil,
		})
	end

	return stations
end

return World
