/datum/component/artillery_fcs
	var/next_fire_time = 0
	var/fire_cooldown = 5 SECONDS

/datum/component/artillery_fcs/Initialize()
	. = ..()
	if(!parent || !istype(parent, /obj/structure/artillery/mortar))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_ARTILLERY_FIRE, PROC_REF(on_fire))
	return

/datum/component/artillery_fcs/Destroy()
	if(parent)
		UnregisterSignal(parent, COMSIG_ARTILLERY_FIRE)
	return ..()

// ---- math helpers ----
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
	var/turf/last = T

	for(var/i in 1 to steps)
		if(!T)
			break

		last = T
		var/turf/next = locate(T.x + dx, T.y + dy, T.z)
		if(!next)
			break

		T = next

	return last

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

// ---- hooks ----
/datum/component/artillery_fcs/proc/get_ranged_skill(mob/living/user)
	return user.get_skill_level(/datum/skill/misc/reading)

/datum/component/artillery_fcs/proc/get_pers_stat(mob/living/user)
	return user.get_stat(STAT_PERCEPTION)

// ---- powder ignition around mortar ----
/datum/component/artillery_fcs/proc/ignite_nearby_powder(obj/structure/artillery/mortar/M)
	for(var/obj/structure/artillery/powder_barrel/B in range(1, M))
		B.detonate()

	for(var/obj/item/artillery/powder_handful/H in range(1, M))
		H.detonate()

	for(var/obj/effect/decal/cleanable/artillery_powder_spill/S in range(1, M))
		S.detonate()

/datum/component/artillery_fcs/proc/compute_impact(turf/origin, azimuth, range_tiles, drift_tiles, scatter)
	if(!origin)
		return null

	// Forward vector
	var/fx = cos(azimuth)
	var/fy = sin(azimuth)

	// Right vector
	var/rx = fy
	var/ry = -fx

	var/x = origin.x + (fx * range_tiles) + (rx * drift_tiles)
	var/y = origin.y + (fy * range_tiles) + (ry * drift_tiles)

	x = clamp(round(x), 1, world.maxx)
	y = clamp(round(y), 1, world.maxy)

	var/turf/T = locate(x, y, origin.z)
	if(!T)
		T = origin

	return apply_scatter(T, scatter)

// ---- main fire ----
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

	if(M.powder_ounces <= 0)
		to_chat(user, span_warning("No powder loaded."))
		return

	next_fire_time = world.time + fire_cooldown

	var/turf/origin = get_turf(M)
	if(!origin)
		return

	var/obj/item/artillery_shell/S = M.loaded_shell

	// RogueTown z-level check: ceiling above mortar -> boom at mortar
	if(art_has_ceiling_above(origin))
		M.visible_message(span_danger("[M] fires into the ceiling and detonates at the muzzle!"))
		ignite_nearby_powder(M)
		do_artillery_explosion(origin, S ? S.blast_mult : 1.0)
		M.apply_misfire(user)
		return

	// risks
	var/ranged = get_ranged_skill(user)
	var/pers = get_pers_stat(user)

	var/safe_max = M.get_safe_powder_max()
	var/burst_chance = 0

	if(M.powder_ounces > safe_max)
		var/over = M.powder_ounces - safe_max
		burst_chance = (over * over) / 8
		burst_chance += M.wear / 2
		burst_chance = clamp(round(burst_chance), 0, 95)

	var/misfire_chance = clamp(8 - round(ranged / 20) + round(M.wear / 25), 0, 25)

	if(prob(burst_chance))
		M.visible_message(span_danger("[M] catastrophically bursts!"))
		ignite_nearby_powder(M)
		M.apply_catastrophic_burst(user)
		return

	if(prob(misfire_chance))
		M.visible_message(span_warning("[M] misfires with a dull thud!"))
		ignite_nearby_powder(M)
		M.apply_misfire(user)
		return

	M.visible_message(span_notice("[M] fires with a thunderous boom!"))

	// Weather
	var/wind_dir = SSartillery_weather.get_effective_wind_dir()
	var/wind_strength = SSartillery_weather.get_effective_wind_strength()
	var/density = SSartillery_weather.get_effective_density()
	var/humidity = SSartillery_weather.get_effective_humidity()

	// Snapshot
	var/used_ounces = M.powder_ounces
	var/powder_pot = M.get_powder_potency_avg()

	var/blast_mult = S.blast_mult
	var/mass = S.mass

	// Elevation factor
	var/elev = clamp(M.aim_elevation, ART_ELEVATION_MIN, ART_ELEVATION_MAX)
	var/elev_factor = sin(2 * elev) // 45 -> 1.0

	// Force model
	var/base_force = used_ounces * powder_pot
	var/skill_force_mult = 1.0 + (ranged / 1000)
	var/effective_force = base_force * skill_force_mult

	var/range_float = (effective_force / mass) * ART_RANGE_K
	range_float *= elev_factor
	range_float *= (1.05 - (density - 1.0))
	range_float = clamp(range_float, 3, 80)

	var/cross = wind_cross_component(wind_dir, M.aim_azimuth)
	var/drift_float = cross * wind_strength * ART_WIND_K * S.drift_mult * (10 / mass)
	drift_float = clamp(drift_float, -12, 12)

	var/scatter = S.base_scatter
	scatter += round(humidity * 4)
	scatter -= round(ranged / 30)
	scatter -= round(pers / 40)
	scatter = clamp(scatter, 0, 8)

	var/turf/impact = compute_impact(origin, M.aim_azimuth, range_float, drift_float, scatter)
	impact = art_adjust_impact_z(impact)

	var/range_tiles = round(range_float)
	var/flight_time = get_flight_time(range_tiles)

	// Consume NOW
	M.consume_shot(used_ounces)

	// Detach shell NOW
	M.loaded_shell = null

	// FX
	spawn_launch_fx(M)
	var/pre_impact = max(flight_time - (0.4 SECONDS), 0.1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(spawn_fall_fx), impact), pre_impact)

	// HIT
	addtimer(CALLBACK(src, PROC_REF(resolve_impact), M, user, S, impact, blast_mult), flight_time)
	return

/datum/component/artillery_fcs/proc/get_flight_time(range_tiles)
	range_tiles = max(1, range_tiles)
	var/t = (0.6 SECONDS) + (range_tiles * (0.12 SECONDS))
	return clamp(t, 0.8 SECONDS, 6 SECONDS)

/// FX (оставляю минимально — как у тебя; если спрайтов нет, будет "невидимо")
/datum/component/artillery_fcs/proc/spawn_launch_fx(obj/structure/artillery/mortar/M)
	if(!M)
		return
	var/turf/origin = get_turf(M)
	if(!origin)
		return
	new /obj/effect/temp_visual/artillery_launch(origin)

/// pre-impact
/datum/component/artillery_fcs/proc/spawn_fall_fx(turf/impact)
	if(!impact)
		return
	new /obj/effect/temp_visual/artillery_fall(impact)

/// impact
/datum/component/artillery_fcs/proc/resolve_impact(obj/structure/artillery/mortar/M, mob/living/user, obj/item/artillery_shell/S, turf/impact, blast_mult)
	if(!impact)
		impact = M ? get_turf(M) : null

	if(user && !QDELETED(user))
		to_chat(user, span_notice("Impact."))

	if(S && impact)
		S.release_chem_cloud(impact)

	if(impact)
		do_artillery_explosion(impact, blast_mult)

	if(S)
		qdel(S)

/// CALCULATOR
/datum/component/artillery_fcs/proc/calc_solution_from_coords(
	mob/living/user,
	turf/mortar_turf,
	target_lat,
	target_lon,
	wind_dir,
	wind_strength,
	density,
	humidity,
	mass,
	drift_mult,
	base_scatter,
	powder_potency,
	elevation
)
	if(!mortar_turf)
		return list("ok" = FALSE, "notes" = "No mortar turf.")

	// sanitize
	wind_dir = (round(wind_dir) + 360) % 360
	wind_strength = clamp(round(wind_strength), 0, ART_WIND_MAX)
	density = clamp(density, 0.7, 1.3)
	humidity = clamp(humidity, 0, 1)

	mass = max(0.1, mass)
	drift_mult = max(0.1, drift_mult)
	base_scatter = max(0, round(base_scatter))

	powder_potency = clamp(powder_potency, 0.5, 2.0)
	elevation = clamp(round(elevation), ART_ELEVATION_MIN, ART_ELEVATION_MAX)

	var/elev_factor = sin(2 * elevation)

	// mortar true coords
	var/list/mc = SSartillery_coords.get_coords(mortar_turf)
	var/m_lat = mc[1]
	var/m_lon = mc[2]

	// delta coords
	var/dlat = target_lat - m_lat
	var/dlon = target_lon - m_lon

	// delta coords -> delta world tiles
	var/list/dw = SSartillery_coords.delta_world_from_delta_coords(dlat, dlon)
	var/dx = dw[1]
	var/dy = dw[2]

	// range in tiles
	var/range_float = sqrt(dx*dx + dy*dy)
	var/range_tiles = clamp(round(range_float), 1, 200)

	// azimuth to target (0=east, 90=north)
	var/target_az = (arctan(dy, dx) + 360) % 360

	// powder needed (inverse of on_fire range model)
	var/density_factor = max((2.05 - density), 0.25)

	// range = ( (powder*potency)/mass ) * K * elev_factor * density_factor
	// => powder = (range * mass) / (K * density_factor * elev_factor * potency)
	if(elev_factor <= 0.05)
		return list("ok" = FALSE, "notes" = "Elevation too low for a stable solution.")

	var/ideal_powder = (range_tiles * mass) / (ART_RANGE_K * density_factor * elev_factor * powder_potency)
	var/powder_needed = clamp(round(ideal_powder), 1, ART_MORTAR_POWDER_MAX)

	// aim correction iteration (crosswind)
	var/aim = target_az
	var/drift_tiles = 0.0
	for(var/i in 1 to 6)
		var/cross = wind_cross_component(wind_dir, aim)
		drift_tiles = cross * wind_strength * ART_WIND_K * drift_mult * (10 / mass)
		drift_tiles = clamp(drift_tiles, -12, 12)

		var/delta = 0.0
		if(range_tiles > 0)
			delta = arctan(drift_tiles / range_tiles)

		aim = (target_az - delta + 360) % 360

	// scatter info
	var/scatter = base_scatter + round(humidity * 4)
	scatter = clamp(scatter, 0, 8)

	return list(
		"ok" = TRUE,
		"range_tiles" = range_tiles,
		"target_azimuth" = round(target_az),
		"aim_azimuth" = round(aim),
		"powder_needed" = powder_needed,
		"drift_tiles" = round(drift_tiles, 0.1),
		"scatter" = scatter,
		"powder_potency" = round(powder_potency, 0.01),
		"elevation" = elevation
	)
