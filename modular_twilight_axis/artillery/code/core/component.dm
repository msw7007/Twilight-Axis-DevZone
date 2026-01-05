// ================================================
// component_artillery_fcs.dm
// ================================================

#define COMSIG_ARTILLERY_FIRE "artillery_fire"

#define ART_CHARGE_MAX 10

/datum/component/artillery_fcs
	// config
	var/powder_capacity = ART_CHARGE_MAX
	var/keg_search_range = 1

	// cooldown
	var/next_fire_time = 0
	var/fire_cooldown = 5 SECONDS

/datum/component/artillery_fcs/Initialize()
	. = ..()
	if(!parent || !istype(parent, /obj/structure/artillery/mortar))
		return

	RegisterSignal(parent, COMSIG_ARTILLERY_FIRE, PROC_REF(on_fire))

/datum/component/artillery_fcs/Destroy()
	if(parent)
		UnregisterSignal(parent, COMSIG_ARTILLERY_FIRE)
	return ..()

/// -------------------------
/// math helpers (tile model)
/// -------------------------

/datum/component/artillery_fcs/proc/azimuth_to_step(azimuth)
	var/dx = round(cos(azimuth))
	var/dy = round(sin(azimuth))
	if(!dx && !dy)
		dx = 1
	return list(dx, dy)

/datum/component/artillery_fcs/proc/perp_step(dx, dy)
	return list(dy, -dx)

/datum/component/artillery_fcs/proc/step_n(turf/start, dx, dy, steps)
	var/turf/T = start
	for(var/i in 1 to steps)
		if(!T)
			break
		T = locate(T.x + dx, T.y + dy, T.z)
	return T

/datum/component/artillery_fcs/proc/apply_scatter(turf/origin, scatter)
	if(scatter <= 0 || !origin)
		return origin
	return locate(origin.x + rand(-scatter, scatter), origin.y + rand(-scatter, scatter), origin.z)

/// crosswind component relative to shot azimuth
/datum/component/artillery_fcs/proc/wind_cross_component(wind_dir, shot_azimuth)
	var/diff = wind_dir - shot_azimuth
	while(diff > 180)
		diff -= 360
	while(diff < -180)
		diff += 360
	return sin(diff)

/// -------------------------
/// INTEGRATION HOOKS
/// -------------------------

/datum/component/artillery_fcs/proc/get_ranged_skill(mob/living/user)
	return 0

/datum/component/artillery_fcs/proc/get_pers_stat(mob/living/user)
	return 10
/proc/do_artillery_explosion(turf/impact, power)
	return

/// -------------------------
/// Component API (called by mortar UI)
/// -------------------------

/datum/component/artillery_fcs/proc/load_powder_from_nearest_keg(mob/living/user, amount)
	var/obj/structure/artillery/mortar/M = parent
	if(!M || M.broken)
		return FALSE

	if(amount <= 0)
		return FALSE

	if(M.powder_measures >= powder_capacity)
		to_chat(user, span_warning("The mortar is already fully charged."))
		return FALSE

	var/need = min(amount, powder_capacity - M.powder_measures)

	var/obj/item/artillery_powder_keg/K = find_nearest_keg(M)
	if(!K)
		to_chat(user, span_warning("No powder keg nearby."))
		return FALSE

	var/list/taken = K.take_measures(need)
	var/q = taken[1]
	var/moist = taken[2]
	var/t = taken[3]
	if(t <= 0)
		to_chat(user, span_warning("The keg is empty."))
		return FALSE

	// Blend powder properties into mortar charge
	M.blend_powder(q, moist, t)

	to_chat(user, span_notice("Loaded [t] measures of powder from [K]."))
	if(t < need)
		to_chat(user, span_warning("The keg didn't have enough powder to load the full amount."))

	return TRUE

/datum/component/artillery_fcs/proc/find_nearest_keg(obj/structure/artillery/mortar/M)
	var/obj/item/artillery_powder_keg/best
	var/best_dist = 999

	for(var/obj/item/artillery_powder_keg/K in range(keg_search_range, M))
		var/d = get_dist(M, K)
		if(d < best_dist)
			best = K
			best_dist = d

	return best

/// -------------------------
/// fire signal handler
/// -------------------------

/datum/component/artillery_fcs/proc/on_fire(obj/structure/artillery/mortar/M, mob/living/user)
	SIGNAL_HANDLER

	if(!M || !user)
		return

	if(world.time < next_fire_time)
		to_chat(user, span_warning("The mortar needs a moment before the next shot."))
		return

	if(M.broken)
		to_chat(user, span_warning("The mortar is broken."))
		return

	if(!M.loaded_shell)
		to_chat(user, span_warning("No shell loaded."))
		return

	if(M.powder_measures <= 0)
		to_chat(user, span_warning("No powder loaded."))
		return

	next_fire_time = world.time + fire_cooldown

	// Chance that a nearby keg sympathetically detonates on firing
	try_sympathetic_keg_detonation(M, user)

	// Compute risks
	var/ranged = get_ranged_skill(user)
	var/pers = get_pers_stat(user)

	var/safe_max = M.get_safe_charge_max()
	var/burst_chance = 0

	if(M.powder_measures > safe_max)
		var/over = M.powder_measures - safe_max
		burst_chance = (over * over) * 10
		burst_chance += M.wear
		burst_chance += round(M.powder_moisture * 100)
		burst_chance = clamp(burst_chance, 0, 95)

	var/misfire_chance = clamp(round(M.powder_moisture * 40) - round(ranged / 10), 0, 35)

	if(prob(burst_chance))
		M.visible_message(span_danger("[M] catastrophically bursts!"))
		M.apply_catastrophic_burst(user)
		return

	if(prob(misfire_chance))
		M.visible_message(span_warning("[M] misfires with a dull thud!"))
		M.apply_misfire(user)
		return

	// Successful shot
	M.visible_message(span_notice("[M] fires with a thunderous boom!"))

	// Atmosphere from SS
	var/wind_dir = SSartillery_weather.get_effective_wind_dir()
	var/wind_strength = SSartillery_weather.get_effective_wind_strength()
	var/density = SSartillery_weather.get_effective_density()
	var/humidity = SSartillery_weather.get_effective_humidity()

	// Shell snapshot before we delete it
	var/obj/item/artillery_shell/S = M.loaded_shell
	var/blast_mult = S.blast_mult

	// Core math
	var/base_force = M.powder_measures * M.powder_quality
	var/skill_force_mult = 1.0 + (ranged / 1000) // +0..+10%
	var/effective_force = base_force * skill_force_mult

	var/mass = S.mass
	var/range_float = (effective_force / mass) * 12
	range_float *= (1.05 - (density - 1.0))
	range_float = clamp(range_float, 3, 80)

	var/cross = wind_cross_component(wind_dir, M.aim_azimuth)
	var/drift_float = cross * wind_strength * 2.2 * S.drift_mult * (10 / mass)
	drift_float = clamp(drift_float, -12, 12)

	var/scatter = S.base_scatter
	scatter += round(humidity * 4)
	scatter += round(M.powder_moisture * 2)
	scatter -= round(ranged / 30)
	scatter -= round(pers / 40)
	scatter = clamp(scatter, 0, 8)

	// Resolve impact turf
	var/turf/origin = get_turf(M)
	var/turf/impact = compute_impact(origin, M.aim_azimuth, round(range_float), round(drift_float), scatter)

	// Effects: chem cloud first, then explosion
	S.release_chem_cloud(impact)
	do_artillery_explosion(impact, blast_mult)

	// Consume shot
	M.consume_shot(base_force)

	// Delete shell
	qdel(S)
	M.loaded_shell = null

/datum/component/artillery_fcs/proc/compute_impact(turf/origin, azimuth, range_tiles, drift_tiles, scatter)
	if(!origin)
		return null

	var/list/fwd = azimuth_to_step(azimuth)
	var/dx = fwd[1]
	var/dy = fwd[2]

	var/list/right = perp_step(dx, dy)
	var/rx = right[1]
	var/ry = right[2]

	var/turf/T = step_n(origin, dx, dy, range_tiles)
	if(!T)
		T = origin

	if(drift_tiles)
		T = step_n(T, rx, ry, abs(drift_tiles))
		if(!T)
			T = origin

	return apply_scatter(T, scatter)

/// Chance to detonate nearby keg when firing
/datum/component/artillery_fcs/proc/try_sympathetic_keg_detonation(obj/structure/artillery/mortar/M, mob/living/user)
	var/obj/item/artillery_powder_keg/K = find_nearest_keg(M)
	if(!K)
		return

	// Tune: higher charge + higher wear => more risk
	var/chance = 2 + (M.powder_measures * 2)
	chance += round(M.wear / 20) // +0..+5
	chance = clamp(chance, 0, 25)

	if(prob(chance))
		// The keg handles its own explosion
		K.detonate(user)
