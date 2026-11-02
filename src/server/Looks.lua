-- Unique looks for NPCs, built from plain parts (no catalog assets needed).
--
-- A look is a table:
--   skin, top, bottom, shoes      Color3
--   sleeves = true                arms colored like the top (T-shirt / tracksuit)
--   shorts = true                 lower legs show skin
--   hair = "buzz" | "flattop" | "mohawk" | "ponytail" | "bun" | "afro" | "spiky" | nil (bald)
--   hairColor                     Color3
--   hat = "cap" | "headband" | "headset" | nil, hatColor
--   glasses, beard, mustache, chain, whistle, belt   true/false (glasses may be a Color3)
--   bands                         Color3 for wristbands
-- Accessory parts are welded to body parts, so they follow the procedural poses.

local Looks = {}

local function weld(base, p)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
end

-- Adds a part to a body part. offset is relative to the body part's CFrame.
local function add(rig, baseName, size, offset, color, material, shape)
	local base = rig:FindFirstChild(baseName)
	if not base then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = "Look"
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = base.CFrame * offset
	p.Parent = rig
	weld(base, p)
	return p
end

local function sizeOf(rig, name)
	local p = rig:FindFirstChild(name)
	return p and p.Size or Vector3.new(1.2, 1.2, 1.2)
end

local function paint(rig, names, color)
	for _, name in ipairs(names) do
		local p = rig:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color = color
		end
	end
end

---------------------------------------------------------------------------
-- Clothes (body part colors)
---------------------------------------------------------------------------
local function dress(rig, look)
	-- Body Colors would overwrite our per-part colors
	local bodyColors = rig:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors:Destroy()
	end

	local skin = look.skin
	paint(rig, { "Head", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand" }, skin)
	paint(rig, { "UpperTorso" }, look.top)
	paint(rig, { "LeftUpperArm", "RightUpperArm" }, look.sleeves and look.top or skin)
	paint(rig, { "LowerTorso", "LeftUpperLeg", "RightUpperLeg" }, look.bottom)
	paint(rig, { "LeftLowerLeg", "RightLowerLeg" }, look.shorts and skin or look.bottom)
	paint(rig, { "LeftFoot", "RightFoot" }, look.shoes)
end

---------------------------------------------------------------------------
-- Hair
---------------------------------------------------------------------------
local HAIR = {}

HAIR.buzz = function(rig, h, c)
	add(rig, "Head", Vector3.new(h.X * 1.04, 0.14, h.Z * 1.04), CFrame.new(0, h.Y / 2 + 0.05, 0), c)
	add(rig, "Head", Vector3.new(h.X * 1.04, h.Y * 0.55, 0.12), CFrame.new(0, h.Y * 0.2, h.Z / 2 + 0.04), c)
end

HAIR.flattop = function(rig, h, c)
	add(rig, "Head", Vector3.new(h.X * 0.98, h.Y * 0.5, h.Z * 0.98), CFrame.new(0, h.Y / 2 + h.Y * 0.24, 0.04), c)
	add(rig, "Head", Vector3.new(h.X * 1.04, h.Y * 0.5, 0.12), CFrame.new(0, h.Y * 0.22, h.Z / 2 + 0.04), c)
end

HAIR.mohawk = function(rig, h, c)
	add(rig, "Head", Vector3.new(0.3, h.Y * 0.6, h.Z * 1.05), CFrame.new(0, h.Y / 2 + h.Y * 0.28, 0.05), c, Enum.Material.Neon)
end

HAIR.ponytail = function(rig, h, c)
	HAIR.buzz(rig, h, c)
	add(rig, "Head", Vector3.new(0.55, 0.55, 0.55), CFrame.new(0, h.Y * 0.25, h.Z / 2 + 0.3), c, nil, Enum.PartType.Ball)
	add(rig, "Head", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, -h.Y * 0.1, h.Z / 2 + 0.45), c, nil, Enum.PartType.Ball)
	add(rig, "Head", Vector3.new(0.35, 0.35, 0.35), CFrame.new(0, -h.Y * 0.4, h.Z / 2 + 0.5), c, nil, Enum.PartType.Ball)
end

HAIR.bun = function(rig, h, c)
	HAIR.buzz(rig, h, c)
	add(rig, "Head", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, h.Y / 2 + 0.2, h.Z * 0.15), c, nil, Enum.PartType.Ball)
end

HAIR.afro = function(rig, h, c)
	add(rig, "Head", Vector3.new(h.X * 1.3, h.X * 1.3, h.X * 1.3), CFrame.new(0, h.Y * 0.45, h.Z * 0.15), c, nil, Enum.PartType.Ball)
end

HAIR.spiky = function(rig, h, c)
	HAIR.buzz(rig, h, c)
	for i, x in ipairs({ -0.35, 0, 0.35 }) do
		local tilt = (i - 2) * 18
		add(rig, "Head", Vector3.new(0.25, h.Y * 0.45, 0.25), CFrame.new(x * h.X, h.Y / 2 + 0.2, 0) * CFrame.Angles(0, 0, math.rad(-tilt)), c)
	end
end

---------------------------------------------------------------------------
-- Headwear, face and accessories
---------------------------------------------------------------------------
local function hat(rig, h, kind, color)
	if kind == "cap" then
		add(rig, "Head", Vector3.new(h.X * 1.07, h.Y * 0.35, h.Z * 1.07), CFrame.new(0, h.Y / 2 + 0.08, 0), color)
		add(rig, "Head", Vector3.new(h.X * 0.9, 0.08, h.Z * 0.6), CFrame.new(0, h.Y / 2 - 0.05, -h.Z / 2 - 0.25), color)
	elseif kind == "headband" then
		add(rig, "Head", Vector3.new(h.X * 1.05, 0.2, h.Z * 1.05), CFrame.new(0, h.Y * 0.3, 0), color, Enum.Material.Neon)
	elseif kind == "headset" then
		add(rig, "Head", Vector3.new(h.X * 1.1, 0.1, 0.15), CFrame.new(0, h.Y / 2 + 0.06, 0), Color3.fromRGB(25, 25, 30))
		for _, side in ipairs({ -1, 1 }) do
			add(rig, "Head", Vector3.new(0.15, 0.45, 0.45), CFrame.new(side * (h.X / 2 + 0.07), 0, 0), Color3.fromRGB(25, 25, 30))
		end
		add(rig, "Head", Vector3.new(0.06, 0.06, 0.55), CFrame.new(h.X / 2, -h.Y * 0.2, -h.Z * 0.3) * CFrame.Angles(0, math.rad(30), 0), color, Enum.Material.Neon)
	end
end

local function face(rig, h, look)
	if look.glasses then
		local lens = typeof(look.glasses) == "Color3" and look.glasses or Color3.fromRGB(20, 20, 25)
		add(rig, "Head", Vector3.new(h.X * 0.92, 0.2, 0.06), CFrame.new(0, h.Y * 0.12, -h.Z / 2 - 0.03), lens, Enum.Material.Neon)
	end
	if look.beard then
		add(rig, "Head", Vector3.new(h.X * 0.88, h.Y * 0.32, 0.14), CFrame.new(0, -h.Y * 0.34, -h.Z / 2 + 0.02), look.hairColor)
	end
	if look.mustache then
		add(rig, "Head", Vector3.new(h.X * 0.5, 0.12, 0.08), CFrame.new(0, -h.Y * 0.12, -h.Z / 2 - 0.03), look.hairColor)
	end
end

local function extras(rig, look)
	local t = sizeOf(rig, "UpperTorso")
	if look.chain then
		for _, side in ipairs({ -1, 1 }) do
			add(rig, "UpperTorso", Vector3.new(0.12, t.Y * 0.45, 0.06), CFrame.new(side * 0.28, t.Y * 0.22, -t.Z / 2 - 0.04) * CFrame.Angles(0, 0, math.rad(side * 25)), Color3.fromRGB(255, 200, 60), Enum.Material.Foil)
		end
		add(rig, "UpperTorso", Vector3.new(0.35, 0.35, 0.08), CFrame.new(0, t.Y * 0.0, -t.Z / 2 - 0.06), Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
	end
	if look.whistle then
		for _, side in ipairs({ -1, 1 }) do
			add(rig, "UpperTorso", Vector3.new(0.06, t.Y * 0.4, 0.04), CFrame.new(side * 0.25, t.Y * 0.24, -t.Z / 2 - 0.03) * CFrame.Angles(0, 0, math.rad(side * 25)), Color3.fromRGB(20, 20, 20))
		end
		add(rig, "UpperTorso", Vector3.new(0.22, 0.16, 0.38), CFrame.new(0, t.Y * 0.04, -t.Z / 2 - 0.15), Color3.fromRGB(210, 210, 220), Enum.Material.Metal)
	end
	if look.belt then
		local l = sizeOf(rig, "LowerTorso")
		add(rig, "LowerTorso", Vector3.new(l.X * 1.08, l.Y * 0.6, l.Z * 1.12), CFrame.new(0, l.Y * 0.1, 0), Color3.fromRGB(90, 50, 25), Enum.Material.Fabric)
		add(rig, "LowerTorso", Vector3.new(0.45, 0.35, 0.08), CFrame.new(0, l.Y * 0.1, -l.Z * 0.56 - 0.03), Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
	end
	if look.bands then
		for _, name in ipairs({ "LeftLowerArm", "RightLowerArm" }) do
			local s = sizeOf(rig, name)
			add(rig, name, Vector3.new(s.X * 1.18, 0.28, s.Z * 1.18), CFrame.new(0, -s.Y * 0.32, 0), look.bands, Enum.Material.Neon)
		end
	end
end

---------------------------------------------------------------------------
function Looks.apply(rig, look)
	if not rig:FindFirstChild("UpperTorso") then
		return -- fallback block NPC, nothing to dress
	end
	dress(rig, look)
	local h = sizeOf(rig, "Head")
	if look.hair and HAIR[look.hair] then
		HAIR[look.hair](rig, h, look.hairColor or Color3.fromRGB(30, 20, 15))
	end
	if look.hat then
		hat(rig, h, look.hat, look.hatColor or Color3.fromRGB(255, 80, 200))
	end
	face(rig, h, look)
	extras(rig, look)
end

---------------------------------------------------------------------------
-- The cast. Every NPC gets its own look and build.
---------------------------------------------------------------------------
local C = Color3.fromRGB
local SKIN = { light = C(240, 200, 165), tan = C(215, 160, 115), medium = C(180, 120, 85), brown = C(130, 85, 60), dark = C(90, 58, 42) }

Looks.cast = {
	admin = {
		build = { width = 1.0, height = 1.0 },
		look = { skin = SKIN.light, top = C(255, 80, 200), bottom = C(45, 40, 60), shoes = C(245, 245, 250), hair = "ponytail", hairColor = C(110, 60, 30), hat = "headset", hatColor = C(255, 80, 200) },
	},
	coach = {
		build = { width = 1.25, height = 1.0 },
		look = { skin = SKIN.medium, top = C(40, 110, 230), sleeves = true, bottom = C(30, 70, 170), shoes = C(245, 245, 250), hair = "buzz", hairColor = C(25, 20, 18), hat = "cap", hatColor = C(230, 40, 60), whistle = true, mustache = true },
	},
	posers = {
		["Рекс"] = {
			build = { width = 1.7, height = 1.05 },
			look = { skin = SKIN.tan, top = C(25, 25, 30), bottom = C(220, 40, 60), shorts = true, shoes = C(20, 20, 25), hair = "mohawk", hairColor = C(80, 255, 140), glasses = C(255, 80, 200), bands = C(80, 255, 140) },
		},
		["Бетон"] = {
			build = { width = 1.9, height = 1.08 },
			look = { skin = SKIN.dark, top = C(120, 120, 130), bottom = C(30, 40, 90), shorts = true, shoes = C(230, 230, 235), beard = true, hairColor = C(20, 15, 12), chain = true },
		},
		["Молния"] = {
			build = { width = 1.6, height = 1.0 },
			look = { skin = SKIN.light, top = C(255, 215, 40), bottom = C(20, 20, 25), shorts = true, shoes = C(255, 215, 40), hair = "flattop", hairColor = C(250, 225, 120), hat = "headband", hatColor = C(60, 190, 255), bands = C(60, 190, 255) },
		},
		["Гриф"] = {
			build = { width = 1.8, height = 1.04 },
			look = { skin = SKIN.brown, top = C(150, 70, 230), bottom = C(15, 15, 20), shorts = true, shoes = C(150, 70, 230), hair = "bun", hairColor = C(15, 12, 10), beard = true, belt = true },
		},
	},
	spectators = {
		{ skin = SKIN.light, top = C(80, 230, 140), sleeves = true, bottom = C(40, 60, 120), shoes = C(240, 240, 240), hair = "spiky", hairColor = C(240, 160, 40) },
		{ skin = SKIN.brown, top = C(255, 120, 60), sleeves = true, bottom = C(30, 30, 35), shoes = C(255, 120, 60), hair = "afro", hairColor = C(25, 18, 14) },
		{ skin = SKIN.tan, top = C(60, 190, 255), bottom = C(220, 220, 230), shorts = true, shoes = C(40, 40, 50), hair = "ponytail", hairColor = C(30, 20, 15), hat = "cap", hatColor = C(60, 190, 255) },
		{ skin = SKIN.medium, top = C(240, 240, 245), sleeves = true, bottom = C(90, 60, 40), shoes = C(30, 30, 30), hair = "buzz", hairColor = C(40, 30, 25), glasses = true, mustache = true },
		{ skin = SKIN.dark, top = C(255, 200, 60), bottom = C(60, 40, 100), shoes = C(255, 255, 255), hair = "bun", hairColor = C(150, 60, 200), hat = "headband", hatColor = C(255, 80, 200) },
		{ skin = SKIN.light, top = C(200, 40, 60), sleeves = true, bottom = C(25, 25, 30), shoes = C(200, 40, 60), hair = "flattop", hairColor = C(120, 70, 30), beard = true },
		{ skin = SKIN.tan, top = C(150, 70, 230), bottom = C(50, 50, 60), shorts = true, shoes = C(80, 230, 140), hair = "mohawk", hairColor = C(255, 80, 200), bands = C(255, 80, 200) },
		{ skin = SKIN.medium, top = C(30, 30, 35), sleeves = true, bottom = C(30, 30, 35), shoes = C(255, 215, 40), hat = "cap", hatColor = C(255, 215, 40), glasses = C(60, 190, 255), chain = true },
	},
}

return Looks
