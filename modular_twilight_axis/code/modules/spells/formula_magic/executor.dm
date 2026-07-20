/datum/mind/proc/perform_formula_magic_cast(mob/living/carbon/human/caster, list/word_ids, atom/cast_on, speak_words = TRUE, atom/guidance_start)
	if(!caster)
		return FALSE
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(word_ids)
	if(!formula || !validate_formula_magic_formula(formula, TRUE))
		qdel(formula)
		return FALSE
	var/list/formula_words = formula.get_word_ids()
	var/datum/formula_magic_combo_formula/contaminated_combo = formula.combo_formula ? null : formula_magic_find_contained_combo_formula(formula_words)
	var/datum/formula_magic_context/context = new
	context.caster = caster
	context.cast_on = cast_on
	context.source_turf = get_turf(caster)
	context.target_turf = get_turf(cast_on) || context.source_turf
	if(contaminated_combo)
		. = formula_magic_detonate_formula_part(caster, formula.parts[1], "[contaminated_combo.name] contamination")
		qdel(context)
		qdel(formula)
		return
	if(formula.combo_formula)
		. = formula.combo_formula.execute(context, formula)
		qdel(context)
		qdel(formula)
		return
	var/resolved = FALSE
	for(var/datum/formula_magic_part/part in formula.parts)
		if(part.execute(context))
			resolved = TRUE
	qdel(context)
	qdel(formula)
	return resolved

/proc/formula_magic_execute_part(datum/formula_magic_context/context, datum/formula_magic_part/part)
	if(!context?.caster || !part || !length(part.forms))
		return FALSE
	var/list/form_counts = formula_magic_part_form_counts(part)
	var/resolved = FALSE
	var/seeker_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_ORB, FORMULA_FORM_WAVE)
	if(seeker_count > 0 && formula_magic_cast_shape(context, part, "seeker", 1))
		resolved = TRUE
	var/breath_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_TOUCH, FORMULA_FORM_NOVA)
	if(breath_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_BREATH, 1))
		resolved = TRUE
	var/meteor_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_INSTANT, FORMULA_FORM_BEAM)
	if(meteor_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_FALL, 1))
		resolved = TRUE
	var/cloak_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_SPIRAL, FORMULA_FORM_AURA)
	if(cloak_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_CLOAK, 1))
		resolved = TRUE
	var/rune_count = formula_magic_consume_part_form_pair(form_counts, FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE)
	if(rune_count > 0 && formula_magic_cast_shape(context, part, FORMULA_FORM_RUNE, 1))
		resolved = TRUE
	if(formula_magic_remaining_part_form_type_count(form_counts) > 1)
		return formula_magic_detonate_formula_part(context.caster, part, "unjoined forms")
	for(var/form_id in form_counts)
		var/count = form_counts[form_id] || 0
		if(count > 0 && formula_magic_cast_shape(context, part, form_id, 1))
			resolved = TRUE
	return resolved

/proc/formula_magic_part_form_counts(datum/formula_magic_part/part)
	var/list/result = list()
	for(var/form_id in part?.forms)
		result[form_id] = (result[form_id] || 0) + 1
	return result

/proc/formula_magic_consume_part_form_pair(list/form_counts, first_form, second_form)
	if(!form_counts)
		return 0
	var/count = min(form_counts[first_form] || 0, form_counts[second_form] || 0)
	if(count <= 0)
		return 0
	form_counts[first_form] -= count
	form_counts[second_form] -= count
	return count

/proc/formula_magic_part_count_form(datum/formula_magic_part/part, form_id)
	if(!part || !form_id)
		return 0
	var/count = 0
	for(var/current_form in part.forms)
		if(current_form == form_id)
			count++
	return count

/proc/formula_magic_consume_same_part_form_pair(list/form_counts, form_id)
	if(!form_counts)
		return 0
	var/count = round((form_counts[form_id] || 0) / 2)
	if(count <= 0)
		return 0
	form_counts[form_id] -= count * 2
	return count

/proc/formula_magic_remaining_part_form_type_count(list/form_counts)
	var/count = 0
	for(var/form_id in form_counts)
		if((form_counts[form_id] || 0) > 0)
			count++
	return count

/proc/formula_magic_detonate_formula_part(mob/living/carbon/human/caster, datum/formula_magic_part/part, reason, blast_radius = 1)
	if(!caster || !part)
		return FALSE
	var/turf/center = get_turf(caster)
	if(!center)
		return FALSE
	var/toxin_force = max(1, part.mana_cost || 1)
	var/splash_toxin = max(1, round(toxin_force * 0.25))
	var/knockback = max(1, length(part.words))
	caster.visible_message(span_danger("[caster]'s formula detonates from [reason || "instability"], blooming into sickly green flame!"), span_userdanger("My formula detonates from [reason || "instability"]!"))
	caster.adjustToxLoss(toxin_force)
	var/turf/caster_throw_target = get_ranged_target_turf(caster, turn(caster.dir, 180), knockback)
	if(caster_throw_target)
		caster.safe_throw_at(caster_throw_target, knockback, 1, caster, force = MOVE_FORCE_STRONG)
	for(var/turf/T in range(max(0, blast_radius || 0), center))
		new /obj/effect/temp_visual/fire/shortduration/formula_magic_toxic(T)
		for(var/mob/living/L in T)
			if(L == caster)
				continue
			L.adjustToxLoss(splash_toxin)
			var/push_dir = get_dir(center, L) || pick(NORTH, SOUTH, EAST, WEST)
			var/turf/throw_target = get_ranged_target_turf(L, push_dir, knockback)
			if(throw_target)
				L.safe_throw_at(throw_target, knockback, 1, caster, force = MOVE_FORCE_STRONG)
	return TRUE


/proc/formula_magic_part_incompatible_modifier(datum/formula_magic_part/part, form_id)
	return formula_magic_validate_shape(part, form_id)

/proc/formula_magic_part_modifier_count(datum/formula_magic_part/part, modifier_id)
	if(!part || !modifier_id)
		return 0
	return max(0, part.tags[modifier_id] || 0)

/proc/formula_magic_part_form_repeat_count(datum/formula_magic_part/part, form_id)
	return max(0, formula_magic_part_count_form(part, form_id))


/proc/formula_magic_part_power(datum/formula_magic_part/part, form_id)
	if(!part)
		return 0
	var/multiplier = 1
	switch(form_id)
		if(FORMULA_FORM_ORB)
			multiplier = 1
		if(FORMULA_FORM_TOUCH)
			multiplier = 1.2
		if(FORMULA_FORM_INSTANT)
			multiplier = 0.9
		if(FORMULA_FORM_BEAM)
			multiplier = 0.7
		if(FORMULA_FORM_SUMMON)
			multiplier = 0.6
		if(FORMULA_FORM_WAVE)
			multiplier = 0.65
		if(FORMULA_FORM_SPIRAL)
			multiplier = 0.5
		if(FORMULA_FORM_AURA)
			multiplier = 0
		if(FORMULA_FORM_GUIDANCE)
			multiplier = 0.8
		if(FORMULA_FORM_NOVA)
			multiplier = 0.6
		if(FORMULA_FORM_BREATH)
			multiplier = 0.4
		if(FORMULA_FORM_CLOAK)
			multiplier = 0.1
		if(FORMULA_FORM_FALL)
			multiplier = 1
		if(FORMULA_FORM_RUNE)
			multiplier = 0.8
	return max(0, round((part.power || 0) * multiplier))
