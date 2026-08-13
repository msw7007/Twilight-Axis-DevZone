/datum/mind/proc/formula_magic_normalized_word_list(list/word_ids)
	var/list/normalized_words = list()
	if(!islist(word_ids))
		return normalized_words
	for(var/word_id in word_ids)
		var/normalized_id = formula_magic_normalize_word_id(word_id)
		if(resolve_formula_magic_word(normalized_id))
			normalized_words += normalized_id
	return normalized_words

/datum/mind/proc/build_formula_magic_formula(list/word_ids)
	var/datum/formula_magic_formula/formula = new
	for(var/word_id in formula_magic_normalized_word_list(word_ids))
		if(!formula.add_word(word_id))
			qdel(formula)
			return null
	formula_magic_finalize_formula_power(formula)
	formula_magic_finalize_formula_limits(formula, current)
	return formula

/proc/formula_magic_finalize_formula_power(datum/formula_magic_formula/formula)
	if(!formula)
		return
	formula.power = 0
	for(var/datum/formula_magic_part/part in formula.parts)
		if(!length(part.forms))
			formula.power = max(formula.power, part.power)
			continue
		var/element_word_count = 0
		var/arcane_deepening = 0
		for(var/datum/formula_magic_word/word in part.words)
			if(word?.role != FORMULA_WORD_ELEMENT)
				continue
			if(word.id == "arcane_deepening")
				arcane_deepening += 1
				continue
			element_word_count += 1
		if(element_word_count > 0)
			part.power = max(1, FORMULA_ELEMENT_BASE_POWER + max(0, element_word_count - 1) * FORMULA_ELEMENT_REPEAT_POWER_BONUS)
		else
			part.power = max(part.power, FORMULA_ARCANE_BASE_POWER + arcane_deepening * FORMULA_ARCANE_DEEPENING_BONUS)
		formula.power = max(formula.power, part.power)

/proc/formula_magic_finalize_formula_limits(datum/formula_magic_formula/formula, mob/living/carbon/human/user)
	if(!formula)
		return
	var/list/requirements = formula_magic_requirement_metrics(formula.get_word_ids())
	var/word_units = max(0, requirements["form_units"] || 0) + max(0, requirements["element_units"] || 0) + max(0, requirements["modifier_units"] || 0)
	var/combat_armaments = user?.get_skill_level(/datum/skill/combat/arcyne) || 0
	formula.interrupt_chance = CLAMP((word_units * FORMULA_INTERRUPT_PER_WORD) + (formula.instability || 0) - (combat_armaments * FORMULA_INTERRUPT_REDUCTION_PER_ARMAMENT), 0, FORMULA_INTERRUPT_MAX)
	formula_magic_apply_intelligence_cast_speed(formula, user)

/proc/formula_magic_apply_intelligence_cast_speed(datum/formula_magic_formula/formula, mob/living/carbon/human/user)
	if(!formula)
		return
	var/multiplier = formula_magic_intelligence_cast_multiplier(formula_magic_user_intelligence(user))
	var/base_total = max(1, formula.cast_time || FORMULA_DEFAULT_WORD_DELAY)
	var/list/base_delays = formula.word_cast_times?.Copy() || list()
	if(!length(base_delays))
		formula.cast_time = max(1, round(base_total * multiplier))
		return
	var/base_delay_total = 0
	for(var/delay in base_delays)
		base_delay_total += max(1, delay || FORMULA_DEFAULT_WORD_DELAY)
	var/list/scaled_delays = list()
	var/scaled_total = 0
	for(var/delay in base_delays)
		var/weighted_delay = max(1, delay || FORMULA_DEFAULT_WORD_DELAY)
		weighted_delay = round((weighted_delay / max(1, base_delay_total)) * base_total * multiplier)
		weighted_delay = max(1, weighted_delay)
		scaled_delays += weighted_delay
		scaled_total += weighted_delay
	formula.word_cast_times = scaled_delays
	formula.cast_time = max(1, scaled_total)

/proc/formula_magic_user_intelligence(mob/living/carbon/human/user)
	if(!user)
		return 10
	return user.get_stat(STATKEY_INT)

/proc/formula_magic_intelligence_cast_multiplier(intelligence)
	if(!isnum(intelligence))
		intelligence = 10
	if(intelligence < 10)
		return 1 + ((10 - intelligence) * 0.1)
	if(intelligence > 10)
		return max(0.5, 1 - ((intelligence - 10) * 0.03))
	return 1

/proc/formula_magic_formula_slot_limit_from_intelligence(intelligence)
	if(!isnum(intelligence))
		intelligence = 10
	var/slots = 2
	if(intelligence < 10)
		return max(0, slots - (10 - intelligence))
	if(intelligence <= 15)
		return slots + ((intelligence - 10) * 2)
	return slots + 10 + ((intelligence - 15) * 3)

/proc/formula_magic_requirement_metrics(list/word_ids)
	var/list/word_counts = list()
	var/list/form_counts = list()
	var/list/school_counts = list()
	var/list/requirements = list()
	var/list/words = list()
	var/form_units = 0
	var/element_units = 0
	var/modifier_units = 0
	var/form_quarters = 0
	var/element_quarters = 0
	var/modifier_quarters = 0
	if(islist(word_ids))
		for(var/word_id in word_ids)
			var/normalized_id = formula_magic_normalize_word_id(word_id)
			var/datum/formula_magic_word/word = resolve_formula_magic_word(normalized_id)
			if(!word)
				continue
			words += normalized_id
			word_counts[normalized_id] = (word_counts[normalized_id] || 0) + 1
			switch(word.role)
				if(FORMULA_WORD_FORM)
					form_counts[normalized_id] = (form_counts[normalized_id] || 0) + 1
				if(FORMULA_WORD_ELEMENT)
					element_units += 1
					element_quarters += FORMULA_ELEMENT_LIMIT_QUARTERS
					if(word.school_id)
						school_counts[word.school_id] = (school_counts[word.school_id] || 0) + 1
				if(FORMULA_WORD_MODIFIER)
					modifier_units += 1
					if(normalized_id == "shrapnel")
						modifier_quarters += FORMULA_SHRAPNEL_LIMIT_QUARTERS
					else
						modifier_quarters += FORMULA_MODIFIER_LIMIT_QUARTERS
	var/list/resolved_form_counts = form_counts.Copy()
	form_units += formula_magic_consume_limit_form_pair(resolved_form_counts, FORMULA_FORM_ORB, FORMULA_FORM_WAVE)
	form_units += formula_magic_consume_limit_form_pair(resolved_form_counts, FORMULA_FORM_TOUCH, FORMULA_FORM_NOVA)
	form_units += formula_magic_consume_limit_form_pair(resolved_form_counts, FORMULA_FORM_INSTANT, FORMULA_FORM_BEAM)
	form_units += formula_magic_consume_limit_form_pair(resolved_form_counts, FORMULA_FORM_SPIRAL, FORMULA_FORM_AURA)
	form_units += formula_magic_consume_limit_form_pair(resolved_form_counts, FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE)
	for(var/form_id in resolved_form_counts)
		form_units += max(0, resolved_form_counts[form_id] || 0)
	form_quarters = form_units * FORMULA_FORM_LIMIT_QUARTERS
	var/arcane_required = 0
	if(length(words))
		arcane_required = max(
			CEILING(form_quarters / FORMULA_WORD_LIMIT_QUARTERS, 1),
			CEILING(element_quarters / FORMULA_WORD_LIMIT_QUARTERS, 1),
			CEILING(modifier_quarters / FORMULA_WORD_LIMIT_QUARTERS, 1)
		)
		arcane_required = max(1, arcane_required)
	for(var/word_id in word_counts)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word || word.role == FORMULA_WORD_MODIFIER)
			continue
		requirements += "[word.name] [word_counts[word_id]]"
	if(arcane_required)
		requirements += "Arcane [arcane_required]"
		requirements += "Reading [arcane_required]"
	return list(
		"words" = words,
		"requirements" = requirements,
		"arcane_required" = arcane_required,
		"reading_required" = arcane_required,
		"word_counts" = word_counts,
		"form_counts" = form_counts,
		"school_counts" = school_counts,
		"form_units" = form_units,
		"element_units" = element_units,
		"modifier_units" = modifier_units,
		"form_quarters" = form_quarters,
		"element_quarters" = element_quarters,
		"modifier_quarters" = modifier_quarters,
	)

/proc/formula_magic_consume_limit_form_pair(list/form_counts, first_form, second_form)
	if(!form_counts)
		return 0
	var/count = min(form_counts[first_form] || 0, form_counts[second_form] || 0)
	if(count <= 0)
		return 0
	form_counts[first_form] = max(0, (form_counts[first_form] || 0) - count)
	form_counts[second_form] = max(0, (form_counts[second_form] || 0) - count)
	return count

/proc/formula_magic_formula_cooldown_time(list/word_ids)
	return max(3 SECONDS, max(1, length(word_ids)) * 2 SECONDS)

/datum/mind/proc/build_formula_magic_raw_formula(list/word_ids)
	return build_formula_magic_formula(word_ids)

/datum/mind/proc/validate_formula_magic_formula(datum/formula_magic_formula/formula, feedback = FALSE)
	if(!formula || !formula.can_resolve())
		return FALSE
	var/list/requirements = formula_magic_requirement_metrics(formula.get_word_ids())
	if(!formula_magic_committed || formula_magic_has_unsaved_progression())
		if(feedback && current)
			to_chat(current, span_warning("I have not fixed this formula knowledge yet."))
		return FALSE
	ensure_formula_magic_progression()
	var/arcane_required = requirements["arcane_required"] || 0
	if((current?.get_skill_level(/datum/skill/magic/arcane) || 0) < arcane_required)
		if(feedback && current)
			to_chat(current, span_warning("I need Arcane [arcane_required] to hold this formula."))
		return FALSE
	if(current?.max_stamina && formula.mana_cost > current.max_stamina)
		if(feedback && current)
			to_chat(current, span_warning("I do not have enough mana for this formula."))
		return FALSE
	var/list/word_counts = list()
	for(var/datum/formula_magic_word/word in formula.words)
		word_counts[word.id] = (word_counts[word.id] || 0) + 1
		if(word.role == FORMULA_WORD_MODIFIER)
			continue
		if(word.role == FORMULA_WORD_FORM)
			if(formula_magic_form_rank(word.id, formula_magic_form_points[word.id] || 0) >= (word_counts[word.id] || 0))
				continue
			if(feedback && current)
				to_chat(current, span_warning("I have not fixed enough knowledge for [word.name]."))
			return FALSE
		if(word.school_id)
			if((formula_magic_known_words[word.id] || 0) >= (word_counts[word.id] || 0))
				continue
			if(feedback && current)
				to_chat(current, span_warning("I have not learned enough of [word.name]."))
			return FALSE
	return TRUE

/datum/mind/proc/validate_formula_magic_word_list(list/word_ids, feedback = FALSE)
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(word_ids)
	var/valid = validate_formula_magic_formula(formula, feedback)
	var/list/requirements = formula_magic_requirement_metrics(word_ids)
	var/list/missing = formula_magic_validation_missing(formula, requirements)
	var/max_mana = current?.max_stamina || 0
	qdel(formula)
	return list(
		"valid" = valid,
		"reason" = valid ? "" : (length(missing) ? missing[1] : "Needs at least one form or fixed formula."),
		"arcane_required" = requirements["arcane_required"],
		"reading_required" = requirements["reading_required"],
		"requirements" = requirements["requirements"],
		"missing" = missing,
		"max_mana" = max_mana,
	)

/datum/mind/proc/formula_magic_validation_missing(datum/formula_magic_formula/formula, list/requirements)
	var/list/missing = list()
	if(!formula || !formula.can_resolve())
		missing += "Needs at least one form or fixed formula"
	if(!formula_magic_committed || formula_magic_has_unsaved_progression())
		missing += "Save Knowledge"
	var/arcane_required = requirements["arcane_required"] || 0
	var/arcane_level = current?.get_skill_level(/datum/skill/magic/arcane) || 0
	if(arcane_level < arcane_required)
		missing += "Arcane [arcane_level]/[arcane_required]"
	var/max_mana = current?.max_stamina || 0
	if(max_mana && formula?.mana_cost > max_mana)
		missing += "Mana [formula.mana_cost]/[max_mana]"
	ensure_formula_magic_progression()
	var/list/seen_counts = list()
	if(formula)
		for(var/datum/formula_magic_word/word in formula.words)
			seen_counts[word.id] = (seen_counts[word.id] || 0) + 1
			if(word.role == FORMULA_WORD_MODIFIER)
				continue
			if(word.role == FORMULA_WORD_FORM)
				var/known_form_rank = formula_magic_form_rank(word.id, formula_magic_form_points[word.id] || 0)
				if(known_form_rank < (seen_counts[word.id] || 0))
					missing += "[word.name] [known_form_rank]/[seen_counts[word.id]]"
				continue
			if(word.school_id)
				var/known_word_rank = formula_magic_known_words[word.id] || 0
				if(known_word_rank < (seen_counts[word.id] || 0))
					missing += "[word.name] [known_word_rank]/[seen_counts[word.id]]"
	return missing

/datum/mind/proc/get_formula_magic_arcane_requirement(list/word_ids)
	var/list/requirements = formula_magic_requirement_metrics(word_ids)
	return requirements["arcane_required"] || 0

/datum/mind/proc/get_formula_magic_formula_requirements(list/word_ids)
	return formula_magic_requirement_metrics(word_ids)
