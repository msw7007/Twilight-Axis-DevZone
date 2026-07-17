/proc/formula_magic_form_rank(form_id, points)
	var/cost = formula_magic_form_unlock_level(form_id)
	if(cost <= 0)
		return max(0, points || 0)
	var/rank = 0
	var/remaining = max(0, points || 0)
	while(remaining >= cost)
		rank++
		remaining -= cost
	return rank

/proc/formula_magic_form_parent(form_id)
	switch(form_id)
		if(FORMULA_FORM_BEAM)
			return FORMULA_FORM_ORB
		if(FORMULA_FORM_NOVA)
			return FORMULA_FORM_SPIRAL
		if(FORMULA_FORM_GUIDANCE)
			return FORMULA_FORM_INSTANT
		if(FORMULA_FORM_AURA)
			return FORMULA_FORM_SUMMON
		if(FORMULA_FORM_WAVE)
			return FORMULA_FORM_TOUCH
	return null

/datum/mind/proc/can_raise_formula_magic_form(form_id, new_points)
	return TRUE

/datum/mind/proc/can_reduce_formula_magic_form(form_id, new_points)
	return TRUE

/proc/formula_magic_form_ids()
	var/list/result = list()
	for(var/datum/formula_magic_word/word as anything in get_formula_magic_word_templates())
		if(!word.school_id && word.role == FORMULA_WORD_FORM)
			result += word.id
	return result

/proc/formula_magic_form_unlock_level(form_id)
	var/datum/formula_magic_word/word = resolve_formula_magic_word(form_id)
	return max(1, word?.learn_cost || 1)

/proc/formula_magic_form_names()
	var/list/result = list()
	for(var/datum/formula_magic_word/word as anything in get_formula_magic_word_templates())
		if(!word.school_id && word.role == FORMULA_WORD_FORM)
			result[word.id] = word.name
	return result

/proc/formula_magic_school_ids()
	return list(
		FORMULA_SCHOOL_GENERAL,
		FORMULA_SCHOOL_PYROMANCY,
		FORMULA_SCHOOL_CRYOMANCY,
		FORMULA_SCHOOL_FULGURMANCY,
		FORMULA_SCHOOL_GEOMANCY,
		FORMULA_SCHOOL_KINESIS,
		FORMULA_SCHOOL_DISPLACEMENT,
		FORMULA_SCHOOL_AUGMENTATION,
		FORMULA_SCHOOL_CURSES,
		FORMULA_SCHOOL_ARTIFICE_WARDING,
		FORMULA_SCHOOL_BIOMANCY,
		FORMULA_SCHOOL_NECROMANCY,
		FORMULA_SCHOOL_CHRONOMANCY,
	)
