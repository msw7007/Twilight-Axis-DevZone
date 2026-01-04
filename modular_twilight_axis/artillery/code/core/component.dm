/datum/component/artillery_fire_control
	/// optional: cache atmo ref (но не храни навсегда если хочешь поддержать замену)
	var/datum/artillery_atmosphere/atmo

	Initialize()
		. = ..()
		atmo = ensure_artillery_atmo()
		if(!parent)
			return COMPONENT_INCOMPATIBLE

		RegisterSignal(parent, COMSIG_ARTILLERY_FIRE, PROC_REF(on_fire))
		return COMPONENT_SUCCESS

	Destroy()
		if(parent)
			UnregisterSignal(parent, COMSIG_ARTILLERY_FIRE)
		return ..()

/datum/component/artillery_fire_control/proc/on_fire(obj/structure/artillery/mortar/M, mob/living/user, aim_azimuth, powder_measures, obj/item/artillery_shell/shell, powder_quality, powder_moisture)
	SIGNAL_HANDLER

	// гарантируем что датум есть (на случай если кто-то удалил)
	atmo = ensure_artillery_atmo()

	if(!M || !user || !shell || powder_measures <= 0)
		return

	// --- INTEGRATION: статы/скиллы ---
	var/ranged = get_ranged_skill(user)
	var/pers = get_pers_stat(user)

	// --- безопасность: safe max из пушки, риск, осечка ---
	var/safe_max = M.get_safe_charge_max()
	var/burst_chance = 0
	if(powder_measures > safe_max)
		var/over = powder_measures - safe_max
		burst_chance = clamp((over * over) * 10 + M.wear + round(powder_moisture * 100), 0, 95)

	var/misfire_chance = clamp(round(powder_moisture * 40) - round(ranged / 10), 0, 35)

	if(prob(burst_chance))
		M.visible_message(span_danger("[M] bursts!"))
		do_artillery_explosion(get_turf(M), 1.0)
		M.on_catastrophic_burst() // пусть пушка сама зачистит загрузку/износ
		return

	if(prob(misfire_chance))
		M.visible_message(span_warning("[M] misfires!"))
		M.on_misfire() // пусть пушка сама решит что с порохом/снарядом
		return

	// --- расчёт баллистики ---
	var/wind_dir = atmo.get_effective_wind_dir()
	var/wind_strength = atmo.get_effective_wind_strength()
	var/density = atmo.air_density + atmo.density_delta
	var/humidity = clamp(atmo.humidity + atmo.humidity_delta, 0, 1)

	var/base_force = powder_measures * powder_quality
	var/skill_force_mult = 1.0 + (ranged / 1000) // маленький бонус
	var/effective_force = base_force * skill_force_mult

	var/mass = shell.mass
	var/range_float = (effective_force / mass) * 12
	range_float *= (1.05 - (density - 1.0))
	range_float = clamp(range_float, 3, 80)

	var/cross = wind_cross_component(wind_dir, aim_azimuth) // -1..1
	var/drift_float = cross * wind_strength * 2.2 * shell.drift_mult * (10 / mass)
	drift_float = clamp(drift_float, -12, 12)

	var/scatter = shell.base_scatter
	scatter += round(humidity * 4)
	scatter += round(powder_moisture * 2)
	scatter -= round(ranged / 30)
	scatter -= round(pers / 40)
	scatter = clamp(scatter, 0, 8)

	var/turf/origin = get_turf(M)
	var/turf/impact = compute_impact(origin, aim_azimuth, round(range_float), round(drift_float), scatter)

	// --- импакт ---
	M.visible_message(span_notice("[M] fires!"))
	do_artillery_explosion(impact, shell.blast_mult)

	// --- пост-эффекты на пушку ---
	M.on_successful_fire(base_force)

/datum/component/artillery_fire_control/proc/compute_impact(turf/origin, azimuth, range_tiles, drift_tiles, scatter)
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
