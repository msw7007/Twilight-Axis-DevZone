/proc/formula_magic_word_lists_match(list/left, list/right)
	if(length(left) != length(right))
		return FALSE
	for(var/i in 1 to length(left))
		if(left[i] != right[i])
			return FALSE
	return TRUE

/proc/formula_magic_school_names()
	return list(
		FORMULA_SCHOOL_GENERAL = "Neuromancy",
		FORMULA_SCHOOL_PYROMANCY = "Pyromancy",
		FORMULA_SCHOOL_CRYOMANCY = "Cryomancy",
		FORMULA_SCHOOL_FULGURMANCY = "Fulgurmancy",
		FORMULA_SCHOOL_GEOMANCY = "Geomancy",
		FORMULA_SCHOOL_KINESIS = "Kinesis",
		FORMULA_SCHOOL_DISPLACEMENT = "Displacement",
		FORMULA_SCHOOL_AUGMENTATION = "Augmentation",
		FORMULA_SCHOOL_CURSES = "Curses",
		FORMULA_SCHOOL_ARTIFICE_WARDING = "Artifice and Warding",
		FORMULA_SCHOOL_BIOMANCY = "Biomancy",
		FORMULA_SCHOOL_NECROMANCY = "Necromancy",
		FORMULA_SCHOOL_CHRONOMANCY = "Chronomancy",
	)

/proc/formula_magic_form_unlocks()
	var/list/result = list()
	for(var/form_id in formula_magic_form_ids())
		result[form_id] = formula_magic_form_unlock_level(form_id)
	return result

/proc/formula_magic_display_parts(list/word_ids)
	var/list/normalized_word_ids = formula_magic_normalized_word_sequence(word_ids)
	var/datum/formula_magic_combo_formula/fixed_combo = formula_magic_find_exact_combo_formula(normalized_word_ids)
	if(fixed_combo)
		var/list/indexes = list()
		for(var/i in 1 to length(normalized_word_ids))
			indexes += i
		return list(list("name" = fixed_combo.name, "words" = normalized_word_ids, "indexes" = indexes))
	var/list/combo_names = list(
		"[FORMULA_FORM_ORB]|[FORMULA_FORM_WAVE]" = "Seeker",
		"[FORMULA_FORM_TOUCH]|[FORMULA_FORM_NOVA]" = "Breath",
		"[FORMULA_FORM_INSTANT]|[FORMULA_FORM_BEAM]" = "Fall",
		"[FORMULA_FORM_SPIRAL]|[FORMULA_FORM_AURA]" = "Cloak",
		"[FORMULA_FORM_SUMMON]|[FORMULA_FORM_GUIDANCE]" = "Rune",
	)
	var/list/words = list()
	var/list/indexes = list()
	var/list/names = list()
	for(var/i in 1 to length(word_ids))
		var/word_id = formula_magic_normalize_word_id(word_ids[i])
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word)
			continue
		words += word_id
		indexes += i
		names += word.name
	if(!length(words))
		return list()
	var/list/form_ids = list()
	for(var/word_id in words)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(word?.role == FORMULA_WORD_FORM)
			form_ids += word.id
	var/display_name = jointext(names, " + ")
	if(length(form_ids) == 2)
		var/combo_key = "[form_ids[1]]|[form_ids[2]]"
		var/reverse_key = "[form_ids[2]]|[form_ids[1]]"
		display_name = combo_names[combo_key] || combo_names[reverse_key] || display_name
	return list(list("name" = display_name, "words" = words, "indexes" = indexes))
