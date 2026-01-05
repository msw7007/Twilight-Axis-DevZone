// artillery_explosions.dm

/// power: 0.1..~8 (твоя шкала)
/// По смыслу соответствует “мощности”, которую мы переводим в радиусы/интенсивности.
/proc/do_artillery_explosion(turf/impact, power)
	if(!impact)
		return

	// power: условная шкала. Подгони в тестах.
	// Я исхожу из того, что 1.0 = маленький бабах, 4.0 = уже страшно.
	power = clamp(power, 0.1, 8.0)

	// ---- маппинг на exp_* как у fireball ----
	// heavy/light/flash/fire — это по смыслу ровно их система.
	var/exp_heavy = clamp(round(power * 0.60), 0, 6)
	var/exp_light = clamp(round(power * 1.20), 1, 10)
	var/exp_flash = clamp(round(power * 0.90), 0, 6)
	var/exp_fire  = clamp(round(power * 0.80), 0, 8)

	// ---- И ВОТ ТУТ МАГИЯ: тот же explosion(), что и у fireball ----
	explosion(
		impact,
		ART_EXPLOSION_DEVASTATION,
		exp_heavy,
		exp_light,
		exp_flash,
		0,
		flame_range = exp_fire,
		soundin = GLOB.artillery_explode_sounds
	)

/proc/do_powder_detonation(turf/T, ounces, potency = 1.0)
	if(!T || ounces <= 0)
		return

	potency = clamp(potency, 0.5, 2.0)

	// 25 oz = хлопок, 150 = серьёзно, 300 = ужас
	var/power = clamp((ounces * potency) / 75, 0.2, 4.0)

	if(hascall(T, "hotspot_expose"))
		T.hotspot_expose(1000, 50)

	do_artillery_explosion(T, power)

/obj/effect/temp_visual/artillery_launch
	name = "launch plume"
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "mortar_launch" // сделай спрайт
	layer = EFFECTS_LAYER
	plane = GAME_PLANE
	duration = 8

/obj/effect/temp_visual/artillery_launch/Initialize(mapload)
	. = ..()
	pixel_y = 0
	alpha = 255
	// “улетает вверх”
	animate(src, pixel_y = 24, alpha = 0, time = duration, easing = SINE_EASING)
	return .

/obj/effect/temp_visual/artillery_fall
	name = "falling shell trail"
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "mortar_fall" // сделай спрайт
	layer = EFFECTS_LAYER
	plane = GAME_PLANE
	duration = 6

/obj/effect/temp_visual/artillery_fall/Initialize(mapload)
	. = ..()
	pixel_y = 24
	alpha = 0
	// “падает вниз” (проявляется и падает)
	animate(src, alpha = 255, time = 2, easing = LINEAR_EASING)
	animate(src, pixel_y = 0, time = duration, easing = SINE_EASING)
	return .

/obj/effect/temp_visual/artillery_tracer
	name = "shell trail"
	icon = 'modular_twilight_axis/artillery/icons/artillery.dmi'
	icon_state = "mortar_tracer" // сделай спрайт/полоску/точку
	layer = EFFECTS_LAYER
	plane = GAME_PLANE
	duration = 4

/obj/effect/temp_visual/artillery_tracer/Initialize(mapload)
	. = ..()
	alpha = 220
	pixel_y = 16
	animate(src, alpha = 0, pixel_y = 24, time = duration, easing = SINE_EASING)
	return .

/proc/art_is_openspace(turf/T)
	if(!T)
		return FALSE
	if(istype(T, ART_TURF_OPENSPACE))
		return TRUE
	return FALSE

/proc/art_get_above(turf/T)
	if(!T || T.z >= world.maxz)
		return null
	return locate(T.x, T.y, T.z + 1)

/proc/art_get_below(turf/T)
	if(!T || T.z <= 1)
		return null
	return locate(T.x, T.y, T.z - 1)

/// "Есть ли что-то над тайлом" в смысле вертикального прохода.
/// Если above существует и это НЕ openspace -> считаем, что сверху закрыто потолком.
/proc/art_has_ceiling_above(turf/T)
	var/turf/A = art_get_above(T)
	if(!A)
		return FALSE
	return !art_is_openspace(A)

/// Подгоняем Z точки импакта:
/// 1) если над точкой есть потолок — "удар в потолок" -> перенос на A (вверх на 1)
/// 2) если сама точка — openspace/пустота — перенос вниз до первого не-openspace
/proc/art_adjust_impact_z(turf/impact)
	if(!impact)
		return null

	// 1) Ceiling above -> explode above (hit the ceiling)
	if(art_has_ceiling_above(impact))
		var/turf/A = art_get_above(impact)
		if(A)
			return A

	// 2) If impact is open air -> fall down to ground
	if(art_is_openspace(impact))
		var/turf/T = impact
		while(T && art_is_openspace(T))
			var/turf/B = art_get_below(T)
			if(!B)
				break
			T = B
		return T

	return impact
