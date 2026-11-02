-- Animates every player who is on a machine: their body pose (joints) and the
-- machine's moving parts. Runs on each client for all players, because joint
-- Transforms don't replicate.
--
-- The server marks a trainee with character attributes:
--   Station = station id, Kind = machine kind, RunSpeed = mph (cardio)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Poses = require(RS.Shared:WaitForChild("Poses"))

local TrainAnimator = {}

local localPlayer = Players.LocalPlayer
local states = {} -- [character] = state
local rad = math.rad

---------------------------------------------------------------------------
-- Joints
---------------------------------------------------------------------------
local function findMotor(character, partName, motorName)
	local p = character:FindFirstChild(partName)
	local m = p and p:FindFirstChild(motorName)
	if m and m:IsA("Motor6D") then
		return m
	end
	return nil
end

local function getJoints(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		return {
			r15 = true,
			shoulderL = findMotor(character, "LeftUpperArm", "LeftShoulder"),
			shoulderR = findMotor(character, "RightUpperArm", "RightShoulder"),
			elbowL = findMotor(character, "LeftLowerArm", "LeftElbow"),
			elbowR = findMotor(character, "RightLowerArm", "RightElbow"),
			hipL = findMotor(character, "LeftUpperLeg", "LeftHip"),
			hipR = findMotor(character, "RightUpperLeg", "RightHip"),
			kneeL = findMotor(character, "LeftLowerLeg", "LeftKnee"),
			kneeR = findMotor(character, "RightLowerLeg", "RightKnee"),
			waist = findMotor(character, "UpperTorso", "Waist"),
			root = findMotor(character, "LowerTorso", "Root"),
		}
	end
	-- R6: only shoulders and hips bend; poses are approximate
	return {
		r15 = false,
		shoulderL = findMotor(character, "Torso", "Left Shoulder"),
		shoulderR = findMotor(character, "Torso", "Right Shoulder"),
		hipL = findMotor(character, "Torso", "Left Hip"),
		hipR = findMotor(character, "Torso", "Right Hip"),
	}
end

local function set(motor, cf)
	if motor and motor.Parent then
		motor.Transform = cf
	end
end

local function applyPose(j, p)
	if j.r15 then
		set(j.shoulderL, CFrame.Angles(rad(p.sL or 0), 0, -rad(p.oL or 0)))
		set(j.shoulderR, CFrame.Angles(rad(p.sR or 0), 0, rad(p.oR or 0)))
		set(j.elbowL, CFrame.Angles(rad(p.eL or 0), 0, 0))
		set(j.elbowR, CFrame.Angles(rad(p.eR or 0), 0, 0))
		set(j.hipL, CFrame.Angles(rad(p.hL or 0), 0, 0))
		set(j.hipR, CFrame.Angles(rad(p.hR or 0), 0, 0))
		set(j.kneeL, CFrame.Angles(-rad(p.kL or 0), 0, 0))
		set(j.kneeR, CFrame.Angles(-rad(p.kR or 0), 0, 0))
		set(j.waist, CFrame.Angles(-rad(p.w or 0), 0, 0))
		set(j.root, CFrame.new(0, -(p.d or 0), p.zb or 0))
	else
		-- R6 motors rotate around their Z axis; left side is mirrored
		set(j.shoulderL, CFrame.Angles(0, 0, -rad(p.sL or 0)))
		set(j.shoulderR, CFrame.Angles(0, 0, rad(p.sR or 0)))
		set(j.hipL, CFrame.Angles(0, 0, -rad(p.hL or 0)))
		set(j.hipR, CFrame.Angles(0, 0, rad(p.hR or 0)))
	end
end

local function resetPose(j)
	for _, motor in pairs(j) do
		if typeof(motor) == "Instance" and motor.Parent then
			motor.Transform = CFrame.identity
		end
	end
end

---------------------------------------------------------------------------
-- Dumbbells in the hands (local cosmetic parts)
---------------------------------------------------------------------------
local function makeDumbbell(hand)
	local model = Instance.new("Model")
	model.Name = "HeldDumbbell"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Cylinder
	handle.Size = Vector3.new(1.1, 0.25, 0.25)
	handle.Color = Color3.fromRGB(200, 200, 215)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = model
	for _, side in ipairs({ -1, 1 }) do
		local plate = Instance.new("Part")
		plate.Shape = Enum.PartType.Cylinder
		plate.Size = Vector3.new(0.3, 0.75, 0.75)
		plate.Color = Color3.fromRGB(255, 80, 200)
		plate.Material = Enum.Material.Neon
		plate.CanCollide = false
		plate.Massless = true
		plate.CFrame = handle.CFrame * CFrame.new(side * 0.55, 0, 0)
		plate.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = plate
		w.Parent = plate
	end
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = handle
	weld.C0 = CFrame.new(0, -0.35, 0)
	weld.Parent = handle
	model.Parent = hand
	return model
end

local function addHandProps(character)
	local props = {}
	for _, name in ipairs({ "LeftHand", "RightHand", "Left Arm", "Right Arm" }) do
		local hand = character:FindFirstChild(name)
		if hand and hand:IsA("BasePart") then
			local d = makeDumbbell(hand)
			if name == "Left Arm" or name == "Right Arm" then
				d.Handle:FindFirstChildOfClass("Weld").C0 = CFrame.new(0, -1.1, 0)
			end
			table.insert(props, d)
		end
	end
	return props
end

---------------------------------------------------------------------------
-- Local player's default Animate script must stop while training
---------------------------------------------------------------------------
local function setDefaultAnimation(character, enabled)
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Enabled = enabled
	end
	if not enabled then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				track:Stop(0.1)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Start / stop / update
---------------------------------------------------------------------------
local function stationModel(stationId)
	local gym = workspace:FindFirstChild("Gym")
	local folder = gym and gym:FindFirstChild("Stations")
	return folder and folder:FindFirstChild(stationId)
end

-- character: a player's character or an NPC model. NPCs have no station model.
local function start(character, stationId, kind)
	local pose = kind and Poses[kind]
	local isNpc = string.sub(stationId, 1, 4) == "npc:"
	local model = not isNpc and stationModel(stationId) or nil
	if not pose or (not isNpc and not model) then
		return nil -- attributes or model not replicated yet; try next frame
	end

	local st = {
		stationId = stationId,
		kind = kind,
		pose = pose,
		repTime = (Config.Machines[kind] and Config.Machines[kind].repTime) or 1,
		repStart = -math.huge,
		repOk = true,
		joints = getJoints(character),
		lifts = {},
		belts = {},
		props = {},
		isLocal = Players:GetPlayerFromCharacter(character) == localPlayer,
		offset = math.random() * 20, -- so NPCs don't pose in sync
	}

	for _, d in ipairs(model and model:GetDescendants() or {}) do
		if d:IsA("BasePart") then
			local home = d:GetAttribute("Home")
			if typeof(home) == "CFrame" then
				local lift = d:GetAttribute("Lift")
				local beltZ = d:GetAttribute("BeltZ")
				if typeof(lift) == "CFrame" then
					table.insert(st.lifts, { part = d, home = home, lift = lift })
				elseif typeof(beltZ) == "number" then
					table.insert(st.belts, { part = d, home = home, z0 = beltZ })
				end
			end
		end
	end

	if pose.handProps then
		st.props = addHandProps(character)
	end
	if st.isLocal then
		setDefaultAnimation(character, false)
	end

	states[character] = st
	return st
end

local function stop(character, st)
	resetPose(st.joints)
	for _, l in ipairs(st.lifts) do
		l.part.CFrame = l.home
	end
	for _, b in ipairs(st.belts) do
		b.part.CFrame = b.home
	end
	for _, p in ipairs(st.props) do
		p:Destroy()
	end
	if st.isLocal and character.Parent then
		setDefaultAnimation(character, true)
	end
	states[character] = nil
end

-- 0 -> 1 -> 0 over one rep. Failed reps only twitch.
local function repCurve(st, now)
	local t = (now - st.repStart) / st.repTime
	if t < 0 or t >= 1 then
		return 0
	end
	local c = math.sin(math.pi * t)
	if not st.repOk then
		c = c * 0.25 + math.sin(t * 70) * 0.03
	end
	return c
end

local function update(character, st, now)
	local pose = st.pose
	local c
	if pose.cycle then
		local speed = character:GetAttribute("RunSpeed") or 3
		applyPose(st.joints, pose.cycle(now + st.offset, speed))
		c = pose.phase(now, speed)
		for _, b in ipairs(st.belts) do
			local z = ((b.z0 + c + 3) % 6) - 3
			b.part.CFrame = b.home * CFrame.new(0, 0, z - b.z0)
		end
		-- Rower seat/handle follow the stroke phase (0..1)
		if #st.lifts > 0 then
			for _, l in ipairs(st.lifts) do
				l.part.CFrame = l.home * CFrame.identity:Lerp(l.lift, c)
			end
		end
	else
		c = repCurve(st, now)
		applyPose(st.joints, Poses.blend(pose.a, pose.b, c))
		for _, l in ipairs(st.lifts) do
			l.part.CFrame = l.home * CFrame.identity:Lerp(l.lift, c)
		end
	end
end

-- Everyone who should be animated this frame: { model, stationId, kind }
local function collect()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local stationId = character and character:GetAttribute("Station")
		if stationId then
			table.insert(list, { character, stationId, character:GetAttribute("Kind") })
		end
	end
	local gym = workspace:FindFirstChild("Gym")
	local npcs = gym and gym:FindFirstChild("NPCs")
	if npcs then
		for _, npc in ipairs(npcs:GetChildren()) do
			local kind = npc:GetAttribute("Pose")
			if kind then
				table.insert(list, { npc, "npc:" .. kind, kind })
			end
		end
	end
	return list
end

RunService.PreSimulation:Connect(function()
	local now = os.clock()
	local seen = {}
	for _, entry in ipairs(collect()) do
		local character, stationId, kind = entry[1], entry[2], entry[3]
		local st = states[character]
		if st and st.stationId ~= stationId then
			stop(character, st)
			st = nil
		end
		st = st or start(character, stationId, kind)
		if st then
			update(character, st, now)
			seen[character] = true
		end
	end
	for character, st in pairs(states) do
		if not seen[character] then
			stop(character, st)
		end
	end
end)

-- Called when the server says a rep happened
function TrainAnimator.onRep(player, ok)
	local character = player.Character
	local st = character and states[character]
	if not st or st.pose.cycle then
		return
	end
	local now = os.clock()
	local t = (now - st.repStart) / st.repTime
	if t >= 0.5 and t < 1 then
		-- On the way down: mirror into the way up so the motion stays smooth
		st.repStart = now - (1 - t) * st.repTime
	elseif t >= 1 or t < 0 then
		st.repStart = now
	end
	-- Still going up: let the current rep continue
	st.repOk = ok
end

return TrainAnimator
