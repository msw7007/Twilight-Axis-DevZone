/datum/mind/proc/can_use_formula_magic_word(word_id)
	ensure_formula_magic_progression()
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word)
		return FALSE
	if(word.role == FORMULA_WORD_MODIFIER)
		return TRUE
	if(!formula_magic_committed || formula_magic_has_unsaved_progression())
		return FALSE
	if(word.role == FORMULA_WORD_FORM)
		return formula_magic_form_rank(word.id, formula_magic_form_points[word.id] || 0) > 0
	if(word.school_id)
		return (formula_magic_known_words[word.id] || 0) > 0
	return FALSE

/datum/mind/proc/know_formula_magic_word(word_id)
	ensure_formula_magic_progression()
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word)
		return FALSE
	if(word.role == FORMULA_WORD_FORM)
		return adjust_formula_magic_form_points(word_id, 1)
	if(word.role == FORMULA_WORD_MODIFIER)
		return TRUE
	if(!word.school_id || !formula_magic_committed || formula_magic_has_unsaved_progression())
		return FALSE
	if(!can_learn_formula_magic_word(word.id, TRUE))
		return FALSE
	if(get_formula_magic_word_free_slots(word) <= 0)
		return FALSE
	formula_magic_known_words[word.id] = (formula_magic_known_words[word.id] || 0) + 1
	return TRUE

/datum/mind/proc/forget_formula_magic_word(word_id)
	ensure_formula_magic_progression()
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word)
		return FALSE
	if(word.role == FORMULA_WORD_FORM)
		return adjust_formula_magic_form_points(word_id, -1)
	if(!word.school_id || !formula_magic_can_reassign || (formula_magic_known_words[word.id] || 0) <= 0)
		return FALSE
	formula_magic_known_words[word.id] = max(0, (formula_magic_known_words[word.id] || 0) - 1)
	return TRUE

/datum/mind/proc/get_formula_magic_known_word_counts()
	ensure_formula_magic_progression()
	var/list/result = formula_magic_known_words.Copy()
	for(var/form_id in formula_magic_form_points)
		result[form_id] = formula_magic_form_rank(form_id, formula_magic_form_points[form_id] || 0)
	return result


/datum/mind/proc/get_formula_magic_school_word_points(school_id)
	ensure_formula_magic_progression()
	var/used = 0
	for(var/word_id in formula_magic_known_words)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(word?.school_id == school_id)
			used += max(0, formula_magic_known_words[word_id] || 0)
	return used

/datum/mind/proc/get_formula_magic_word_free_slots(datum/formula_magic_word/word)
	ensure_formula_magic_progression()
	if(!word?.school_id)
		return 0
	return max(0, (formula_magic_school_points[word.school_id] || 0) - get_formula_magic_school_word_points(word.school_id))

/datum/mind/proc/can_learn_formula_magic_word(word_id, committed_values = FALSE)
	ensure_formula_magic_progression()
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word)
		return FALSE
	if(word.role == FORMULA_WORD_MODIFIER)
		return TRUE
	if(word.role == FORMULA_WORD_FORM)
		var/list/form_source = committed_values ? formula_magic_form_points : formula_magic_draft_form_points
		return formula_magic_form_rank(word.id, form_source[word.id] || 0) > 0
	if(!word.school_id)
		return FALSE
	var/list/school_source = committed_values ? formula_magic_school_points : formula_magic_draft_school_points
	if((school_source[word.school_id] || 0) < word.unlock_level)
		return FALSE
	for(var/required_school_id in word.required_school_points)
		if((school_source[required_school_id] || 0) < (word.required_school_points[required_school_id] || 0))
			return FALSE
	return TRUE
