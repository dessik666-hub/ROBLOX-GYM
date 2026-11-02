-- Builds machine models out of parts.
-- Every station is built around a pivot on the floor; the user faces -Z.
--
-- Animated parts carry attributes the client reads:
--   Home  (CFrame)  rest pose in world space
--   Lift  (CFrame)  offset in the part's local space at the peak of a rep
--   BeltZ (number)  treadmill chevrons: start offset along the belt
--
-- build(kind, pivot) returns the model, the CFrame for the trainee's
-- HumanoidRootPart and the CFrame to place the player when they leave.

local MachineModels = {}

-- Equipment style: black matte metal, black pads, purple indicators, cyan displays
local METAL = Color3.fromRGB(30, 30, 36)
local PAD = Color3.fromRGB(26, 25, 31)
local NEON_PURPLE = Color3.fromRGB(139, 32, 255)
local NEON_BLUE = Color3.fromRGB(53, 217, 255) -- cyan displays
local NEON_PINK = NEON_PURPLE -- accents are purple only

local function part(model, pivot, name, size, rel, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = pivot * rel
	p.Color = color or METAL
	p.Material = material or Enum.Material.Metal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

local function setLift(p, lift)
	p:SetAttribute("Home", p.CFrame)
	p:SetAttribute("Lift", lift)
	p.CanCollide = false
	return p
end

-- Rubber floor mat with a subtle grey border (purple stays an accent, not a frame)
local function mat(model, pivot, w, d, _color)
	part(model, pivot, "Mat", Vector3.new(w, 0.2, d), CFrame.new(0, 0.1, 0), Color3.fromRGB(24, 24, 28), Enum.Material.Rubber)
	local c = Color3.fromRGB(72, 70, 82)
	part(model, pivot, "Edge", Vector3.new(w, 0.24, 0.15), CFrame.new(0, 0.12, -d / 2), c, Enum.Material.SmoothPlastic)
	part(model, pivot, "Edge", Vector3.new(w, 0.24, 0.15), CFrame.new(0, 0.12, d / 2), c, Enum.Material.SmoothPlastic)
	part(model, pivot, "Edge", Vector3.new(0.15, 0.24, d), CFrame.new(-w / 2, 0.12, 0), c, Enum.Material.SmoothPlastic)
	part(model, pivot, "Edge", Vector3.new(0.15, 0.24, d), CFrame.new(w / 2, 0.12, 0), c, Enum.Material.SmoothPlastic)
end

-- Barbell along X with two plates. All parts share the same Lift.
local function barbell(model, pivot, rel, length, lift, plateColor)
	local bar = part(model, pivot, "Bar", Vector3.new(length, 0.25, 0.25), rel, Color3.fromRGB(200, 200, 215), Enum.Material.Metal, Enum.PartType.Cylinder)
	setLift(bar, lift)
	for _, side in ipairs({ -1, 1 }) do
		local plate = part(model, pivot, "Plate", Vector3.new(0.4, 1.8, 1.8), rel * CFrame.new(side * (length / 2 - 0.7), 0, 0), plateColor or Color3.fromRGB(25, 25, 35), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		setLift(plate, lift)
		local rim = part(model, pivot, "PlateRim", Vector3.new(0.42, 1.2, 1.2), rel * CFrame.new(side * (length / 2 - 0.7), 0, 0), NEON_PINK, Enum.Material.Neon, Enum.PartType.Cylinder)
		setLift(rim, lift)
	end
end

local builders = {}

-- Rack with dumbbells; the player holds dumbbells added by the client.
builders.dumbbells = function(model, pivot)
	mat(model, pivot, 6, 6)
	part(model, pivot, "Rack", Vector3.new(5, 1.4, 1.2), CFrame.new(0, 0.9, 2.4), METAL)
	for i = -2, 2 do
		part(model, pivot, "Dumbbell", Vector3.new(0.9, 0.35, 0.35), CFrame.new(i * 0.95, 1.8, 2.4), Color3.fromRGB(30, 30, 40), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end
	return CFrame.new(0, 3.2, 0), CFrame.new(4, 3.2, 0)
end

-- Treadmill with scrolling neon chevrons on the belt
builders.treadmill = function(model, pivot)
	part(model, pivot, "Deck", Vector3.new(3.2, 0.6, 7), CFrame.new(0, 0.3, 0), METAL)
	part(model, pivot, "Belt", Vector3.new(2.6, 0.1, 6.6), CFrame.new(0, 0.65, 0), Color3.fromRGB(15, 15, 20), Enum.Material.SmoothPlastic)
	for i, z in ipairs({ -2, 0, 2 }) do
		local chevron = part(model, pivot, "Chevron" .. i, Vector3.new(1.8, 0.05, 0.3), CFrame.new(0, 0.72, z), NEON_PINK, Enum.Material.Neon)
		chevron.CanCollide = false
		chevron:SetAttribute("Home", chevron.CFrame)
		chevron:SetAttribute("BeltZ", z)
	end
	for _, x in ipairs({ -1.4, 1.4 }) do
		part(model, pivot, "Upright", Vector3.new(0.3, 3.6, 0.3), CFrame.new(x, 2.3, -3.2), METAL)
	end
	part(model, pivot, "Console", Vector3.new(3.2, 0.7, 0.9), CFrame.new(0, 4.1, -3.3), METAL)
	part(model, pivot, "Screen", Vector3.new(2.4, 0.5, 0.1), CFrame.new(0, 4.15, -2.83), NEON_BLUE, Enum.Material.Neon)
	return CFrame.new(0, 3.7, 0.5), CFrame.new(3.5, 3.2, 0)
end

-- Flat bench with uprights. The trainee lies face up, head toward +Z.
builders.bench = function(model, pivot)
	mat(model, pivot, 7, 7)
	part(model, pivot, "Pad", Vector3.new(1.6, 0.5, 5), CFrame.new(0, 1.75, 0.3), PAD, Enum.Material.Fabric)
	part(model, pivot, "Leg", Vector3.new(0.4, 1.5, 0.4), CFrame.new(0, 0.75, -1.8), METAL)
	part(model, pivot, "Leg", Vector3.new(0.4, 1.5, 0.4), CFrame.new(0, 0.75, 2.4), METAL)
	for _, x in ipairs({ -2.2, 2.2 }) do
		part(model, pivot, "Upright", Vector3.new(0.35, 4.6, 0.35), CFrame.new(x, 2.3, 1.4), METAL)
		part(model, pivot, "Hook", Vector3.new(0.35, 0.3, 0.6), CFrame.new(x, 4.3, 1.2), NEON_PURPLE, Enum.Material.Neon)
	end
	-- Rest = arms extended (bar on the hooks), peak = bar at the chest
	barbell(model, pivot, CFrame.new(0, 4.55, 1.2), 6.5, CFrame.new(0, -1.6, 0))
	local root = CFrame.new(0, 2.5, 0.4) * CFrame.Angles(math.rad(90), 0, 0)
	return root, CFrame.new(4, 3.2, 0)
end

-- Abs bench with a foot roller
builders.abs = function(model, pivot)
	mat(model, pivot, 6, 7)
	part(model, pivot, "Pad", Vector3.new(1.6, 0.5, 5), CFrame.new(0, 1.75, 0.6), PAD, Enum.Material.Fabric)
	part(model, pivot, "Leg", Vector3.new(0.4, 1.5, 0.4), CFrame.new(0, 0.75, -1.4), METAL)
	part(model, pivot, "Leg", Vector3.new(0.4, 1.5, 0.4), CFrame.new(0, 0.75, 2.6), METAL)
	part(model, pivot, "RollerPost", Vector3.new(0.3, 2.4, 0.3), CFrame.new(0, 1.2, -2.4), METAL)
	part(model, pivot, "Roller", Vector3.new(2.2, 0.6, 0.6), CFrame.new(0, 2.5, -2.4), NEON_PURPLE, Enum.Material.Neon, Enum.PartType.Cylinder)
	local root = CFrame.new(0, 2.5, 0.9) * CFrame.Angles(math.rad(90), 0, 0)
	return root, CFrame.new(4, 3.2, 0)
end

-- 45° leg press. The sled slides away along its own back side.
builders.legpress = function(model, pivot)
	mat(model, pivot, 6, 9)
	part(model, pivot, "Frame", Vector3.new(2.6, 0.5, 8), CFrame.new(0, 0.45, 0), METAL)
	part(model, pivot, "Seat", Vector3.new(1.8, 0.5, 1.8), CFrame.new(0, 1.6, 1.8), PAD, Enum.Material.Fabric)
	part(model, pivot, "Back", Vector3.new(1.8, 3.2, 0.5), CFrame.new(0, 2.8, 2.9) * CFrame.Angles(math.rad(-45), 0, 0), PAD, Enum.Material.Fabric)
	for _, x in ipairs({ -1.4, 1.4 }) do
		part(model, pivot, "Rail", Vector3.new(0.3, 0.3, 6), CFrame.new(x, 3.2, -1.6) * CFrame.Angles(math.rad(45), 0, 0), NEON_PURPLE, Enum.Material.Neon)
	end
	-- Platform faces the seat (toward +Z and down); Lift pushes it away along local +Z
	local platformPos = Vector3.new(0, 3.4, -1.0)
	local platformRel = CFrame.lookAt(platformPos, platformPos + Vector3.new(0, -1, 1))
	local platform = part(model, pivot, "Sled", Vector3.new(2.8, 2.6, 0.4), platformRel, Color3.fromRGB(30, 30, 45), Enum.Material.Metal)
	setLift(platform, CFrame.new(0, 0, 1.5))
	local glow = part(model, pivot, "SledGlow", Vector3.new(2.2, 0.2, 0.42), platformRel * CFrame.new(0, 1.1, 0), NEON_PINK, Enum.Material.Neon)
	setLift(glow, CFrame.new(0, 0, 1.5))
	local root = CFrame.new(0, 2.7, 2.0) * CFrame.Angles(math.rad(45), 0, 0)
	return root, CFrame.new(4, 3.2, 0)
end

-- Lat pulldown tower in front of a seat
builders.pulldown = function(model, pivot)
	mat(model, pivot, 6, 6)
	part(model, pivot, "Seat", Vector3.new(1.6, 0.5, 1.6), CFrame.new(0, 1.6, 0.4), PAD, Enum.Material.Fabric)
	part(model, pivot, "SeatPost", Vector3.new(0.4, 1.4, 0.4), CFrame.new(0, 0.8, 0.4), METAL)
	part(model, pivot, "KneePad", Vector3.new(2, 0.5, 0.5), CFrame.new(0, 2.6, -0.6), PAD, Enum.Material.Fabric, Enum.PartType.Cylinder)
	part(model, pivot, "Tower", Vector3.new(0.6, 9, 0.6), CFrame.new(0, 4.5, -1.8), METAL)
	part(model, pivot, "Beam", Vector3.new(0.5, 0.5, 2.4), CFrame.new(0, 8.8, -0.7), NEON_PURPLE, Enum.Material.Neon)
	local lift = CFrame.new(0, -2.0, 0)
	local bar = part(model, pivot, "PullBar", Vector3.new(5, 0.25, 0.25), CFrame.new(0, 6.4, 0.2), Color3.fromRGB(200, 200, 215), Enum.Material.Metal, Enum.PartType.Cylinder)
	setLift(bar, lift)
	local cable = part(model, pivot, "Cable", Vector3.new(0.08, 2.2, 0.08), CFrame.new(0, 7.6, 0.2), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic)
	setLift(cable, lift)
	return CFrame.new(0, 2.85, 0.4), CFrame.new(4, 3.2, 0)
end

-- Rowing machine. Seat and handle move with the stroke.
builders.rower = function(model, pivot)
	mat(model, pivot, 4, 9, NEON_BLUE)
	part(model, pivot, "Rail", Vector3.new(0.8, 0.4, 7.5), CFrame.new(0, 0.6, 0), METAL)
	part(model, pivot, "Flywheel", Vector3.new(1.6, 2.2, 1.4), CFrame.new(0, 1.3, -3.6), Color3.fromRGB(30, 30, 45), Enum.Material.Metal)
	part(model, pivot, "FlywheelGlow", Vector3.new(0.2, 1.6, 1.6), CFrame.new(0.81, 1.3, -3.6), NEON_BLUE, Enum.Material.Neon, Enum.PartType.Cylinder)
	part(model, pivot, "Footplate", Vector3.new(2, 0.8, 0.3), CFrame.new(0, 1.0, -2.2) * CFrame.Angles(math.rad(-30), 0, 0), METAL)
	local seat = part(model, pivot, "RowSeat", Vector3.new(1.4, 0.4, 1.4), CFrame.new(0, 1.0, 1.0), PAD, Enum.Material.Fabric)
	setLift(seat, CFrame.new(0, 0, 1.6))
	local handle = part(model, pivot, "Handle", Vector3.new(2, 0.2, 0.2), CFrame.new(0, 2.2, -1.6), NEON_PINK, Enum.Material.Neon, Enum.PartType.Cylinder)
	setLift(handle, CFrame.new(0, 0.3, 2.4))
	return CFrame.new(0, 2.2, 1.0), CFrame.new(3.5, 3.2, 0)
end

-- Squat rack. The bar sits on the shoulders and drops with the body.
builders.squat = function(model, pivot)
	mat(model, pivot, 7, 7)
	for _, x in ipairs({ -2.4, 2.4 }) do
		part(model, pivot, "Upright", Vector3.new(0.4, 8, 0.4), CFrame.new(x, 4, 0.6), METAL)
		part(model, pivot, "Hook", Vector3.new(0.4, 0.3, 0.6), CFrame.new(x, 4.4, 0.4), NEON_PURPLE, Enum.Material.Neon)
	end
	part(model, pivot, "Top", Vector3.new(5.2, 0.4, 0.4), CFrame.new(0, 8, 0.6), NEON_PURPLE, Enum.Material.Neon)
	barbell(model, pivot, CFrame.new(0, 4.6, 0.35), 7, CFrame.new(0, -1.4, 0))
	return CFrame.new(0, 3.2, 0), CFrame.new(4.5, 3.2, 0)
end

-- Cable crossover: two towers, handles meet in front of the chest
builders.cable = function(model, pivot)
	mat(model, pivot, 9, 6)
	for _, x in ipairs({ -3.8, 3.8 }) do
		part(model, pivot, "Tower", Vector3.new(0.7, 9, 0.7), CFrame.new(x, 4.5, 0.3), METAL)
		part(model, pivot, "TowerGlow", Vector3.new(0.2, 8, 0.72), CFrame.new(x, 4.5, 0.3), NEON_PURPLE, Enum.Material.Neon)
	end
	part(model, pivot, "Beam", Vector3.new(8.3, 0.5, 0.5), CFrame.new(0, 9.1, 0.3), METAL)
	local right = part(model, pivot, "HandleR", Vector3.new(0.3, 0.6, 0.3), CFrame.new(2.9, 4.4, 0), NEON_PINK, Enum.Material.Neon)
	setLift(right, CFrame.new(-2.6, 0, -1.9))
	local left = part(model, pivot, "HandleL", Vector3.new(0.3, 0.6, 0.3), CFrame.new(-2.9, 4.4, 0), NEON_PINK, Enum.Material.Neon)
	setLift(left, CFrame.new(2.6, 0, -1.9))
	return CFrame.new(0, 3.2, 0), CFrame.new(0, 3.2, 4)
end

-- Titan: a glowing arena with a heavy bar (front squat -> overhead press)
builders.titan = function(model, pivot)
	mat(model, pivot, 9, 9, NEON_PINK)
	for _, x in ipairs({ -4, 4 }) do
		for _, z in ipairs({ -4, 4 }) do
			part(model, pivot, "Pillar", Vector3.new(0.6, 10, 0.6), CFrame.new(x, 5, z), METAL)
		end
		part(model, pivot, "TopBeam", Vector3.new(0.6, 0.6, 8.6), CFrame.new(x, 10, 0), METAL)
		part(model, pivot, "TopGlow", Vector3.new(0.2, 0.2, 8.6), CFrame.new(x, 9.65, 0), NEON_PURPLE, Enum.Material.Neon)
	end
	part(model, pivot, "TopBeam", Vector3.new(8.6, 0.6, 0.6), CFrame.new(0, 10, -4), METAL)
	part(model, pivot, "TopBeam", Vector3.new(8.6, 0.6, 0.6), CFrame.new(0, 10, 4), METAL)
	-- Rest: bar at the shoulders in a squat. Peak: overhead.
	barbell(model, pivot, CFrame.new(0, 3.7, -0.5), 7.5, CFrame.new(0, 3.3, 0.4), NEON_PURPLE)
	return CFrame.new(0, 3.3, 0), CFrame.new(5.5, 3.2, 0)
end

-- Posing spot on the podium stage: glowing ring, spotlight, applause anchor
builders.pose = function(model, pivot)
	local ring = part(model, pivot, "Ring", Vector3.new(0.3, 6, 6), CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 60), Enum.Material.Neon, Enum.PartType.Cylinder)
	ring.CanCollide = false
	ring.Transparency = 0.4

	-- Lamp above and slightly in front of the poser, pointing down
	local lamp = part(model, pivot, "Spot", Vector3.new(1.6, 1, 1.6), CFrame.new(0, 16, -5), Color3.fromRGB(20, 20, 30), Enum.Material.Metal)
	lamp.CanCollide = false
	local light = Instance.new("SpotLight")
	light.Name = "Light"
	light.Face = Enum.NormalId.Bottom
	light.Angle = 55
	light.Range = 24
	light.Brightness = 8
	light.Color = Color3.fromRGB(255, 190, 230)
	light.Enabled = false
	light.Parent = lamp

	-- Players in the audience applaud through a prompt here
	local anchor = part(model, pivot, "ApplaudAnchor", Vector3.new(1, 1, 1), CFrame.new(0, 8, 0), Color3.new(1, 1, 1))
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false

	-- Root sits on the stage; leaving puts the player a few studs in front
	return CFrame.new(0, 3.2, 0), CFrame.new(0, 3.2, -6)
end

function MachineModels.build(kind, pivot)
	local builder = builders[kind]
	assert(builder, "No builder for machine " .. tostring(kind))
	local model = Instance.new("Model")
	local rootRel, exitRel = builder(model, pivot)

	-- Invisible part that carries the prompt and the name tag
	local anchor = part(model, pivot, "PromptAnchor", Vector3.new(1, 1, 1), CFrame.new(0, 3, 0), METAL)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	model.PrimaryPart = anchor

	return model, pivot * rootRel, pivot * exitRel
end

return MachineModels
