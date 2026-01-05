#define ART_WIND_MAX 5

SUBSYSTEM_DEF(artillery_weather)
	name = "Artillery Weather"
	init_order = INIT_ORDER_DEFAULT
	wait = 2 SECONDS

	/// base (roundstart)
	var/wind_dir = 0
	var/wind_strength = 0
	var/air_density = 1.0
	var/humidity = 0.0

	/// deltas from external weather (rain/fog systems)
	var/density_delta = 0.0
	var/humidity_delta = 0.0
	var/wind_strength_delta = 0
	var/wind_dir_delta = 0

	/// cooldown
	var/next_weather_step = 0
	var/weather_step_cd = 25 SECONDS

/datum/controller/subsystem/artillery_weather/Initialize(timeofday)
	generate_roundstart()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/artillery_weather/proc/generate_roundstart()
	wind_dir = rand(0, 359)
	wind_strength = rand(0, ART_WIND_MAX)
	air_density = rand(85, 115) / 100
	humidity = rand(0, 100) / 100

	clear_weather_data()
	next_weather_step = world.time + weather_step_cd

/datum/controller/subsystem/artillery_weather/proc/clear_weather_data()
	density_delta = 0
	humidity_delta = 0
	wind_strength_delta = 0
	wind_dir_delta = 0

/datum/controller/subsystem/artillery_weather/proc/apply_rain(amount)
	amount = clamp(amount, 0, 1)
	humidity_delta += 0.25 * amount
	density_delta += 0.05 * amount
	wind_strength_delta += round(1 * amount)

/datum/controller/subsystem/artillery_weather/proc/apply_fog(amount)
	amount = clamp(amount, 0, 1)
	humidity_delta += 0.15 * amount
	density_delta += 0.03 * amount

/datum/controller/subsystem/artillery_weather/proc/set_wind_shift(dir_delta, strength_delta)
	wind_dir_delta += dir_delta
	wind_strength_delta += strength_delta

/// --- helpers ---
/proc/nudge_int(value, step, low, high)
	return clamp(value + rand(-step, step), low, high)

/// step is max absolute delta, e.g. 0.01 => +/-0.01
/proc/nudge_float(value, step, low, high)
	return clamp(value + (rand(-1000, 1000) / 1000) * step, low, high)

/// random walk, gated by cooldown
/datum/controller/subsystem/artillery_weather/fire(resumed)
	if(world.time < next_weather_step)
		return
	next_weather_step = world.time + weather_step_cd

	// Wind direction: small drift (+/- 0..6 degrees), not every step
	if(prob(15))
		wind_dir = (wind_dir + rand(-6, 6) + 360) % 360

	// Wind strength: small discrete wobble (-1..+1), not every step
	if(prob(15))
		wind_strength = nudge_int(wind_strength, 1, 0, ART_WIND_MAX)

	// Density: small float wobble
	if(prob(15))
		air_density = nudge_float(air_density, 0.01, 0.85, 1.15)

	// Humidity: slightly bigger wobble than density
	if(prob(15))
		humidity = nudge_float(humidity, 0.03, 0, 1)

/// --- getters ---
/datum/controller/subsystem/artillery_weather/proc/get_effective_wind_dir()
	return (wind_dir + wind_dir_delta + 360) % 360

/datum/controller/subsystem/artillery_weather/proc/get_effective_wind_strength()
	return clamp(wind_strength + wind_strength_delta, 0, ART_WIND_MAX)

/datum/controller/subsystem/artillery_weather/proc/get_effective_density()
	return clamp(air_density + density_delta, 0.7, 1.3)

/datum/controller/subsystem/artillery_weather/proc/get_effective_humidity()
	return clamp(humidity + humidity_delta, 0, 1)
