/datum/mind/proc/ensure_formula_magic_progression()
	if(!formula_magic_school_points)
		formula_magic_school_points = list()
	if(!formula_magic_draft_school_points)
		formula_magic_draft_school_points = formula_magic_school_points.Copy()
	if(!formula_magic_form_points)
		formula_magic_form_points = list()
	if(!formula_magic_draft_form_points)
		formula_magic_draft_form_points = formula_magic_form_points.Copy()
	if(!formula_magic_known_words)
		formula_magic_known_words = list()
	for(var/school_id in formula_magic_school_ids())
		if(isnull(formula_magic_school_points[school_id]))
			formula_magic_school_points[school_id] = 0
		if(isnull(formula_magic_draft_school_points[school_id]))
			formula_magic_draft_school_points[school_id] = formula_magic_school_points[school_id] || 0
	for(var/datum/formula_magic_word/word as anything in get_formula_magic_word_templates())
		if(!word.school_id && isnull(formula_magic_form_points[word.id]))
			formula_magic_form_points[word.id] = 0
		if(!word.school_id && isnull(formula_magic_draft_form_points[word.id]))
			formula_magic_draft_form_points[word.id] = formula_magic_form_points[word.id] || 0
		if(word.school_id && isnull(formula_magic_known_words[word.id]))
			formula_magic_known_words[word.id] = 0

/datum/mind/proc/get_formula_magic_total_points()
	var/total = 0
	if(LAZYLEN(major_aspects))
		total += LAZYLEN(major_aspects) * FORMULA_MAJOR_POINTS
	if(LAZYLEN(minor_aspects))
		total += LAZYLEN(minor_aspects) * FORMULA_MINOR_POINTS
	if(current)
		total += current.get_skill_level(/datum/skill/magic/arcane) * FORMULA_ARCANE_POINT_FACTOR
	return total

/datum/mind/proc/get_formula_magic_spent_points()
	ensure_formula_magic_progression()
	var/spent = 0
	for(var/school_id in formula_magic_draft_school_points)
		spent += max(0, formula_magic_draft_school_points[school_id] || 0)
	for(var/word_id in formula_magic_draft_form_points)
		spent += max(0, formula_magic_draft_form_points[word_id] || 0)
	return spent

/datum/mind/proc/get_formula_magic_free_points()

/datum/mind/proc/get_formula_magic_progression_data()
	ensure_formula_magic_progression()
	return list(
		"free_points" = get_formula_magic_free_points(),
		"spent_points" = get_formula_magic_spent_points(),
		"total_points" = get_formula_magic_total_points(),
		"school_points" = formula_magic_draft_school_points.Copy(),
		"form_points" = formula_magic_draft_form_points.Copy(),
		"committed_school_points" = formula_magic_school_points.Copy(),
		"committed_form_points" = formula_magic_form_points.Copy(),
		"school_access" = get_formula_magic_school_access(),
		"committed" = formula_magic_committed,
		"can_reassign" = formula_magic_can_reassign,
		"dirty" = formula_magic_has_unsaved_progression(),
	)

/datum/mind/proc/get_formula_magic_school_points()
	ensure_formula_magic_progression()
	return formula_magic_draft_school_points.Copy()

/datum/mind/proc/get_formula_magic_form_points()
	ensure_formula_magic_progression()
	return formula_magic_draft_form_points.Copy()

/datum/mind/proc/get_formula_magic_school_access()
	var/list/access = list()
	for(var/school_id in formula_magic_school_ids())
		access[school_id] = TRUE
	return access


/datum/mind/proc/adjust_formula_magic_school_points(school_id, delta)
	ensure_formula_magic_progression()
	if(!(school_id in formula_magic_school_ids()) || !delta)
		return FALSE
	var/current_points = formula_magic_draft_school_points[school_id] || 0
	var/new_points = current_points + (delta > 0 ? 1 : -1)
	if(delta > 0 && get_formula_magic_free_points() <= 0)
		return FALSE
	if(delta < 0 && !formula_magic_can_reassign && new_points < (formula_magic_school_points[school_id] || 0))
		return FALSE
	if(new_points < get_formula_magic_school_word_points(school_id))
		return FALSE
	if(new_points < 0)
		return FALSE
	formula_magic_draft_school_points[school_id] = new_points
	return TRUE

/datum/mind/proc/adjust_formula_magic_form_points(form_id, delta)
	ensure_formula_magic_progression()
	var/datum/formula_magic_word/word = resolve_formula_magic_word(form_id)
	if(!word || word.school_id || word.role != FORMULA_WORD_FORM || !delta)
		return FALSE
	var/cost = formula_magic_form_unlock_level(word.id)
	var/step = delta > 0 ? cost : -cost
	var/current_points = formula_magic_draft_form_points[word.id] || 0
	var/new_points = current_points + step
	if(delta > 0 && get_formula_magic_free_points() < cost)
		return FALSE
	if(delta < 0 && !formula_magic_can_reassign && new_points < (formula_magic_form_points[word.id] || 0))
		return FALSE
	if(new_points < 0)
		return FALSE
	if(delta > 0 && !can_raise_formula_magic_form(word.id, new_points))
		return FALSE
	if(delta < 0 && !can_reduce_formula_magic_form(word.id, new_points))
		return FALSE
	formula_magic_draft_form_points[word.id] = new_points
	return TRUE

/datum/mind/proc/commit_formula_magic_allocations()
	ensure_formula_magic_progression()
	formula_magic_school_points = formula_magic_draft_school_points.Copy()
	formula_magic_form_points = formula_magic_draft_form_points.Copy()
	formula_magic_committed = TRUE
	formula_magic_can_reassign = FALSE
	return TRUE

/datum/mind/proc/formula_magic_has_unsaved_progression()
	ensure_formula_magic_progression()
	for(var/school_id in formula_magic_draft_school_points)
		if((formula_magic_draft_school_points[school_id] || 0) != (formula_magic_school_points[school_id] || 0))
			return TRUE
	for(var/word_id in formula_magic_draft_form_points)
		if((formula_magic_draft_form_points[word_id] || 0) != (formula_magic_form_points[word_id] || 0))
			return TRUE
	return FALSE


/datum/mind/proc/unlock_formula_magic_reassignment()
	ensure_formula_magic_progression()
	formula_magic_can_reassign = TRUE
	formula_magic_draft_school_points = formula_magic_school_points.Copy()
	formula_magic_draft_form_points = formula_magic_form_points.Copy()
	return TRUE
