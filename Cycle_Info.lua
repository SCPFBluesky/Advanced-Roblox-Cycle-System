local Cycle_Info = {}

Cycle_Info.lookup = {
	Sunrise = 1,
	Morning = 2,
	Noon = 3,
	Afternoon = 4,
	Evening = 5,
	Sunset = 6,
	Night = 7
}

Cycle_Info.phases = {
	{
		name = "Sunrise",
		minutes = 1,
		targetClockTime = 6.1,
		targetFogEnd = 1000,
		targetBrightness = 0.5,
		targetAmbient = Color3.fromRGB(255, 171, 171),
		atmosphereDensity = 0.4,
		atmosphereOffset = 0.2,
		atmosphereColor = Color3.fromRGB(255, 200, 150),
		atmosphereDecay = Color3.fromRGB(100, 50, 50),
		targetSunRayIntensity = 0.5,
		targetExposureCompensation = 0
	},
	{
		name = "Morning",
		minutes = 1,
		targetClockTime = 9,
		targetFogEnd = 1000,
		targetBrightness = 1,
		targetAmbient = Color3.fromRGB(255, 255, 255),
		atmosphereDensity = 0.3,
		atmosphereOffset = 0.25,
		atmosphereColor = Color3.fromRGB(255, 255, 255),
		atmosphereDecay = Color3.fromRGB(150, 150, 150),
		targetSunRayIntensity = 1,
		targetExposureCompensation = 0
	},
	{
		name = "Noon",
		minutes = 1,
		targetClockTime = 12,
		targetFogEnd = 1000,
		targetBrightness = 1,
		targetAmbient = Color3.fromRGB(255, 255, 255),
		atmosphereDensity = 0.2,
		atmosphereOffset = 0.3,
		atmosphereColor = Color3.fromRGB(255, 255, 255),
		atmosphereDecay = Color3.fromRGB(200, 200, 200),
		targetSunRayIntensity = 1,
		targetExposureCompensation = 0
	},
	{
		name = "Afternoon",
		minutes = 1,
		targetClockTime = 15,
		targetFogEnd = 1000,
		targetBrightness = 1,
		targetAmbient = Color3.fromRGB(255, 255, 255),
		atmosphereDensity = 0.3,
		atmosphereOffset = 0.25,
		atmosphereColor = Color3.fromRGB(255, 255, 255),
		atmosphereDecay = Color3.fromRGB(150, 150, 150),
		targetSunRayIntensity = 1,
		targetExposureCompensation = 0
	},
	{
		name = "Evening",
		minutes = 1,
		targetClockTime = 18,
		targetFogEnd = 1000,
		targetBrightness = 0.5,
		targetAmbient = Color3.fromRGB(200, 200, 200),
		atmosphereDensity = 0.4,
		atmosphereOffset = 0.2,
		atmosphereColor = Color3.fromRGB(255, 200, 150),
		atmosphereDecay = Color3.fromRGB(100, 50, 50),
		targetSunRayIntensity = 0.5,
		targetExposureCompensation = 0
	},
	{
		name = "Sunset",
		minutes = 1,
		targetClockTime = 17.8,
		targetFogEnd = 1000,
		targetBrightness = 0.5,
		targetAmbient = Color3.fromRGB(204, 111, 104),
		atmosphereDensity = 0.3,
		atmosphereOffset = 0.25,
		atmosphereColor = Color3.fromRGB(255, 120, 97),
		atmosphereDecay = Color3.fromRGB(106, 66, 48),
		targetSunRayIntensity = 0.5,
		targetExposureCompensation = 0
	},
	{
		name = "Night",
		minutes = 1,
		targetClockTime = 21,
		targetFogEnd = 100,
		targetBrightness = 0.2,
		targetAmbient = Color3.fromRGB(0, 0, 0),
		atmosphereDensity = 0.5,
		atmosphereOffset = 0.2,
		atmosphereColor = Color3.fromRGB(50, 50, 100),
		atmosphereDecay = Color3.fromRGB(0, 0, 0),
		targetSunRayIntensity = 0,
		targetExposureCompensation = -2
	},
}

Cycle_Info.moonPhases = {
	Default = "rbxassetid://6444320592",
	NewMoon = "rbxassetid://0",
	WaxingCrescent = "rbxassetid://18433303273",
	FirstQuarter = "rbxassetid://18433306897",
	WaxingGibbous = "rbxassetid://18433310984",
	FullMoon = "rbxassetid://18433314553",
	WaningGibbous = "rbxassetid://18433319161",
	ThirdQuarter = "rbxassetid://18433328592",
	WaningCrescent = "rbxassetid://18433324891",
}

Cycle_Info.RareOccurrences = {
	SolarEclipse = "rbxassetid://18433675007",
	LunarEclipse = "rbxassetid://13713200424",
	TotalEclipse = "rbxassetid://18433972178" 
}

Cycle_Info.Textures = {
	Sun = "rbxassetid://6196665106"
}

Cycle_Info.RareOccurrenceTimes = {
	SolarEclipse = 7, -- Will use the same minutes into seconds system
	LunarEclipse = 6,
	TotalEclipse = 5
}

Cycle_Info.RareOccurrenceSettings = {
	SolarEclipse = {
		Brightness = 0.1,
		SunRayIntensity = 0,
		ExposureCompensation = -3,
		GeographicLatitude = 0,
		EnvironmentDiffuseScale = 0,
		EnvironmentSpecularScale = 0
	},
	LunarEclipse = {
		Brightness = 0.05,
		Ambient = Color3.fromRGB(10, 10, 10)
	},
	TotalEclipse = {
		Brightness = 0,
		SunRayIntensity = 0,
		Ambient = Color3.fromRGB(0, 0, 0),
		AtmosphereDensity = 0.7,
		AtmosphereOffset = 0.1,
		ExposureCompensation = -5,
		AtmosphereColor = Color3.fromRGB(0, 0, 0),
		AtmosphereDecay = Color3.fromRGB(50, 50, 50)
	}
}

return Cycle_Info
