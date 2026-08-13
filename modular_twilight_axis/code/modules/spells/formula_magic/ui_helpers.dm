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

/proc/formula_magic_combo_form_entries()
	return list(
		list(FORMULA_FORM_ORB, FORMULA_FORM_WAVE, "Seeker"),
		list(FORMULA_FORM_TOUCH, FORMULA_FORM_NOVA, "Breath"),
		list(FORMULA_FORM_INSTANT, FORMULA_FORM_BEAM, "Fall"),
		list(FORMULA_FORM_SPIRAL, FORMULA_FORM_AURA, "Cloak"),
		list(FORMULA_FORM_SUMMON, FORMULA_FORM_GUIDANCE, "Rune"),
	)

/proc/formula_magic_combo_names_for_form_ids(list/form_ids)
	var/list/result = list()
	if(!length(form_ids))
		return result
	var/list/counts = list()
	for(var/form_id in form_ids)
		counts[form_id] = (counts[form_id] || 0) + 1
	for(var/list/entry as anything in formula_magic_combo_form_entries())
		var/first_form = entry[1]
		var/second_form = entry[2]
		var/name = entry[3]
		if(min(counts[first_form] || 0, counts[second_form] || 0) > 0)
			result += name
	return result

/proc/formula_magic_display_text_for_word_ids(list/word_ids)
	var/list/form_ids = list()
	var/list/non_form_names = list()
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word)
			continue
		if(word.role == FORMULA_WORD_FORM)
			form_ids += word.id
		else
			non_form_names += word.name
	var/list/combo_names = formula_magic_combo_names_for_form_ids(form_ids)
	if(length(combo_names))
		non_form_names += combo_names
		return jointext(non_form_names, " + ")
	var/list/names = list()
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(word)
			names += word.name
	return jointext(names, " + ")

/proc/formula_magic_display_parts(list/word_ids)
	var/list/normalized_word_ids = formula_magic_normalized_word_sequence(word_ids)
	var/datum/formula_magic_combo_formula/fixed_combo = formula_magic_find_exact_combo_formula(normalized_word_ids)
	if(fixed_combo)
		var/list/indexes = list()
		for(var/i in 1 to length(normalized_word_ids))
			indexes += i
		return list(list("name" = fixed_combo.name, "words" = normalized_word_ids, "indexes" = indexes, "combo" = TRUE))
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
	var/list/combo_display_names = formula_magic_combo_names_for_form_ids(form_ids)
	var/display_name = length(combo_display_names) ? formula_magic_display_text_for_word_ids(words) : jointext(names, " + ")
	return list(list("name" = display_name, "words" = words, "indexes" = indexes, "combo" = length(combo_display_names) > 0))
