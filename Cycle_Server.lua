-- // Variables
local Cycle_Info = require(game.ReplicatedStorage.Modules.Cycle_Info)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local cycleConfig = ReplicatedStorage:WaitForChild("Cycle_Config")
local rareOccurrenceConfig = ReplicatedStorage:WaitForChild("RareOccurrence_Config")

local solarEclipseChance = rareOccurrenceConfig:WaitForChild("SolarEclipse_Chance").Value / 100
local lunarEclipseChance = rareOccurrenceConfig:WaitForChild("LunarEclipse_Chance").Value / 100
local totalEclipseChance = rareOccurrenceConfig:WaitForChild("TotalEclipse_Chance").Value / 100

local enableRareOccurrences = cycleConfig:WaitForChild("EnableRareOccurrences").Value
local enableMoonPhases = cycleConfig:WaitForChild("EnableMoonPhases").Value
local startingPhaseName = cycleConfig:WaitForChild("StartingPhase").Value

local gloomEnabled = cycleConfig:WaitForChild("EnableGloomSystem").Value
local nightFogEnabled = cycleConfig:WaitForChild("EnableNightFog").Value

local sky = Lighting:FindFirstChild("Sky")
if not sky then
	error("Please make sure you have a skybox, if you do please rename it to Sky in lighting")
end

local atmosphere = Lighting:FindFirstChild("Atmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
end

local sunRays = Lighting:FindFirstChild("SunRays")
if not sunRays then
	error("Please make sure you have a sunrays, if you do please rename it to SunRays")
end

local debugEnabled = cycleConfig:FindFirstChild("DebugEnabled") and cycleConfig.DebugEnabled.Value
local transitionTime = 2

local originalSettings = {
	Brightness = Lighting.Brightness,
	SunRayIntensity = sunRays.Intensity,
	ExposureCompensation = Lighting.ExposureCompensation,
	GeographicLatitude = Lighting.GeographicLatitude,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	Ambient = Lighting.Ambient,
	AtmosphereDensity = atmosphere.Density,
	AtmosphereOffset = atmosphere.Offset,
	AtmosphereColor = atmosphere.Color,
	AtmosphereDecay = atmosphere.Decay
}

-- Function to ensure value exists
local function ensureValueExists(parent, name, valueType, defaultValue)
	local value = parent:FindFirstChild(name)
	if not value then
		value = Instance.new(valueType)
		value.Name = name
		value.Value = defaultValue
		value.Parent = parent
	end
	return value
end

local currentPhaseStringValue = ensureValueExists(script, "currentPhase", "StringValue", "")
local rareOccurrenceStringValue = ensureValueExists(script, "RareOccurrence", "StringValue", "None")
local pendingEclipseBoolValue = ensureValueExists(script, "pendingEclipse", "BoolValue", false)
local eclipseOccurred = ensureValueExists(script, "eclipseOccurred", "BoolValue", false)

-- // Functions

local function debugPrint(...)
	if debugEnabled then
		warn(...)
	end
end

local function tweenProperty(instance, property, targetValue, duration)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(instance, tweenInfo, {[property] = targetValue})
	tween:Play()
	return tween
end

local function updateSkyTextures(sunTextureId, moonTextureId)
	sky.SunTextureId = sunTextureId or ""
	sky.MoonTextureId = moonTextureId or ""
	debugPrint("Sky textures updated: SunTextureId = " .. tostring(sky.SunTextureId) .. ", MoonTextureId = " .. tostring(sky.MoonTextureId))
end

local function forceRefreshSkyTextures()
	local originalSunTexture = sky.SunTextureId
	local originalMoonTexture = sky.MoonTextureId
	sky.SunTextureId = ""
	sky.MoonTextureId = ""
	task.wait(0.1)
	sky.SunTextureId = originalSunTexture
	sky.MoonTextureId = originalMoonTexture
	debugPrint("Forced refresh of sky textures")
end

local function transitionToPhase(phase)
	debugPrint("Transitioning to phase: " .. phase.name)
	local tweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local tweens = {
		TweenService:Create(Lighting, tweenInfo, { ClockTime = phase.targetClockTime }),
		TweenService:Create(Lighting, tweenInfo, { FogEnd = phase.targetFogEnd }),
		TweenService:Create(Lighting, tweenInfo, { Brightness = phase.targetBrightness }),
		TweenService:Create(Lighting, tweenInfo, { Ambient = phase.targetAmbient }),
		TweenService:Create(atmosphere, tweenInfo, { Density = phase.atmosphereDensity }),
		TweenService:Create(atmosphere, tweenInfo, { Offset = phase.atmosphereOffset }),
		TweenService:Create(atmosphere, tweenInfo, { Color = phase.atmosphereColor }),
		TweenService:Create(atmosphere, tweenInfo, { Decay = phase.atmosphereDecay }),
		TweenService:Create(sunRays, tweenInfo, { Intensity = phase.targetSunRayIntensity })
	}

	if phase.name == "Night" then
		table.insert(tweens, TweenService:Create(Lighting, tweenInfo, { ExposureCompensation = phase.targetExposureCompensation }))
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	local transitionComplete = Instance.new("BoolValue")
	transitionComplete.Value = false

	tweens[1].Completed:Connect(function()
		transitionComplete.Value = true
		debugPrint("Transition to phase complete: " .. phase.name)
	end)

	currentPhaseStringValue.Value = phase.name
	return transitionComplete
end

local function updateGloom(skipUpdate)
	if gloomEnabled and not skipUpdate then
		if Lighting.ClockTime >= 18 or Lighting.ClockTime <= 6 then
			--tweenProperty(Lighting, "Ambient", Color3.fromRGB(80, 80, 80), transitionTime)
		else
			--tweenProperty(Lighting, "Ambient", Cycle_Info.phases[2].targetAmbient, transitionTime)
		end
	end
end

local function updateFog(skipUpdate)
	if nightFogEnabled and not skipUpdate then
		if Lighting.ClockTime >= 18 and Lighting.ClockTime <= 24 then
			tweenProperty(Lighting, "FogColor", Color3.fromRGB(0, 0, 0), transitionTime)
		else
			tweenProperty(Lighting, "FogColor", Color3.fromRGB(255, 255, 255), transitionTime)
		end
	end
end

local function updateCelestialBodies(skipSunIntensityUpdate, skipSunTextureUpdate, skipUpdate, eclipseOngoing)
	if eclipseOngoing then
		return -- Skip updating sun texture and intensity during eclipses
	end

	local time = Lighting.ClockTime
	local sunIntensity = 0

	if time >= 6 and time <= 18 then
		local progress = (time - 6) / 12
		local angle = progress * math.pi
		sunIntensity = 1 - math.abs(12 - time) / 6
	else
		sunIntensity = 0
	end

	if time < 6 or time > 18 then
		if not skipSunTextureUpdate then
			updateSkyTextures("", sky.MoonTextureId)
		end
	else
		if not skipSunTextureUpdate then
			updateSkyTextures(Cycle_Info.Textures.Sun, "")
		end
	end

	if not skipSunIntensityUpdate and math.abs(sunRays.Intensity - sunIntensity) > 0.01 then
		sunRays.Intensity = sunIntensity
		Lighting.EnvironmentDiffuseScale = sunIntensity
		Lighting.EnvironmentSpecularScale = sunIntensity
		debugPrint("Updated sun intensity to: " .. sunIntensity)
	end

	if not skipUpdate then
		updateGloom()
		updateFog()
	end
end

local function applyRareOccurrenceSettings(settings)
	for property, value in pairs(settings) do
		if property == "Brightness" then
			Lighting.Brightness = value
		elseif property == "SunRayIntensity" then
			sunRays.Intensity = value
		elseif property == "ExposureCompensation" then
			Lighting.ExposureCompensation = value
		elseif property == "GeographicLatitude" then
			Lighting.GeographicLatitude = value
		elseif property == "EnvironmentDiffuseScale" then
			Lighting.EnvironmentDiffuseScale = value
		elseif property == "EnvironmentSpecularScale" then
			Lighting.EnvironmentSpecularScale = value
		elseif property == "Ambient" then
			Lighting.Ambient = value
		elseif property == "AtmosphereDensity" then
			atmosphere.Density = value
		elseif property == "AtmosphereOffset" then
			atmosphere.Offset = value
		elseif property == "AtmosphereColor" then
			atmosphere.Color = value
		elseif property == "AtmosphereDecay" then
			atmosphere.Decay = value
		end
	end
end

local moonPhaseSet = false
local eclipseOngoing = false

local function updateMoonPhase()
	if enableMoonPhases and not moonPhaseSet then
		local moonPhases = {
			Cycle_Info.moonPhases.NewMoon,
			Cycle_Info.moonPhases.WaxingCrescent,
			Cycle_Info.moonPhases.FirstQuarter,
			Cycle_Info.moonPhases.WaxingGibbous,
			Cycle_Info.moonPhases.FullMoon,
			Cycle_Info.moonPhases.WaningGibbous,
			Cycle_Info.moonPhases.ThirdQuarter,
			Cycle_Info.moonPhases.WaningCrescent
		}
		local randomPhase = moonPhases[math.random(#moonPhases)]
		updateSkyTextures(nil, randomPhase)
		moonPhaseSet = true
		debugPrint("Moon phase changed to: " .. randomPhase)
	elseif not enableMoonPhases then
		updateSkyTextures(nil, Cycle_Info.moonPhases.Default)
		debugPrint("Moon phase set to default")
	end
end

local function handleEclipse(eclipseType)
	if eclipseOccurred.Value then
		return -- Skip if an eclipse has already occurred
	end
	debugPrint(eclipseType .. " is occurring!")
	rareOccurrenceStringValue.Value = eclipseType
	local textureId = Cycle_Info.RareOccurrences[eclipseType]
	updateSkyTextures(textureId, nil)
	task.delay(4, function()
		applyRareOccurrenceSettings(Cycle_Info.RareOccurrenceSettings[eclipseType])
		eclipseOngoing = true
		debugPrint(eclipseType .. " texture changed to: " .. textureId)
	end)
end

local function resetEclipseEffects()
	updateSkyTextures(Cycle_Info.Textures.Sun, sky.MoonTextureId)
	applyRareOccurrenceSettings(originalSettings)
	rareOccurrenceStringValue.Value = "None"
	eclipseOngoing = false
	eclipseOccurred.Value = true -- Set flag to indicate an eclipse has occurred
	-- Set chances to 0 to prevent future eclipses
	solarEclipseChance = 0
	lunarEclipseChance = 0
	totalEclipseChance = 0
	debugPrint("Reset eclipse effects")
	debugPrint("Sun texture reset to default")
	debugPrint("Sun intensity reset to: " .. originalSettings.SunRayIntensity)
	debugPrint("Brightness reset to: " .. originalSettings.Brightness)
	debugPrint("Ambient reset to: " .. tostring(originalSettings.Ambient))
end

-- // Main Cycle Loop
local isTransitioning = false
local pendingEclipse = nil
local solarEclipseScheduled = false
local totalEclipseScheduled = false
local solarEclipsePhase = nil
local totalEclipsePhase = nil
local inEclipse = false
local solarEclipseOngoing = false
local daytimePhases = {
	"Morning",
	"Noon",
	"Afternoon"
}

warn(startingPhaseName)
local PhasePtr = Cycle_Info.lookup[startingPhaseName]

while true do
	local currentPhase = Cycle_Info.phases[PhasePtr]
	debugPrint("Starting phase: " .. currentPhase.name)
	warn(PhasePtr)
	local transitionComplete = transitionToPhase(currentPhase)
	isTransitioning = not transitionComplete.Value

	if enableRareOccurrences then
		if pendingEclipse then
			debugPrint("Pending eclipse exists")
			pendingEclipseBoolValue.Value = true
			if not isTransitioning then
				debugPrint("Executing pending eclipse")
				pendingEclipse()
				pendingEclipse = nil
				pendingEclipseBoolValue.Value = false
				inEclipse = true
			end
		else
			if not solarEclipseScheduled and currentPhase.name ~= "Sunrise" and currentPhase.name ~= "Sunset" and currentPhase.name ~= "EarlyMorning" and math.random() < solarEclipseChance then
				solarEclipseScheduled = true
				local randomPhaseIndex = math.random(2, 4) -- Morning (2), Noon (3), Afternoon (4)
				solarEclipsePhase = Cycle_Info.phases[randomPhaseIndex]
				debugPrint("Solar eclipse scheduled for phase: " .. solarEclipsePhase.name)
			end

			if not totalEclipseScheduled and currentPhase.name ~= "Sunrise" and currentPhase.name ~= "Sunset" and currentPhase.name ~= "EarlyMorning" and math.random() < totalEclipseChance then
				totalEclipseScheduled = true
				local randomPhaseIndex = math.random(2, 4) -- Morning (2), Noon (3), Afternoon (4)
				totalEclipsePhase = Cycle_Info.phases[randomPhaseIndex]
				debugPrint("Total eclipse scheduled for phase: " .. totalEclipsePhase.name)
			end

			if solarEclipseScheduled and currentPhase.name == solarEclipsePhase.name then
				debugPrint("Solar eclipse occurring during phase: " .. currentPhase.name)
				solarEclipseOngoing = true
				handleEclipse("SolarEclipse")
				local solarEclipseTime = Cycle_Info.RareOccurrenceTimes.SolarEclipse * 60
				debugPrint("Solar eclipse duration: " .. solarEclipseTime .. " seconds")
				for i = 1, solarEclipseTime do
					debugPrint("Solar eclipse ends in " .. (solarEclipseTime - i) .. " seconds")
					updateCelestialBodies(true, solarEclipseOngoing, true, true)
					task.wait(1)  -- Wait for 1 second
				end
				resetEclipseEffects()
				solarEclipseScheduled = false
				solarEclipsePhase = nil
				inEclipse = false
				solarEclipseOngoing = false
			elseif totalEclipseScheduled and currentPhase.name == totalEclipsePhase.name then
				debugPrint("Total eclipse occurring during phase: " .. currentPhase.name)
				solarEclipseOngoing = true
				handleEclipse("TotalEclipse")
				local totalEclipseTime = Cycle_Info.RareOccurrenceTimes.TotalEclipse * 60
				debugPrint("Total eclipse duration: " .. totalEclipseTime .. " seconds")
				for i = 1, totalEclipseTime do
					debugPrint("Total eclipse ends in " .. (totalEclipseTime - i) .. " seconds")
					updateCelestialBodies(true, solarEclipseOngoing, true, true)
					task.wait(1)  -- Wait for 1 second
				end
				resetEclipseEffects()
				totalEclipseScheduled = false
				totalEclipsePhase = nil
				inEclipse = false
				solarEclipseOngoing = false
			elseif currentPhase.name == "Night" then
				if math.random() < lunarEclipseChance then
					debugPrint("A lunar eclipse is occurring!")
					rareOccurrenceStringValue.Value = "Lunar Eclipse"
					local moonTextureId = Cycle_Info.RareOccurrences.LunarEclipse
					updateSkyTextures(nil, moonTextureId)
					task.delay(4, function()
						applyRareOccurrenceSettings(Cycle_Info.RareOccurrenceSettings.LunarEclipse)
						eclipseOngoing = true
						debugPrint("Lunar eclipse texture changed to: " .. moonTextureId)
					end)
					local lunarEclipseTime = Cycle_Info.RareOccurrenceTimes.LunarEclipse * 60
					debugPrint("Lunar eclipse duration: " .. lunarEclipseTime .. " seconds")
					for i = 1, lunarEclipseTime do
						debugPrint("Lunar eclipse ends in " .. (lunarEclipseTime - i) .. " seconds")
						updateCelestialBodies(true, false, true, true)
						task.wait(1)  -- Wait for 1 second
					end
					resetEclipseEffects()
				else
					updateMoonPhase()
				end
			end
		end
	end

	-- Convert minutes to seconds and wait for the duration of the current phase
	local waitTime = currentPhase.minutes * 60 -- Convert minutes to seconds
	debugPrint("Phase duration: " .. waitTime .. " seconds")
	for i = 1, waitTime do
		debugPrint("Phase ends in " .. (waitTime - i) .. " seconds")
		updateCelestialBodies(inEclipse, solarEclipseOngoing, false, eclipseOngoing)
		task.wait(1)  -- Wait for 1 second
	end

	-- Reset the sun texture after the night ends
	if currentPhase.name == "Night" then
		moonPhaseSet = false  -- Allow new moon phase to be set for the next night cycle
		debugPrint("Moon texture maintained after night phase")
	end

	-- Move to the next phase

	PhasePtr += 1
	if PhasePtr == 8 then
		PhasePtr = 1
	end
	debugPrint("Moving to next phase: " .. Cycle_Info.phases[PhasePtr].name)
end
