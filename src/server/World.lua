-- Builds the club in code: a premium dark gym with neutral white light and
-- purple neon used only as an accent (see docs/gdd.md, section 10).
--
-- Top view (the player spawns facing -Z):
--
--      PODIUM HALL        |   LOBBY    |        GYM HALL
--   x -280 ... -60        | -60 ... 60 |     60 ... 240
--   stage, star, carpet   | reception  |  plan from the gym spec (×3)
--                         |   spawn    |
--
-- The gym follows the 30 × 20 m plan from the spec, enlarged ×3
-- (1 m = 3 studs, ×3 = 9 studs per meter). Plan X (left→right when you
-- walk in) maps to world +Z, plan Z (entrance → far wall) maps to world +X.

local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS.Shared.Config)
local MachineModels = require(script.Parent.MachineModels)

local World = {}

---------------------------------------------------------------------------
-- Configuration: palette, sizes and the gym plan in one place
---------------------------------------------------------------------------
local C = {
	floor = Color3.fromRGB(46, 45, 52), -- matte graphite tile
	tileLine = Color3.fromRGB(34, 33, 40),
	wall = Color3.fromRGB(23, 21, 33), -- #171521
	ceiling = Color3.fromRGB(20, 19, 26),
	beam = Color3.fromRGB(34, 34, 40),
	duct = Color3.fromRGB(70, 70, 78),
	column = Color3.fromRGB(44, 43, 50),
	darkPurple = Color3.fromRGB(40, 16, 68), -- #281044
	purple = Color3.fromRGB(139, 32, 255), -- #8B20FF
	cyan = Color3.fromRGB(53, 217, 255), -- #35D9FF
	white = Color3.fromRGB(245, 245, 250),
	lamp = Color3.fromRGB(255, 244, 229), -- ~4500 K
	mirror = Color3.fromRGB(200, 205, 215),
	poster = Color3.fromRGB(20, 18, 28),
	gold = Color3.fromRGB(255, 200, 60),
	red = Color3.fromRGB(170, 20, 45),
}

local HEIGHT = 40
local MIN_X, MAX_X = -280, 240
local MIN_Z, MAX_Z = -135, 135
local CENTER_X = (MIN_X + MAX_X) / 2
local WIDTH_X = MAX_X - MIN_X
local DEPTH_Z = MAX_Z - MIN_Z
local ARCH = 18 -- half width of the arches (36 studs = 4 m entrance ×9)

-- Gym plan from the spec, in meters
local PLAN = {
	scale = 9, -- studs per meter
	originX = 60, -- world X of the entrance wall
	originZ = MIN_Z, -- world Z of plan X = 0
	zones = {
		cardio = { 0.5, 14.5, 10.5, 19.5 },
		functional = { 11, 14.5, 20.5, 19.5 },
		strength = { 1, 4, 22.5, 14 },
		freeWeights = { 23, 3, 29.5, 17 },
		entry = { 10.5, 0.5, 19.5, 4.2 },
	},
	columns = { { 0.9, 5.5 }, { 0.9, 11.5 }, { 10.8, 5.5 }, { 10.8, 11.5 }, { 21.8, 5.5 }, { 21.8, 11.5 } },
}

-- Plan meters (planX, planZ) -> world X, Z
local function planToWorld(px, pz)
	return PLAN.originX + pz * PLAN.scale, PLAN.originZ + px * PLAN.scale
end

-- Facing helpers. Sign/poster text sits on the part's Back face (local +Z).
local FACE_PLUS_Z = CFrame.new()
local FACE_MINUS_Z = CFrame.Angles(0, math.pi, 0)
local FACE_MINUS_X = CFrame.Angles(0, -math.pi / 2, 0)
local FACE_PLUS_X = CFrame.Angles(0, math.pi / 2, 0)
local YAW_TO_PLUS_X = -math.pi / 2 -- machine users face +X (toward the far wall)

-- Bold italic like the reference sign; signs are English for everyone
local SIGN_FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)

---------------------------------------------------------------------------
-- Small builders
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

local function deco(parent, name, size, cf, color, material)
	local p = part(parent, name, size, cf, color, material)
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function surface(board, face, ppsd)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Back
	gui.PixelsPerStud = ppsd or 25
	gui.LightInfluence = 0
	gui.Parent = board
	return gui
end

local function textLabel(parent, text, pos, size, color)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextScaled = true
	l.RichText = true
	l.FontFace = SIGN_FONT
	l.TextColor3 = color or C.white
	l.Parent = parent
	return l
end

-- Wall sign: white bold italic text, purple underline slash (like the reference)
local function sign(parent, text, pos, facing, width, height)
	local board = deco(parent, "Sign", Vector3.new(width, height, 0.4), CFrame.new(pos) * facing, C.poster)
	local gui = surface(board)
	textLabel(gui, text, UDim2.fromScale(0.05, 0.08), UDim2.fromScale(0.9, 0.66))
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = C.purple
	bar.BorderSizePixel = 0
	bar.Position = UDim2.fromScale(0.3, 0.8)
	bar.Size = UDim2.fromScale(0.4, 0.07)
	bar.Parent = gui
	return board
end

-- Motivational poster: big lines of text, purple slash under them
local function poster(parent, lines, pos, facing)
	local board = deco(parent, "Poster", Vector3.new(14, 18, 0.4), CFrame.new(pos) * facing, C.poster)
	local gui = surface(board)
	local label = textLabel(gui, lines, UDim2.fromScale(0.1, 0.12), UDim2.fromScale(0.8, 0.5))
	label.TextXAlignment = Enum.TextXAlignment.Left
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = C.purple
	bar.BorderSizePixel = 0
	bar.Position = UDim2.fromScale(0.1, 0.66)
	bar.Size = UDim2.fromScale(0.5, 0.035)
	bar.Rotation = -6
	bar.Parent = gui
	-- thin white frame line at the top, like a lit panel
	deco(parent, "PosterLight", Vector3.new(14, 0.2, 0.5), CFrame.new(pos) * facing * CFrame.new(0, 9.1, 0), C.lamp, Enum.Material.Neon)
	return board
end

-- Board with a title and N text lines (leaderboard, stage screen)
local function screen(parent, name, size, cf, face, title, lineCount)
	local board = deco(parent, name, size, cf, Color3.fromRGB(12, 11, 18))
	local gui = surface(board, face, 25)

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

	local titleLabel = textLabel(frame, title, UDim2.new(), UDim2.fromScale(1, 0.2), C.white)
	titleLabel.LayoutOrder = 0
	local lines = {}
	for i = 1, lineCount do
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 0.74 / lineCount)
		l.BackgroundTransparency = 1
		l.TextScaled = true
		l.Font = Enum.Font.GothamBold
		l.TextColor3 = Color3.fromRGB(225, 225, 235)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = ""
		l.LayoutOrder = i
		l.Parent = frame
		lines[i] = l
	end
	-- purple accent line under the board
	local s = size
	deco(parent, name .. "Glow", Vector3.new(math.max(s.X, s.Z), 0.3, 0.6), cf * CFrame.new(0, -s.Y / 2 - 0.2, 0) * (s.X < s.Z and CFrame.Angles(0, math.pi / 2, 0) or CFrame.new()), C.purple, Enum.Material.Neon)
	return { board = board, lines = lines }
end

-- Square column with vertical purple LED strips and a ceiling contour
local function column(parent, x, z, whiteAccent)
	local size = 5.4
	part(parent, "Column", Vector3.new(size, HEIGHT, size), CFrame.new(x, HEIGHT / 2, z), C.column, Enum.Material.Concrete)
	local h = HEIGHT - 6
	for _, side in ipairs({ -1, 1 }) do
		deco(parent, "ColumnLED", Vector3.new(0.35, h, 0.2), CFrame.new(x + side * 1.6, h / 2 + 1, z + size / 2 + 0.05), C.purple, Enum.Material.Neon)
		deco(parent, "ColumnLED", Vector3.new(0.35, h, 0.2), CFrame.new(x + side * 1.6, h / 2 + 1, z - size / 2 - 0.05), C.purple, Enum.Material.Neon)
	end
	if whiteAccent then
		deco(parent, "ColumnWhite", Vector3.new(0.2, h, 0.6), CFrame.new(x + size / 2 + 0.05, h / 2 + 1, z), C.lamp, Enum.Material.Neon)
		deco(parent, "ColumnWhite", Vector3.new(0.2, h, 0.6), CFrame.new(x - size / 2 - 0.05, h / 2 + 1, z), C.lamp, Enum.Material.Neon)
	end
	-- Square purple contour on the ceiling around the column (like the reference)
	local r, y = 9, HEIGHT - 2.2
	deco(parent, "CeilingContour", Vector3.new(2 * r, 0.3, 0.3), CFrame.new(x, y, z - r), C.purple, Enum.Material.Neon)
	deco(parent, "CeilingContour", Vector3.new(2 * r, 0.3, 0.3), CFrame.new(x, y, z + r), C.purple, Enum.Material.Neon)
	deco(parent, "CeilingContour", Vector3.new(0.3, 0.3, 2 * r), CFrame.new(x - r, y, z), C.purple, Enum.Material.Neon)
	deco(parent, "CeilingContour", Vector3.new(0.3, 0.3, 2 * r), CFrame.new(x + r, y, z), C.purple, Enum.Material.Neon)
end

-- Floor zone: slightly lighter tiles with thin white light lines on the border
local function zone(parent, name, x0, z0, x1, z1, accent)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local w, d = x1 - x0, z1 - z0
	deco(parent, name, Vector3.new(w, 0.06, d), CFrame.new(cx, 0.03, cz), C.floor:Lerp(C.white, 0.04), Enum.Material.SmoothPlastic)
	local edge = accent or C.white
	local t = 0.35
	for _, e in ipairs({
		{ Vector3.new(w, 0.08, t), CFrame.new(cx, 0.05, z0) },
		{ Vector3.new(w, 0.08, t), CFrame.new(cx, 0.05, z1) },
		{ Vector3.new(t, 0.08, d), CFrame.new(x0, 0.05, cz) },
		{ Vector3.new(t, 0.08, d), CFrame.new(x1, 0.05, cz) },
	}) do
		local line = deco(parent, name .. "Line", e[1], e[2], edge, Enum.Material.Neon)
		line.Transparency = 0.35
	end
end

local function planZone(parent, name, key, accent)
	local r = PLAN.zones[key]
	local xa, za = planToWorld(r[1], r[2])
	local xb, zb = planToWorld(r[3], r[4])
	zone(parent, name, math.min(xa, xb), math.min(za, zb), math.max(xa, xb), math.max(za, zb), accent)
	return (xa + xb) / 2, (za + zb) / 2
end

local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(118, 118, 126)
	Lighting.OutdoorAmbient = Color3.fromRGB(105, 105, 115)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.6
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.25
	bloom.Size = 18
	bloom.Threshold = 2.4
	bloom.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Contrast = 0.08
	cc.Saturation = -0.05
	cc.Parent = Lighting
end

---------------------------------------------------------------------------
-- Shell: floor tiles, walls, arches, industrial ceiling, white light
---------------------------------------------------------------------------
local function buildShell(hall)
	part(hall, "Floor", Vector3.new(WIDTH_X, 1, DEPTH_Z), CFrame.new(CENTER_X, -0.5, 0), C.floor, Enum.Material.SmoothPlastic).Reflectance = 0.04
	-- Large tiles: 1 m × 1 m in plan scale = 9 studs
	for x = MIN_X + 9, MAX_X - 1, 9 do
		deco(hall, "TileLine", Vector3.new(0.15, 0.02, DEPTH_Z), CFrame.new(x, 0.01, 0), C.tileLine)
	end
	for z = MIN_Z + 9, MAX_Z - 1, 9 do
		deco(hall, "TileLine", Vector3.new(WIDTH_X, 0.02, 0.15), CFrame.new(CENTER_X, 0.01, z), C.tileLine)
	end

	-- Outer walls
	part(hall, "WallNear", Vector3.new(WIDTH_X, HEIGHT, 1), CFrame.new(CENTER_X, HEIGHT / 2, MAX_Z + 0.5), C.wall)
	part(hall, "WallFar", Vector3.new(WIDTH_X, HEIGHT, 1), CFrame.new(CENTER_X, HEIGHT / 2, MIN_Z - 0.5), C.wall)
	part(hall, "WallLeft", Vector3.new(1, HEIGHT, DEPTH_Z), CFrame.new(MIN_X - 0.5, HEIGHT / 2, 0), C.wall)
	part(hall, "WallRight", Vector3.new(1, HEIGHT, DEPTH_Z), CFrame.new(MAX_X + 0.5, HEIGHT / 2, 0), C.wall)

	-- Dividers between the lobby and the two halls, with wide arches
	local side = (DEPTH_Z / 2 - ARCH)
	for _, x in ipairs({ -60, 60 }) do
		part(hall, "Divider", Vector3.new(1, HEIGHT, side), CFrame.new(x, HEIGHT / 2, MIN_Z + side / 2), C.wall)
		part(hall, "Divider", Vector3.new(1, HEIGHT, side), CFrame.new(x, HEIGHT / 2, MAX_Z - side / 2), C.wall)
		part(hall, "Lintel", Vector3.new(1, HEIGHT - 24, 2 * ARCH), CFrame.new(x, 24 + (HEIGHT - 24) / 2, 0), C.wall)
		-- Arch outline: white inner line, purple outer line
		deco(hall, "ArchWhite", Vector3.new(1.3, 0.35, 2 * ARCH), CFrame.new(x, 23.8, 0), C.lamp, Enum.Material.Neon)
		deco(hall, "ArchPurple", Vector3.new(1.3, 0.35, 2 * ARCH + 2), CFrame.new(x, 25, 0), C.purple, Enum.Material.Neon)
		for _, z in ipairs({ -ARCH, ARCH }) do
			deco(hall, "ArchWhite", Vector3.new(1.3, 24, 0.35), CFrame.new(x, 12, z), C.lamp, Enum.Material.Neon)
		end
	end
	sign(hall, "GYM  →", Vector3.new(59.3, 30, 0), FACE_MINUS_X, 34, 8)
	sign(hall, "←  PODIUM", Vector3.new(-59.3, 30, 0), FACE_PLUS_X, 34, 8)

	-- Industrial ceiling: slab, beams, ducts, cable trays
	part(hall, "Ceiling", Vector3.new(WIDTH_X, 1, DEPTH_Z), CFrame.new(CENTER_X, HEIGHT + 0.5, 0), C.ceiling)
	for x = MIN_X + 13.5, MAX_X - 1, 27 do
		deco(hall, "Beam", Vector3.new(2, 2.6, DEPTH_Z), CFrame.new(x, HEIGHT - 1.3, 0), C.beam, Enum.Material.Metal)
	end
	for _, z in ipairs({ -78, 78 }) do
		local duct = deco(hall, "Duct", Vector3.new(WIDTH_X, 3.4, 3.4), CFrame.new(CENTER_X, HEIGHT - 4.5, z), C.duct, Enum.Material.Metal)
		duct.Shape = Enum.PartType.Cylinder
	end
	for _, z in ipairs({ -112, 112 }) do
		deco(hall, "CableTray", Vector3.new(WIDTH_X, 0.35, 1.8), CFrame.new(CENTER_X, HEIGHT - 3, z), Color3.fromRGB(52, 52, 58), Enum.Material.DiamondPlate)
	end

	-- Main light: white linear fixtures between the beams; every other one casts light
	local n = 0
	for x = MIN_X + 27, MAX_X - 1, 27 do
		for _, z in ipairs({ -108, -72, -36, 0, 36, 72, 108 }) do
			n += 1
			local lamp = deco(hall, "LinearLight", Vector3.new(1, 0.35, 22), CFrame.new(x, HEIGHT - 3.2, z), C.lamp, Enum.Material.Neon)
			if n % 2 == 0 then
				local light = Instance.new("PointLight")
				light.Color = C.lamp
				light.Range = 38
				light.Brightness = 1.15
				light.Shadows = false
				light.Parent = lamp
			end
		end
	end
end

---------------------------------------------------------------------------
-- Lobby (spawn, reception, leaderboard)
---------------------------------------------------------------------------
local function buildLobby(hall)
	-- Reception desk: graphite body, white top, purple underglow
	part(hall, "ReceptionDesk", Vector3.new(20, 3.8, 3.4), CFrame.new(0, 1.9, 25), Color3.fromRGB(30, 29, 36))
	deco(hall, "ReceptionTop", Vector3.new(20.6, 0.3, 3.8), CFrame.new(0, 3.95, 25), C.white)
	deco(hall, "ReceptionGlow", Vector3.new(19.6, 0.25, 0.3), CFrame.new(0, 0.4, 26.8), C.purple, Enum.Material.Neon)

	-- NEON GYM sign above reception: purple NEON, white GYM
	local board = deco(hall, "LobbySign", Vector3.new(44, 9, 0.4), CFrame.new(0, 31, 14), C.poster)
	local gui = surface(board)
	textLabel(gui, '<font color="#8B20FF">NEON</font> GYM', UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.8))

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

	-- Light lines from the spawn toward both arches
	for _, x in ipairs({ -30, 30 }) do
		local line = deco(hall, "PathLine", Vector3.new(58, 0.08, 0.5), CFrame.new(x, 0.06, 0), C.lamp, Enum.Material.Neon)
		line.Transparency = 0.3
	end

	for _, x in ipairs({ -38, 38 }) do
		column(hall, x, -95, x > 0)
		column(hall, x, 95, x < 0)
	end
	poster(hall, "TRAIN\nHARDER", Vector3.new(-45, 14, MIN_Z + 0.3), FACE_PLUS_Z)
	poster(hall, "NO\nEXCUSES", Vector3.new(45, 14, MIN_Z + 0.3), FACE_PLUS_Z)

	return screen(hall, "TopBoard", Vector3.new(60, 26, 1), CFrame.new(0, 16, MIN_Z + 1.5), Enum.NormalId.Back, "TOP BY STRENGTH", 10)
end

---------------------------------------------------------------------------
-- Gym hall (plan from the spec)
---------------------------------------------------------------------------
local function buildGym(hall)
	local cx, cz = planZone(hall, "CardioZone", "cardio", C.purple)
	local fx, fz = planZone(hall, "FunctionalZone", "functional")
	local sx, sz = planZone(hall, "StrengthZone", "strength")
	local wx, wz = planZone(hall, "FreeWeightsZone", "freeWeights")
	planZone(hall, "EntryZone", "entry")

	-- Zone labels hang facing the entrance
	sign(hall, "CARDIO", Vector3.new(cx - 18, 24, cz), FACE_MINUS_X, 24, 5)
	sign(hall, "FUNCTIONAL", Vector3.new(fx - 18, 24, fz), FACE_MINUS_X, 28, 5)
	sign(hall, "STRENGTH", Vector3.new(sx - 40, 24, sz), FACE_MINUS_X, 26, 5)
	sign(hall, "FREE WEIGHTS", Vector3.new(wx - 40, 24, wz), FACE_MINUS_X, 30, 5)

	-- Columns from the plan; every other one gets a white accent
	for i, c in ipairs(PLAN.columns) do
		local x, z = planToWorld(c[1], c[2])
		column(hall, x, z, i % 2 == 0)
	end

	-- Mirrors on the far wall and the right wall
	local function mirrorRow(fromA, toA, step, makeCF)
		for a = fromA, toA, step do
			local m = part(hall, "Mirror", Vector3.new(step - 2, 12, 0.3), makeCF(a), C.mirror, Enum.Material.Glass)
			m.Reflectance = 0.55
			m.CanCollide = false
		end
	end
	mirrorRow(MIN_Z + 12, MAX_Z - 12, 20, function(z)
		return CFrame.new(MAX_X - 0.2, 7, z) * FACE_MINUS_X
	end)
	mirrorRow(72, MAX_X - 12, 20, function(x)
		return CFrame.new(x, 7, MAX_Z - 0.2) * FACE_MINUS_Z
	end)

	-- Big NEON GYM sign over the far central wall
	local board = deco(hall, "GymSign", Vector3.new(70, 14, 0.4), CFrame.new(MAX_X - 0.4, 27, 0) * FACE_MINUS_X, C.poster)
	local gui = surface(board)
	textLabel(gui, '<font color="#8B20FF">NEON</font> GYM', UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.8))
	deco(hall, "GymSignGlow", Vector3.new(0.6, 0.35, 66), CFrame.new(MAX_X - 0.8, 19.6, 0), C.purple, Enum.Material.Neon)

	-- Posters
	poster(hall, "TRAIN\nHARDER", Vector3.new(110, 16, MIN_Z + 0.3), FACE_PLUS_Z)
	poster(hall, "NO\nEXCUSES", Vector3.new(160, 16, MIN_Z + 0.3), FACE_PLUS_Z)
	poster(hall, "NO\nLIMITS", Vector3.new(MAX_X - 0.3, 22, -95), FACE_MINUS_X)
	poster(hall, "STRONGER\nEVERY DAY", Vector3.new(MAX_X - 0.3, 22, 95), FACE_MINUS_X)

	-- Entry plaza logo on the floor
	local ex, ez = planToWorld(15, 2.3)
	local logo = deco(hall, "FloorLogo", Vector3.new(16, 0.05, 30), CFrame.new(ex, 0.07, ez), C.floor)
	local floorGui = surface(logo, Enum.NormalId.Top, 12)
	local l = textLabel(floorGui, '<font color="#8B20FF">NEON</font> GYM', UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
	l.Rotation = 0
	l.TextTransparency = 0.35
end

---------------------------------------------------------------------------
-- Podium hall
---------------------------------------------------------------------------
local function buildPodium(hall)
	-- Backdrop with a giant star
	local backdrop = part(hall, "Backdrop", Vector3.new(1, 34, 100), CFrame.new(MIN_X + 2, 17, 0), Color3.fromRGB(16, 14, 24))
	local gui = surface(backdrop, Enum.NormalId.Right, 15)
	local star = textLabel(gui, "★", UDim2.fromScale(0.25, 0.02), UDim2.fromScale(0.5, 0.74), C.gold)
	star.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Black)
	textLabel(gui, '<font color="#8B20FF">NEON</font> STAGE', UDim2.fromScale(0.05, 0.76), UDim2.fromScale(0.9, 0.18))
	for _, z in ipairs({ -50, 50 }) do
		deco(hall, "BackdropLED", Vector3.new(1.4, 34, 0.5), CFrame.new(MIN_X + 2.5, 17, z), C.purple, Enum.Material.Neon)
	end

	-- Stage: black glass with a gold front edge
	part(hall, "Stage", Vector3.new(40, 3, 100), CFrame.new(-257, 1.5, 0), Color3.fromRGB(18, 17, 24), Enum.Material.Glass)
	deco(hall, "StageEdge", Vector3.new(0.5, 0.3, 100), CFrame.new(-237, 3, 0), C.gold, Enum.Material.Neon)
	part(hall, "Steps", Vector3.new(6, 1.5, 36), CFrame.new(-234, 0.75, 0), Color3.fromRGB(30, 29, 36))
	deco(hall, "StepsEdge", Vector3.new(0.4, 0.2, 36), CFrame.new(-231, 1.5, 0), C.lamp, Enum.Material.Neon)

	-- Stage show lights (purple accent + warm white)
	for _, z in ipairs({ -30, 30 }) do
		local holder = deco(hall, "StageLight", Vector3.new(1, 1, 1), CFrame.new(-250, HEIGHT - 6, z), C.beam, Enum.Material.Metal)
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Angle = 70
		spot.Range = 40
		spot.Brightness = 3
		spot.Color = z < 0 and C.purple or C.lamp
		spot.Parent = holder
	end

	-- Red carpet with golden stars toward the lobby
	part(hall, "Carpet", Vector3.new(160, 0.2, 16), CFrame.new(-151, 0.1, 0), C.red, Enum.Material.Fabric)
	for x = -225, -77, 12 do
		for _, z in ipairs({ -5.5, 5.5 }) do
			deco(hall, "CarpetStar", Vector3.new(1.3, 0.24, 1.3), CFrame.new(x, 0.21, z) * CFrame.Angles(0, math.rad(45), 0), C.gold, Enum.Material.Neon)
		end
	end

	-- Velvet rope barriers with gold posts
	for _, z in ipairs({ -12, 12 }) do
		for x = -226, -78, 16 do
			part(hall, "RopePost", Vector3.new(0.6, 3, 0.6), CFrame.new(x, 1.5, z), C.gold, Enum.Material.Metal)
		end
		deco(hall, "Rope", Vector3.new(148, 0.35, 0.35), CFrame.new(-152, 2.6, z), Color3.fromRGB(70, 20, 110), Enum.Material.Fabric)
	end

	for _, x in ipairs({ -110, -200 }) do
		column(hall, x, -95, x == -110)
		column(hall, x, 95, x == -200)
	end
	poster(hall, "SHOW\nYOUR GAINS", Vector3.new(-150, 16, MIN_Z + 0.3), FACE_PLUS_Z)
	poster(hall, "BUILT\nDIFFERENT", Vector3.new(-150, 16, MAX_Z - 0.3), FACE_MINUS_Z)

	return screen(hall, "StageScreen", Vector3.new(1, 14, 44), CFrame.new(-200, 30, 0), Enum.NormalId.Right, "ON STAGE NOW", 3)
end

---------------------------------------------------------------------------
-- Stations: { kind, x, z, y?, yaw? }. Weaker machines sit closer to the entrance.
---------------------------------------------------------------------------
local function buildLayout()
	local L = {}
	local function add(kind, x, z, y, yaw)
		table.insert(L, { kind, x, z, y or 0, yaw or 0 })
	end

	-- Cardio (far left): two rows of 8 treadmills facing the far wall
	for _, x in ipairs({ 200, 222 }) do
		for i = 0, 7 do
			add("treadmill", x, -124 + i * 11, 0, YAW_TO_PLUS_X)
		end
	end
	-- Functional zone (far middle): rowing machines and the two Titan rigs
	for i = 0, 5 do
		add("rower", 200, -30 + i * 10, 0, YAW_TO_PLUS_X)
	end
	add("titan", 224, -18, 0, YAW_TO_PLUS_X)
	add("titan", 224, 18, 0, YAW_TO_PLUS_X)
	-- Strength zone: 4 rows of 8, stronger rows deeper in the hall
	local rows = { { "abs", 110 }, { "legpress", 132 }, { "pulldown", 154 }, { "cable", 176 } }
	for _, r in ipairs(rows) do
		for i = 0, 7 do
			add(r[1], r[2], -116 + i * 22)
		end
	end
	-- Free weights along the right side: dumbbells, benches, squat racks
	local free = { { "dumbbells", 82 }, { "bench", 100 }, { "squat", 120 } }
	for _, r in ipairs(free) do
		for i = 0, 7 do
			add(r[1], 96 + i * 16, r[2])
		end
	end
	-- Podium: three posing spots on the stage, facing the audience (+X)
	for _, z in ipairs({ -14, 0, 14 }) do
		add("pose", -252, z, 3, YAW_TO_PLUS_X)
	end
	return L
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

	buildShell(hall)
	local topBoard = buildLobby(hall)
	buildGym(hall)
	local stageScreen = buildPodium(hall)

	local stationsFolder = Instance.new("Folder")
	stationsFolder.Name = "Stations"
	stationsFolder.Parent = gym

	local stations = {}
	local counter = {}
	for _, entry in ipairs(buildLayout()) do
		local kind, x, z, y, yaw = entry[1], entry[2], entry[3], entry[4], entry[5]
		local cfg = Config.Machines[kind]
		counter[kind] = (counter[kind] or 0) + 1
		local id = kind .. "_" .. counter[kind]

		local pivot = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
		local model, rootCF, exitCF = MachineModels.build(kind, pivot)
		model.Name = id
		model:SetAttribute("Kind", kind)
		-- Gameplay hooks from the spec
		model:SetAttribute("MachineType", kind)
		model:SetAttribute("StrengthPerClick", cfg.mult or 0)
		model:SetAttribute("RequiredStrength", cfg.unlock or 0)
		model.Parent = stationsFolder

		-- Prompt texts are English defaults; clients replace them with their language
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TrainPrompt"
		prompt.ActionText = cfg.type == "cardio" and "Start" or (cfg.type == "pose" and "Step on stage" or "Train")
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
			local applaud = Instance.new("ProximityPrompt")
			applaud.Name = "ApplaudPrompt"
			applaud.ActionText = "Applaud 👏"
			applaud.ObjectText = "Podium"
			applaud.KeyboardKeyCode = Enum.KeyCode.F
			applaud.HoldDuration = 0
			applaud.MaxActivationDistance = 60
			applaud.RequiresLineOfSight = false
			applaud.Enabled = false
			applaud.Parent = model:FindFirstChild("ApplaudAnchor")
			station.applaudPrompt = applaud
			station.light = model:FindFirstChild("Spot") and model.Spot:FindFirstChild("Light")
			station.ring = model:FindFirstChild("Ring")
		end

		table.insert(stations, station)
	end

	-- Where NPCs go (used by Npcs.lua). Names are proper nouns, same in every language.
	local npcLayout = {
		admin = { pos = Vector3.new(0, 3.2, 21), facing = Vector3.new(0, 0, 1) },
		coachArea = { min = Vector2.new(100, -110), max = Vector2.new(185, 60) },
		posers = {
			{ name = "Rex", sila = 120000, pos = Vector3.new(-264, 6.2, -30), facing = Vector3.new(1, 0, 0.3) },
			{ name = "Brick", sila = 450000, pos = Vector3.new(-264, 6.2, 30), facing = Vector3.new(1, 0, -0.3) },
			{ name = "Bolt", sila = 1300000, pos = Vector3.new(-248, 6.2, -42), facing = Vector3.new(1, 0, 0.2) },
			{ name = "Griff", sila = 5200000, pos = Vector3.new(-248, 6.2, 42), facing = Vector3.new(1, 0, -0.2) },
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
