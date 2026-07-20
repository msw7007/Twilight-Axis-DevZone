/proc/formula_magic_apply_touch_chain(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, list/excluded)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	if(chain_count <= 0 || !length(excluded))
		return FALSE
	var/list/visited = list(caster)
	visited |= excluded
	for(var/i in 1 to chain_count)
		var/mob/living/target = formula_magic_nearest_chain_target(caster, source, visited, 2)
		if(!target)
			break
		formula_magic_apply_form_payload_area(caster, part, get_turf(target), 0, max(1, round((power || part.power || 1) * 0.7)), visited, FORMULA_FORM_TOUCH)
		visited |= target
	return TRUE

/proc/formula_magic_apply_moment_ricochet(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power)
	var/ricochet_count = formula_magic_part_modifier_count(part, "ricochet")
	if(ricochet_count <= 0)
		return FALSE
	for(var/i in 1 to ricochet_count)
		var/turf/random_turf = formula_magic_random_turf_from(source, max(1, part.radius || 1))
		if(random_turf)
			formula_magic_apply_form_payload_area(caster, part, random_turf, 0, max(1, power || part.power || 1), list(caster))
	return TRUE

/proc/formula_magic_apply_moment_chain(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, list/excluded, max_distance = 7, chain_form_id = FORMULA_FORM_INSTANT)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	if(chain_count <= 0 || !length(excluded))
		return FALSE
	var/list/visited = list(caster)
	visited |= excluded
	for(var/i in 1 to chain_count)
		var/mob/living/target = formula_magic_nearest_chain_target(caster, source, visited, max_distance)
		if(!target)
			break
		formula_magic_apply_form_payload_area(caster, part, get_turf(target), 0, max(1, round((power || part.power || 1) * 0.7)), visited, chain_form_id)
		visited |= target
	return TRUE

/proc/formula_magic_apply_nova_ricochet(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, max_distance)
	var/ricochet_count = formula_magic_part_modifier_count(part, "ricochet")
	if(ricochet_count <= 0)
		return FALSE
	for(var/i in 1 to ricochet_count)
		var/turf/random_target = get_ranged_target_turf(source, pick(GLOB.alldirs), max(1, max_distance || 1))
		if(random_target)
			formula_magic_apply_form_payload_area(caster, part, random_target, 0, max(1, power || part.power || 1), list(caster))
	return TRUE

/proc/formula_magic_apply_nova_chain(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, max_distance, list/excluded, chain_form_id = FORMULA_FORM_NOVA)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	if(chain_count <= 0 || !length(excluded))
		return FALSE
	var/list/visited = list(caster)
	visited |= excluded
	for(var/i in 1 to chain_count)
		var/mob/living/target = formula_magic_nearest_chain_target(caster, source, visited, max_distance)
		if(!target || get_dist(source, target) > max(1, max_distance || 1))
			break
		formula_magic_apply_form_payload_area(caster, part, get_turf(target), 0, max(1, round((power || part.power || 1) * 0.7)), visited, chain_form_id)
		visited |= target
	return TRUE

/proc/formula_magic_apply_wave_shrapnel(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/source, power, list/excluded)
	var/shrapnel_count = formula_magic_part_modifier_count(part, "shrapnel")
	if(shrapnel_count <= 0)
		return FALSE
	return formula_magic_apply_part_area(caster, part, source, shrapnel_count, max(1, power || part.power || 1), excluded, FORMULA_FORM_NOVA)

/proc/formula_magic_apply_fall_payload(mob/living/carbon/human/caster, datum/formula_magic_part/part, turf/target, power, allow_followups = TRUE)
	if(!caster || QDELETED(caster) || !part || QDELETED(part) || !target)
		return FALSE
	var/list/result = formula_magic_apply_form_payload_area(caster, part, target, max(0, part.radius || 0), max(1, power || part.power || 1), null, FORMULA_FORM_FALL)
	var/list/affected_turfs = result["turfs"] || list()
	var/list/hit_targets = result["targets"] || list()
	formula_magic_apply_instant_existence(caster, part, affected_turfs, max(1, power || part.power || 1))
	if(!allow_followups)
		return TRUE
	var/ricochet_count = formula_magic_part_modifier_count(part, "ricochet")
	for(var/i in 1 to ricochet_count)
		var/turf/random_target = formula_magic_random_turf_from(target, 5)
		if(random_target)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_fall_payload), caster, part, random_target, power, FALSE), i * 0.5 SECONDS)
	var/chain_count = formula_magic_part_modifier_count(part, "chain")
	var/list/visited = hit_targets?.Copy() || list(caster)
	if(length(hit_targets) > 0)
		for(var/i in 1 to chain_count)
			var/mob/living/next_target = formula_magic_nearest_chain_target(caster, target, visited, 4)
			if(!next_target || get_dist(target, next_target) > 4)
				break
			visited |= next_target
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(formula_magic_apply_fall_payload), caster, part, get_turf(next_target), power, FALSE), i * 0.5 SECONDS)
	var/shrapnel_count = formula_magic_part_modifier_count(part, "shrapnel")
	if(shrapnel_count > 0)
		formula_magic_fire_orb_shrapnel(caster, target, max(1, power || part.power || 1), part.impact_damage_type, part.impact_flag, part.impact_woundclass, part.impact_intdamfactor, part.impact_color, shrapnel_count)
	return TRUE
