/proc/formula_magic_random_living_target(mob/living/carbon/human/caster, turf/source, list/excluded)
	if(!source)
		return null
	if(!excluded)
		excluded = list()
	var/list/candidates = list()
	for(var/mob/living/L in view(7, source))
		if(L == caster || (L in excluded) || QDELETED(L))
			continue
		candidates += L
	if(!length(candidates))
		return null
	return pick(candidates)

/proc/formula_magic_random_turf_from(turf/source, radius = 5)
	if(!source)
		return null
	var/list/candidates = orange(max(1, radius || 1), source)
	if(!length(candidates))
		return source
	return pick(candidates)


/proc/formula_magic_limited_part_target(datum/formula_magic_context/context, datum/formula_magic_part/part, max_distance)
	var/turf/source = get_turf(context?.caster)
	var/turf/target = context?.target_turf
	if(!source)
		return target
	if(!target)
		target = get_ranged_target_turf(context.caster, context.caster.dir, max(1, max_distance || part?.range || 1))
	if(!target)
		return source
	max_distance = max(1, max_distance || part?.range || 1)
	if(get_dist(source, target) <= max_distance)
		return target
	var/list/line = getline(source, target)
	if(length(line) > max_distance + 1)
		return line[max_distance + 1]
	return get_ranged_target_turf(source, get_dir(source, target) || context.caster.dir, max_distance) || target

/proc/formula_magic_limited_turf_from_to(turf/source, turf/target, max_distance, fallback_dir = NORTH)
	if(!source)
		return target
	max_distance = max(1, max_distance || 1)
	if(!target || target == source)
		return get_ranged_target_turf(source, fallback_dir || NORTH, max_distance) || source
	if(get_dist(source, target) <= max_distance)
		return target
	var/list/line = getline(source, target)
	if(length(line) > max_distance + 1)
		return line[max_distance + 1]
	return formula_magic_turf_at_angle(source, Get_Angle(source, target), max_distance) || get_ranged_target_turf(source, get_dir(source, target) || fallback_dir || NORTH, max_distance) || target

/proc/formula_magic_nearest_chain_target(mob/living/carbon/human/caster, turf/source, list/excluded, max_distance = 7)
	if(!source)
		return null
	if(!excluded)
		excluded = list()
	max_distance = max(1, max_distance || 1)
	var/mob/living/next_target
	var/best_distance = 999
	for(var/mob/living/L in view(max_distance, source))
		if(L == caster || (L in excluded) || QDELETED(L))
			continue
		var/distance = get_dist(source, L)
		if(distance > max_distance)
			continue
		if(distance < best_distance)
			best_distance = distance
			next_target = L
	return next_target

/proc/formula_magic_turf_at_angle(turf/source, angle, distance)
	if(!source)
		return null
	angle = SIMPLIFY_DEGREES(angle || 0)
	distance = max(1, distance || 1)
	var/target_x = CLAMP(source.x + round(sin(angle) * distance), 1, world.maxx)
	var/target_y = CLAMP(source.y + round(cos(angle) * distance), 1, world.maxy)
	return locate(target_x, target_y, source.z)

/proc/formula_magic_step_from_angle(turf/source, angle)
	return formula_magic_turf_at_angle(source, angle, 1)

/proc/formula_magic_reflected_angle(turf/approach, atom/target, current_angle)
	if(!target)
		return SIMPLIFY_DEGREES((current_angle || 0) + 180)
	var/face_direction = get_dir(target, approach) || angle2dir(SIMPLIFY_DEGREES((current_angle || 0) + 180))
	var/face_angle = dir2angle(face_direction)
	var/incidence = GET_ANGLE_OF_INCIDENCE(face_angle, ((current_angle || 0) + 180))
	return SIMPLIFY_DEGREES(face_angle + incidence)

/proc/formula_magic_reflected_angle_from_projectile(turf/projectile_turf, atom/target, current_angle)
	if(!projectile_turf || !target)
		return SIMPLIFY_DEGREES((current_angle || 0) + 180)
	var/face_direction = get_dir(target, projectile_turf) || angle2dir(SIMPLIFY_DEGREES((current_angle || 0) + 180))
	var/face_angle = dir2angle(face_direction)
	var/incidence = GET_ANGLE_OF_INCIDENCE(face_angle, ((current_angle || 0) + 180))
	var/a_incidence = abs(incidence)
	if(a_incidence > 90 && a_incidence < 270)
		return null
	return SIMPLIFY_DEGREES(face_angle + incidence)

/proc/formula_magic_ricochet_start_turf(turf/approach, atom/target, new_angle)
	var/turf/impact = get_turf(target)
	if(!impact)
		return approach
	if(isliving(target))
		return impact
	if(!target.density)
		return impact
	var/turf/reflected_step = formula_magic_step_from_angle(impact, new_angle)
	if(reflected_step && !reflected_step.density)
		return reflected_step
	if(approach && !approach.density)
		return approach
	var/turf/back_step = formula_magic_step_from_angle(impact, SIMPLIFY_DEGREES((new_angle || 0) + 180))
	if(back_step && !back_step.density)
		return back_step
	return impact

/proc/formula_magic_circle_turfs(turf/center, radius)
	var/list/result = list()
	if(!center)
		return result
	radius = max(0, min(radius || 0, 8))
	if(radius <= 0)
		result += center
		return result
	var/rsq = radius * (radius + 0.5)
	for(var/turf/T in range(radius, center))
		var/dx = T.x - center.x
		var/dy = T.y - center.y
		if(dx * dx + dy * dy <= rsq)
			result += T
	return result

/proc/formula_magic_area_turfs_for_shape(turf/center, radius, form_id)
	if(!center)
		return list()
	radius = max(0, min(radius || 0, 8))
	switch(form_id)
		if(FORMULA_FORM_ORB, FORMULA_FORM_INSTANT, FORMULA_FORM_SUMMON, FORMULA_FORM_NOVA, FORMULA_FORM_CLOAK, FORMULA_FORM_FALL)
			return formula_magic_circle_turfs(center, radius)
	return range(radius, center)
