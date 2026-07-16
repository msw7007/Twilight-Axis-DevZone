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

/proc/formula_magic_nearest_chain_target(mob/living/carbon/human/caster, turf/source, list/excluded)
	if(!source)
		return null
	if(!excluded)
		excluded = list()
	var/mob/living/next_target
	var/best_distance = 999
	for(var/mob/living/L in view(7, source))
		if(L == caster || (L in excluded) || QDELETED(L))
			continue
		var/distance = get_dist(source, L)
		if(distance < best_distance)
			best_distance = distance
			next_target = L
	return next_target

/proc/formula_magic_reflected_angle(turf/approach, atom/target, current_angle)
	if(!target)
		return SIMPLIFY_DEGREES((current_angle || 0) + 180)
	var/face_direction = get_dir(target, approach) || angle2dir(SIMPLIFY_DEGREES((current_angle || 0) + 180))
	var/face_angle = dir2angle(face_direction)
	var/incidence = GET_ANGLE_OF_INCIDENCE(face_angle, ((current_angle || 0) + 180))
	return SIMPLIFY_DEGREES(face_angle + incidence)

/proc/formula_magic_ricochet_start_turf(turf/approach, atom/target, new_angle)
	var/turf/impact = get_turf(target)
	if(!impact)
		return approach
	if(isliving(target))
		return impact
	if(!target.density)
		return impact
	var/turf/reflected_step = get_step(impact, angle2dir(new_angle))
	if(reflected_step && !reflected_step.density)
		return reflected_step
	if(approach && !approach.density)
		return approach
	var/turf/back_step = get_step(impact, angle2dir(SIMPLIFY_DEGREES((new_angle || 0) + 180)))
	if(back_step && !back_step.density)
		return back_step
	return impact
