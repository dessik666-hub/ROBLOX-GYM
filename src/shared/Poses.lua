-- Procedural body poses for every machine. No animation assets needed.
--
-- A pose is a table of joint angles in degrees:
--   sL/sR  shoulder pitch (+ = arm forward/up)
--   oL/oR  shoulder out   (+ = arm out to the side)
--   eL/eR  elbow bend     (+ = forearm up)
--   hL/hR  hip pitch      (+ = leg forward/up)
--   kL/kR  knee bend      (+ = lower leg back)
--   w      waist lean     (+ = torso forward)
--   d      body drop in studs (squats)
--   zb     body shift back in studs (rowing seat)
--
-- Weight machines have pose `a` (rest, c = 0) and pose `b` (peak of the rep, c = 1).
-- Cardio machines have `cycle(t, speed)` that returns a pose for time t.

local Poses = {}

local function lerp(a, b, c)
	return a + (b - a) * c
end

function Poses.blend(a, b, c)
	local out = {}
	for k, v in pairs(a) do
		out[k] = lerp(v, b[k] or 0, c)
	end
	for k, v in pairs(b) do
		if out[k] == nil then
			out[k] = lerp(0, v, c)
		end
	end
	return out
end

-- Standing biceps curl with a dumbbell in each hand
Poses.dumbbells = {
	a = { sL = 5, sR = 5, eL = 10, eR = 10 },
	b = { sL = 15, sR = 15, eL = 135, eR = 135 },
	handProps = true,
}

-- Lying on the back. Arms straight up at rest, bar at the chest at the peak.
Poses.bench = {
	a = { sL = 90, sR = 90, eL = 0, eR = 0, hL = 20, hR = 20, kL = 70, kR = 70 },
	b = { sL = 80, sR = 80, oL = 35, oR = 35, eL = 95, eR = 95, hL = 20, hR = 20, kL = 70, kR = 70 },
}

-- Crunch on the abs bench, hands behind the head
Poses.abs = {
	a = { sL = 150, sR = 150, oL = 30, oR = 30, eL = 120, eR = 120, hL = 60, hR = 60, kL = 90, kR = 90, w = 0 },
	b = { sL = 150, sR = 150, oL = 30, oR = 30, eL = 120, eR = 120, hL = 75, hR = 75, kL = 90, kR = 90, w = 55 },
}

-- Reclined leg press: knees bent at rest, legs straight at the peak
Poses.legpress = {
	a = { hL = 105, hR = 105, kL = 105, kR = 105, sL = 20, sR = 20, eL = 30, eR = 30 },
	b = { hL = 80, hR = 80, kL = 10, kR = 10, sL = 20, sR = 20, eL = 30, eR = 30 },
}

-- Seated lat pulldown: arms up at rest, bar pulled to the chin at the peak
Poses.pulldown = {
	a = { sL = 170, sR = 170, oL = 20, oR = 20, eL = 10, eR = 10, hL = 90, hR = 90, kL = 90, kR = 90 },
	b = { sL = 40, sR = 40, oL = 65, oR = 65, eL = 115, eR = 115, hL = 90, hR = 90, kL = 90, kR = 90, w = -10 },
}

-- Back squat with the bar on the shoulders
Poses.squat = {
	a = { sL = 25, sR = 25, oL = 75, oR = 75, eL = 120, eR = 120 },
	b = { sL = 25, sR = 25, oL = 75, oR = 75, eL = 120, eR = 120, hL = 95, hR = 95, kL = 105, kR = 105, w = 25, d = 1.4 },
}

-- Cable crossover: arms wide at rest, hands together in front at the peak
Poses.cable = {
	a = { sL = 10, sR = 10, oL = 80, oR = 80, eL = 15, eR = 15 },
	b = { sL = 80, sR = 80, oL = -10, oR = -10, eL = 15, eR = 15, w = 10 },
}

-- Titan: from a front squat with the bar at the shoulders to an overhead press
Poses.titan = {
	a = { sL = 60, sR = 60, oL = 30, oR = 30, eL = 140, eR = 140, hL = 80, hR = 80, kL = 90, kR = 90, w = 15, d = 1.2 },
	b = { sL = 175, sR = 175, oL = 10, oR = 10, eL = 5, eR = 5 },
}

-- Running on the treadmill. Faster speed = faster stride.
Poses.treadmill = {
	cycle = function(t, speed)
		local freq = 5 + speed * 0.25
		local sw = math.sin(t * freq)
		local amp = math.min(45, 20 + speed)
		return {
			hL = -amp * sw,
			hR = amp * sw,
			kL = 15 + 55 * math.max(0, sw),
			kR = 15 + 55 * math.max(0, -sw),
			sL = amp * 0.9 * sw,
			sR = -amp * 0.9 * sw,
			eL = 85,
			eR = 85,
			w = 8,
		}
	end,
	-- Phase used to move machine parts (belt). Not a rep.
	phase = function(t, speed)
		return t * (2 + speed * 0.3)
	end,
}

-- Rowing: catch (knees bent, arms out) -> finish (legs straight, handle at chest)
Poses.rower = {
	cycle = function(t, speed)
		local c = (math.sin(t * (2 + speed * 0.08)) + 1) / 2
		return Poses.blend(
			{ hL = 110, hR = 110, kL = 120, kR = 120, sL = 80, sR = 80, eL = 0, eR = 0, w = 30, zb = 0 },
			{ hL = 85, hR = 85, kL = 5, kR = 5, sL = 25, sR = 25, eL = 110, eR = 110, w = -15, zb = 1.6 },
			c
		)
	end,
	phase = function(t, speed)
		return (math.sin(t * (2 + speed * 0.08)) + 1) / 2
	end,
}

---------------------------------------------------------------------------
-- Podium
---------------------------------------------------------------------------
local FLEXES = {
	{ sL = 90, sR = 90, oL = 90, oR = 90, eL = 100, eR = 100 }, -- double biceps
	{ sL = 35, sR = 35, oL = 25, oR = 25, eL = 75, eR = 75, w = 12 }, -- most muscular ("crab")
	{ sL = -15, sR = -15, oL = 45, oR = 45, eL = 95, eR = 95 }, -- front lat spread
	{ sL = 170, sR = 170, oL = 30, oR = 30, eL = 15, eR = 15 }, -- victory, arms up
}

local function smooth(x)
	return x * x * (3 - 2 * x)
end

-- Cycles through bodybuilding poses, holding each and blending to the next
Poses.pose = {
	cycle = function(t)
		local hold = 2.4
		local i = math.floor(t / hold)
		local f = t / hold - i
		local a = FLEXES[i % #FLEXES + 1]
		local b = FLEXES[(i + 1) % #FLEXES + 1]
		local c = f > 0.75 and smooth((f - 0.75) / 0.25) or 0
		local p = Poses.blend(a, b, c)
		-- Breathing and a little shake while flexing
		p.w = (p.w or 0) + math.sin(t * 2) * 2
		p.eL = (p.eL or 0) + math.sin(t * 23) * 1.5
		p.eR = (p.eR or 0) + math.sin(t * 23 + 1) * 1.5
		return p
	end,
	phase = function()
		return 0
	end,
}

-- Spectators clapping
Poses.clap = {
	cycle = function(t)
		local s = math.abs(math.sin(t * 7))
		return { sL = 75, sR = 75, oL = -8 + 25 * s, oR = -8 + 25 * s, eL = 40, eR = 40 }
	end,
	phase = function()
		return 0
	end,
}

return Poses
