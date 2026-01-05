#define ART_INSTRUMENT_TIME (3 SECONDS)
#define ART_PERS_MIN 1
#define ART_PERS_NORMAL 10
#define ART_PERS_MAX 20

/// -------------------------
/// INTEGRATION HOOKS
/// -------------------------

/// PERS range assumed 1..20
/obj/item/artillery_instrument/proc/get_pers_stat(mob/living/user)
	// INTEGRATION: replace with real stat getter
	return ART_PERS_NORMAL

/// Reading skill range assumed 0..100
/obj/item/artillery_instrument/proc/get_reading_skill(mob/living/user)
	// INTEGRATION: replace with your skill system
	return 0

/// -------------------------
/// ERROR MODEL
/// -------------------------

/// Returns "spread percent" (0..100). Your spec:
/// - PERS <= 10 => 100%
/// - PERS 20 => 0%
/// - 11..20 => linear down
/obj/item/artillery_instrument/proc/art_get_base_spread_percent(mob/living/user)
	var/pers = clamp(get_pers_stat(user), ART_PERS_MIN, ART_PERS_MAX)

	if(pers <= ART_PERS_NORMAL)
		return 100

	// pers 11..20 => 90..0
	// Example: pers=11 => (20-11)/10*100 = 90
	return round(((ART_PERS_MAX - pers) / (ART_PERS_MAX - ART_PERS_NORMAL)) * 100)

/// Reading reduces spread and blunder chance.
/// reading 0..100 => up to -35% spread (tune) and -20% blunder chance (tune)
/obj/item/artillery_instrument/proc/art_apply_reading_bonus(spread_percent, blunder_chance, mob/living/user)
	var/reading = clamp(get_reading_skill(user), 0, 100)

	var/spread_reduction = round(35 * (reading / 100))
	var/blunder_reduction = round(20 * (reading / 100))

	spread_percent = clamp(spread_percent - spread_reduction, 0, 100)
	blunder_chance = clamp(blunder_chance - blunder_reduction, 0, 100)

	return list(spread_percent, blunder_chance)

/// Chance that the measurement has a "calculation error" (not just noisy).
/// This is separate from spread.
/// Behavior idea:
/// - PERS <=10: noticeably high chance
/// - PERS 20: very low
/// Complexity increases chance (wind_dir more "mathy" than humidity).
/obj/item/artillery_instrument/proc/art_get_blunder_chance(mob/living/user, complexity = 1)
	var/pers = clamp(get_pers_stat(user), ART_PERS_MIN, ART_PERS_MAX)

	// Base: at pers=1 -> ~35%, pers=10 -> ~25%, pers=20 -> ~5%
	var/base = 0
	if(pers <= ART_PERS_NORMAL)
		base = 25 + round((ART_PERS_NORMAL - pers) * 1.2) // 10->25%, 1->~36%
	else
		base = round(25 * ((ART_PERS_MAX - pers) / (ART_PERS_MAX - ART_PERS_NORMAL))) // 11->22.., 20->0
		base = max(base, 5) // keep a tiny risk even at 20 if you want; set to 0 if you don't.

	// Complexity scales it a bit
	base += (complexity - 1) * 5
	return clamp(base, 0, 60)

/// Apply percent noise to a float-like value.
/// spread=100 means +/-100% (value can double or go near 0).
/obj/item/artillery_instrument/proc/art_apply_spread_float(value, spread_percent)
	if(spread_percent <= 0)
		return value
	var/p = rand(-spread_percent, spread_percent) / 100
	return value * (1 + p)

/// Discrete noise for integer values.
/// step_max is the maximum absolute step at spread=100.
/obj/item/artillery_instrument/proc/art_apply_spread_int(value, spread_percent, step_max, low, high)
	if(spread_percent <= 0)
		return clamp(value, low, high)

	var/step = max(1, round(step_max * (spread_percent / 100)))
	return clamp(value + rand(-step, step), low, high)

/// A "blunder" means we sometimes do something actually wrong:
/// - wind_dir: rotate by large wrong chunk (e.g. 60..180 degrees)
/// - wind_strength: off by 2..3 steps
/// - density/humidity: push with big bias
/obj/item/artillery_instrument/proc/art_apply_blunder_wind_dir(dir)
	return (dir + pick(-180, -150, -120, -90, -60, 60, 90, 120, 150, 180) + 360) % 360

/obj/item/artillery_instrument/proc/art_apply_blunder_wind_strength(str)
	return clamp(str + pick(-3, -2, 2, 3), 0, ART_WIND_MAX)

/obj/item/artillery_instrument/proc/art_apply_blunder_density(dens)
	return clamp(dens + pick(-0.12, -0.08, 0.08, 0.12), 0.7, 1.3)

/obj/item/artillery_instrument/proc/art_apply_blunder_humidity(h)
	return clamp(h + pick(-0.35, -0.25, 0.25, 0.35), 0, 1)


/// -------------------------
/// BASE INSTRUMENT
/// -------------------------

/obj/item/artillery_instrument
	name = "instrument"
	desc = "Measures something."
	icon = 'icons/fullblack.dmi'
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
	icon_state = "hygrometer"
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
	icon_state = "weather_slate"
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

