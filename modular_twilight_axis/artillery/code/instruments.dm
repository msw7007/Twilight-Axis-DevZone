/obj/structure/artillery_instrument
	name = "instrument"
	desc = "Measures something."
	icon = 'icons/obj/artillery.dmi'
	icon_state = "instrument"

	anchored = TRUE
	density = FALSE

	/// Base measurement error in "steps"
	var/base_error = 1

/obj/structure/artillery_instrument/proc/get_error(mob/living/user)
	var/pers = get_pers_stat(user)
	// High PERS => less error. Low PERS => more error.
	// 0..100 => +2..0 roughly
	var/extra = 2 - round(pers / 50) // 0->2, 50->1, 100->0
	return max(0, base_error + extra)

/// Adds a +/- error to discrete values.
proc/apply_discrete_error(value, err, low, high)
	return clamp(value + rand(-err, err), low, high)

/// Adds a +/- percent noise for float-ish values.
proc/apply_float_error(value, err_percent)
	var/mult = (100 + rand(-err_percent, err_percent)) / 100
	return value * mult


/obj/structure/artillery_instrument/anemometer
	name = "anemometer"
	desc = "Shows wind direction and strength."
	icon_state = "anemometer"
	base_error = 1

/obj/structure/artillery_instrument/anemometer/examine(mob/user)
	. = ..()
	if(!GLOB.artillery_atmo)
		return

	var/datum/artillery_atmosphere/A = GLOB.artillery_atmo
	var/err = get_error(user)

	var/dir = (A.get_effective_wind_dir() + rand(-15 * err, 15 * err) + 360) % 360
	var/str = apply_discrete_error(A.get_effective_wind_strength(), err, 0, ART_WIND_MAX)

	. += "Wind: [dir]°; strength: [str]/[ART_WIND_MAX]."


/obj/structure/artillery_instrument/barometer
	name = "barometer"
	desc = "Shows air density (roughly)."
	icon_state = "barometer"
	base_error = 1

/obj/structure/artillery_instrument/barometer/examine(mob/user)
	. = ..()
	if(!GLOB.artillery_atmo)
		return

	var/datum/artillery_atmosphere/A = GLOB.artillery_atmo
	var/err = get_error(user)

	var/dens = apply_float_error(A.get_effective_density(), 5 * err) // +/- 5% * err
	. += "Air density factor: [round(dens, 0.01)]."


/obj/structure/artillery_instrument/hygrometer
	name = "hygrometer"
	desc = "Shows humidity."
	icon_state = "hygrometer"
	base_error = 1

/obj/structure/artillery_instrument/hygrometer/examine(mob/user)
	. = ..()
	if(!GLOB.artillery_atmo)
		return

	var/datum/artillery_atmosphere/A = GLOB.artillery_atmo
	var/err = get_error(user)

	var/h = clamp(A.get_effective_humidity() + (rand(-10 * err, 10 * err) / 100), 0, 1)
	. += "Humidity: [round(h * 100)]%."
