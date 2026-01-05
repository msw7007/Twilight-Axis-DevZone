
/// PERS range assumed 1..20
/obj/item/artillery_instrument/proc/get_pers_stat(mob/living/user)
	return user.get_stat(STAT_PERCEPTION)

/// Reading skill range assumed 0..100
/obj/item/artillery_instrument/proc/get_reading_skill(mob/living/user)
	return user.get_skill_level(/datum/skill/misc/reading)

/obj/item/artillery_instrument/proc/art_get_base_spread_percent(mob/living/user)
	var/pers = clamp(get_pers_stat(user), ART_PERS_MIN, ART_PERS_MAX)

	// 1..10 : 25 -> 15
	if(pers <= ART_PERS_NORMAL)
		var/t = (pers - ART_PERS_MIN) / (ART_PERS_NORMAL - ART_PERS_MIN) // 0..1
		return round(25 - (10 * t)) // 25..15

	// 11..18 : 15 -> 0
	// (pers=10 => 15, pers=18 => 0)
	var/t2 = (pers - ART_PERS_NORMAL) / 8 // 10..18 => 0..1
	var/out = round(15 * (1 - t2)) // 15..0
	return clamp(out, 0, 25)

/obj/item/artillery_instrument/proc/art_get_blunder_chance(mob/living/user, complexity = 1)
	var/pers = clamp(get_pers_stat(user), ART_PERS_MIN, ART_PERS_MAX)

	// pers=1 => 12, pers=10 => 6, pers=20 => 2
	var/base
	if(pers <= ART_PERS_NORMAL)
		var/t = (pers - ART_PERS_MIN) / (ART_PERS_NORMAL - ART_PERS_MIN) // 0..1
		base = round(12 - (6 * t)) // 12..6
	else
		var/t2 = (pers - ART_PERS_NORMAL) / (ART_PERS_MAX - ART_PERS_NORMAL) // 0..1
		base = round(6 - (4 * t2)) // 6..2

	base += (complexity - 1) * 2
	return clamp(base, 0, 25)

/// Reading бонус — теперь относительный и приятный.
/// reading 0..100:
/// - spread уменьшаем до -40%
/// - blunder уменьшаем до -50% (но не ниже 0)
/obj/item/artillery_instrument/proc/art_apply_reading_bonus(spread_percent, blunder_chance, mob/living/user)
	var/reading = clamp(get_reading_skill(user), 0, 100)

	var/t = (reading - 1) / 5
	var/spread_mult = 1 - t
	var/blunder_mult = 1 - t

	spread_percent = clamp(round(spread_percent * spread_mult), 0, 100)
	blunder_chance = clamp(round(blunder_chance * blunder_mult), 0, 100)

	return list(spread_percent, blunder_chance)

/// Мягкие blunder'ы
/obj/item/artillery_instrument/proc/art_apply_blunder_wind_dir(dir)
	return (dir + pick(-45, -30, -20, 20, 30, 45) + 360) % 360

/obj/item/artillery_instrument/proc/art_apply_blunder_wind_strength(str)
	return clamp(str + pick(-2, -1, 1, 2), 0, ART_WIND_MAX)

/// density/humidity — небольшие сдвиги
/obj/item/artillery_instrument/proc/art_apply_blunder_density(dens)
	return clamp(dens + pick(-0.08, -0.05, -0.03, 0.03, 0.05, 0.08), 0.7, 1.3)

/// влажность тоже мягче
/obj/item/artillery_instrument/proc/art_apply_blunder_humidity(h)
	return clamp(h + pick(-0.20, -0.12, -0.08, 0.08, 0.12, 0.20), 0, 1)

/// мягкий blunder координат — перепутал деление/знак/цифры: сдвиг на 2..8% и/или + небольшая постоянная
/obj/item/artillery_instrument/proc/art_apply_blunder_coords(value)
	return value * pick(0.92, 0.95, 1.05, 1.08) + pick(-3, -2, 2, 3)

/// Percent noise for float-ish values.
/// spread_percent=25 => +/-25%
/// spread_percent=0 => no change
/obj/item/artillery_instrument/proc/art_apply_spread_float(value, spread_percent)
	if(spread_percent <= 0)
		return value
	var/p = rand(-spread_percent, spread_percent) / 100
	return value * (1 + p)

/// Discrete noise for integer values.
/// step_max is the maximum absolute step at spread=100.
/// Example: step_max=3, spread=15 => step=1
/obj/item/artillery_instrument/proc/art_apply_spread_int(value, spread_percent, step_max, low, high)
	if(spread_percent <= 0)
		return clamp(value, low, high)

	var/step = max(1, round(step_max * (spread_percent / 100)))
	return clamp(value + rand(-step, step), low, high)

/// -------------------------
/// BASE INSTRUMENT
/// -------------------------

/obj/item/artillery_instrument
	name = "instrument"
	desc = "Measures something."
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "instrument"

	/// how annoying/complex it is to use: affects blunder chance slightly
	var/complexity = 1

	/// read time (do_after)
	var/read_time = ART_INSTRUMENT_TIME

/obj/item/artillery_instrument/proc/read_instrument(mob/living/user)
	if(!user)
		return FALSE
	if(!do_after(user, read_time, target = src))
		return FALSE
	return TRUE

/obj/item/artillery_instrument/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	use(user)

/obj/item/artillery_instrument/use(mob/living/user)
	// overridden
	return

/// -------------------------
/// ANEMOMETER: wind dir/strength
/// -------------------------

/obj/item/artillery_instrument/anemometer
	name = "anemometer"
	desc = "Measures wind direction and strength."
	icon_state = "anemometer"
	complexity = 2

/obj/item/artillery_instrument/anemometer/use(mob/living/user)
	if(!read_instrument(user))
		return

	var/spread = art_get_base_spread_percent(user)
	var/blunder = art_get_blunder_chance(user, complexity)

	var/list/adj = art_apply_reading_bonus(spread, blunder, user)
	spread = adj[1]
	blunder = adj[2]

	var/dir = SSartillery_weather.get_effective_wind_dir()
	var/str = SSartillery_weather.get_effective_wind_strength()

	// Spread
	dir = (dir + rand(-round(30 * (spread / 100)), round(30 * (spread / 100))) + 360) % 360
	str = art_apply_spread_int(str, spread, 3, 0, ART_WIND_MAX)

	// Blunder
	if(prob(blunder))
		dir = art_apply_blunder_wind_dir(dir)
		str = art_apply_blunder_wind_strength(str)

	to_chat(user, span_notice("Wind: [dir]°; strength: [str]/[ART_WIND_MAX]."))


/// -------------------------
/// BAROMETER: density
/// -------------------------

/obj/item/artillery_instrument/barometer
	name = "barometer"
	desc = "Measures air density."
	icon_state = "barometer"
	complexity = 2

/obj/item/artillery_instrument/barometer/use(mob/living/user)
	if(!read_instrument(user))
		return

	var/spread = art_get_base_spread_percent(user)
	var/blunder = art_get_blunder_chance(user, complexity)

	var/list/adj = art_apply_reading_bonus(spread, blunder, user)
	spread = adj[1]
	blunder = adj[2]

	var/dens = SSartillery_weather.get_effective_density()

	// Spread as percent noise
	dens = art_apply_spread_float(dens, spread)

	// Blunder
	if(prob(blunder))
		dens = art_apply_blunder_density(dens)

	to_chat(user, span_notice("Air density factor: [round(dens, 0.01)]."))


/// -------------------------
/// HYGROMETER: humidity
/// -------------------------

/obj/item/artillery_instrument/hygrometer
	name = "hygrometer"
	desc = "Measures humidity."
	icon_state = "thermometr"
	complexity = 1

/obj/item/artillery_instrument/hygrometer/use(mob/living/user)
	if(!read_instrument(user))
		return

	var/spread = art_get_base_spread_percent(user)
	var/blunder = art_get_blunder_chance(user, complexity)

	var/list/adj = art_apply_reading_bonus(spread, blunder, user)
	spread = adj[1]
	blunder = adj[2]

	var/h = SSartillery_weather.get_effective_humidity()

	// Spread
	h = art_apply_spread_float(h, spread)

	// Blunder
	if(prob(blunder))
		h = art_apply_blunder_humidity(h)

	to_chat(user, span_notice("Humidity: [round(clamp(h, 0, 1) * 100)]%."))


/// -------------------------
/// OPTIONAL: Combined "weather slate" that reads all at once
/// (useful for артиллеристов)
/// -------------------------

/obj/item/artillery_instrument/weather_slate
	name = "weather slate"
	desc = "A combined kit for wind, density, and humidity."
	icon_state = "anemometer"
	complexity = 3
	read_time = 4 SECONDS

/obj/item/artillery_instrument/weather_slate/use(mob/living/user)
	if(!read_instrument(user))
		return

	var/spread = art_get_base_spread_percent(user)
	var/blunder = art_get_blunder_chance(user, complexity)

	var/list/adj = art_apply_reading_bonus(spread, blunder, user)
	spread = adj[1]
	blunder = adj[2]

	var/dir = SSartillery_weather.get_effective_wind_dir()
	var/str = SSartillery_weather.get_effective_wind_strength()
	var/dens = SSartillery_weather.get_effective_density()
	var/h = SSartillery_weather.get_effective_humidity()

	// Spread
	dir = (dir + rand(-round(30 * (spread / 100)), round(30 * (spread / 100))) + 360) % 360
	str = art_apply_spread_int(str, spread, 3, 0, ART_WIND_MAX)
	dens = art_apply_spread_float(dens, spread)
	h = art_apply_spread_float(h, spread)

	// Blunder: if it triggers, it can corrupt one or several readings
	if(prob(blunder))
		switch(rand(1, 4))
			if(1) dir = art_apply_blunder_wind_dir(dir)
			if(2) str = art_apply_blunder_wind_strength(str)
			if(3) dens = art_apply_blunder_density(dens)
			if(4) h = art_apply_blunder_humidity(h)

	to_chat(user, span_notice("Wind: [dir]°; strength: [str]/[ART_WIND_MAX]."))
	to_chat(user, span_notice("Air density factor: [round(dens, 0.01)]."))
	to_chat(user, span_notice("Humidity: [round(clamp(h, 0, 1) * 100)]%."))

/obj/item/artillery_instrument/compass
	name = "compass"
	desc = "A surveyor's compass. Click a location to read its latitude/longitude."
	icon_state = "compass"
	complexity = 2
	var/compass_range = 20

/obj/item/artillery_instrument/compass/afterattack(atom/target, mob/user, proximity, params)
	. = ..()
	if(!isliving(user))
		return
	var/mob/living/L = user

	if(!target)
		return

	var/turf/T = get_turf(target)
	if(!T)
		return

	if(get_dist(L, T) > compass_range)
		to_chat(L, span_warning("Too far to get a reading."))
		return

	if(!(T in view(compass_range, L)))
		to_chat(L, span_warning("No line of sight to that location."))
		return

	if(!read_instrument(L))
		return

	var/spread = art_get_base_spread_percent(L)
	var/blunder = art_get_blunder_chance(L, complexity)

	var/list/adj = art_apply_reading_bonus(spread, blunder, L)
	spread = adj[1]
	blunder = adj[2]

	var/list/true_coords = SSartillery_coords.get_coords(T)
	var/lat = true_coords[1]
	var/lon = true_coords[2]

	// apply spread to offset-relative components, not absolute values
	var/lat_u = lat - SSartillery_coords.offset_lat
	var/lon_u = lon - SSartillery_coords.offset_lon

	lat_u = art_apply_spread_float(lat_u, spread)
	lon_u = art_apply_spread_float(lon_u, spread)

	lat = lat_u + SSartillery_coords.offset_lat
	lon = lon_u + SSartillery_coords.offset_lon

	if(prob(blunder))
		lat = art_apply_blunder_coords(lat)
		lon = art_apply_blunder_coords(lon)

	to_chat(L, span_notice("Coords: φ=[round(lat, 0.01)], λ=[round(lon, 0.01)]"))
