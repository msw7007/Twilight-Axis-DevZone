SUBSYSTEM_DEF(artillery_weather)
	name = "Artillery Weather"
	init_order = INIT_ORDER_DEFAULT

	/// base (roundstart)
	var/wind_dir = 0
	var/wind_strength = 0
	var/air_density = 1.0
	var/humidity = 0.0

	/// deltas from weather
	var/density_delta = 0.0
	var/humidity_delta = 0.0
	var/wind_strength_delta = 0
	var/wind_dir_delta = 0

/datum/controller/subsystem/artillery_weather/Initialize(timeofday)
	generate_roundstart()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/artillery_weather/proc/generate_roundstart()
	wind_dir = rand(0, 359)
	wind_strength = rand(0, ART_WIND_MAX)
	air_density = rand(85, 115) / 100
	humidity = rand(0, 100) / 100
	clear_weather_data()

	target_wind_dir = wind_dir
	target_wind_strength = wind_strength

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

/// Если хочешь динамику: плавно приближать ветер к цели
/datum/controller/subsystem/artillery_weather/fire(resumed)
	// пример: медленное “гуляние” ветра раз в тик
	if(prob(5))
		target_wind_dir = rand(0, 359)
	if(prob(5))
		target_wind_strength = rand(0, ART_WIND_MAX)

	// плавно двигаем
	wind_dir = (wind_dir + clamp(angle_delta(wind_dir, target_wind_dir), -2, 2) + 360) % 360
	wind_strength = clamp(wind_strength + clamp(target_wind_strength - wind_strength, -1, 1), 0, ART_WIND_MAX)

/// --- getters ---
/datum/controller/subsystem/artillery_weather/proc/get_effective_wind_dir()
	return (wind_dir + wind_dir_delta + 360) % 360

/datum/controller/subsystem/artillery_weather/proc/get_effective_wind_strength()
	return clamp(wind_strength + wind_strength_delta, 0, ART_WIND_MAX)

/datum/controller/subsystem/artillery_weather/proc/get_effective_density()
	return clamp(air_density + density_delta, 0.7, 1.3)

/datum/controller/subsystem/artillery_weather/proc/get_effective_humidity()
	return clamp(humidity + humidity_delta, 0, 1)

