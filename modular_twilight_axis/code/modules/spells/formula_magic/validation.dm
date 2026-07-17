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
	return formula

/proc/formula_magic_finalize_formula_power(datum/formula_magic_formula/formula)
	if(!formula)
		return
	formula.power = 0
	for(var/datum/formula_magic_part/part in formula.parts)
		if(length(part.forms))
			part.power = max(part.power, 30)
		formula.power = max(formula.power, part.power)

/datum/mind/proc/build_formula_magic_raw_formula(list/word_ids)
	return build_formula_magic_formula(word_ids)

/datum/mind/proc/validate_formula_magic_formula(datum/formula_magic_formula/formula, feedback = FALSE)
	if(!formula || !formula.can_resolve())
		return FALSE
	if(!formula_magic_committed || formula_magic_has_unsaved_progression())
		if(feedback && current)
			to_chat(current, span_warning("I have not fixed this formula knowledge yet."))
		return FALSE
	ensure_formula_magic_progression()
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
	var/list/requirements = get_formula_magic_formula_requirements(word_ids)
	var/max_mana = current?.max_stamina || 0
	if(max_mana && formula?.mana_cost > max_mana)
		valid = FALSE
	qdel(formula)
	return list(
		"valid" = valid,
		"reason" = valid ? "" : "Needs at least one form or fixed formula.",
		"arcane_required" = requirements["arcane_required"],
		"reading_required" = requirements["reading_required"],
		"requirements" = requirements["requirements"],
		"max_mana" = max_mana,
	)

/datum/mind/proc/get_formula_magic_arcane_requirement(list/word_ids)
	var/list/words = formula_magic_normalized_word_list(word_ids)
	return length(words) ? 1 : 0

/datum/mind/proc/get_formula_magic_formula_requirements(list/word_ids)
	var/list/words = formula_magic_normalized_word_list(word_ids)
	var/list/word_counts = list()
	var/list/form_counts = list()
	for(var/word_id in words)
		word_counts[word_id] = (word_counts[word_id] || 0) + 1
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(word?.role == FORMULA_WORD_FORM)
			form_counts[word.id] = (form_counts[word.id] || 0) + 1
	var/list/requirements = list()
	for(var/word_id in word_counts)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word)
			continue
		if(word.role == FORMULA_WORD_MODIFIER)
			continue
		requirements += "[word.name] [word_counts[word_id]]"
	var/arcane_required = length(words) ? 1 : 0
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
		"school_counts" = list(),
	)
