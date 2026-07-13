/datum/mind
	var/formula_magic_replaces_spell_learning = FALSE
	var/list/formula_magic_school_points
	var/list/formula_magic_form_points
	var/list/formula_magic_draft_school_points
	var/list/formula_magic_draft_form_points
	var/list/formula_magic_known_words
	var/list/formula_magic_saved_formulas
	var/list/formula_magic_live_words
	var/formula_magic_committed = FALSE
	var/formula_magic_can_reassign = TRUE

/datum/mind/proc/get_formula_magic_total_points()
	var/total = 0
	if(formula_magic_replaces_spell_learning && LAZYLEN(mage_aspect_config))
		total += (mage_aspect_config["major"] || 0) * FORMULA_MAJOR_POINTS
		total += (mage_aspect_config["minor"] || 0) * FORMULA_MINOR_POINTS
	else
		total += LAZYLEN(major_aspects) * FORMULA_MAJOR_POINTS
		total += LAZYLEN(minor_aspects) * FORMULA_MINOR_POINTS
	if(current)
		total += current.get_skill_level(/datum/skill/magic/arcane) * FORMULA_ARCANE_POINT_FACTOR
	return total

/datum/mind/proc/enable_formula_magic_spell_learning()
	formula_magic_replaces_spell_learning = TRUE
	RemoveSpell(/datum/action/cooldown/spell/learnspell)
	if(!has_spell(/datum/action/cooldown/spell/formula_live_cast))
		AddSpell(new /datum/action/cooldown/spell/formula_live_cast())
	return TRUE

/datum/mind/proc/ensure_formula_magic_allocations()
	if(!formula_magic_school_points)
		formula_magic_school_points = list()
	if(!formula_magic_draft_school_points)
		formula_magic_draft_school_points = formula_magic_school_points.Copy()
	for(var/school_id in formula_magic_school_ids())
		if(isnull(formula_magic_school_points[school_id]))
			formula_magic_school_points[school_id] = 0
		if(isnull(formula_magic_draft_school_points[school_id]))
			formula_magic_draft_school_points[school_id] = formula_magic_school_points[school_id] || 0

	if(!formula_magic_form_points)
		formula_magic_form_points = list()
	if(!formula_magic_draft_form_points)
		formula_magic_draft_form_points = formula_magic_form_points.Copy()
	for(var/form_id in formula_magic_form_ids())
		if(isnull(formula_magic_form_points[form_id]))
			formula_magic_form_points[form_id] = 0
		if(isnull(formula_magic_draft_form_points[form_id]))
			formula_magic_draft_form_points[form_id] = formula_magic_form_points[form_id] || 0

	if(!formula_magic_known_words)
		formula_magic_known_words = list()
	normalize_formula_magic_known_words()
	if(!formula_magic_saved_formulas)
		formula_magic_saved_formulas = list()
	if(!formula_magic_live_words)
		formula_magic_live_words = list()

/datum/mind/proc/normalize_formula_magic_known_words()
	var/list/normalized = list()
	for(var/datum/formula_magic_word/word as anything in get_formula_magic_word_templates())
		var/count = formula_magic_known_words[word.id]
		if(!isnum(count) && (word.id in formula_magic_known_words))
			count = 1
		if(isnum(count) && count > 0)
			normalized[word.id] = count
	formula_magic_known_words = normalized

/datum/mind/proc/get_formula_magic_spent_points()
	ensure_formula_magic_allocations()
	var/spent = 0
	for(var/school_id in formula_magic_draft_school_points)
		spent += max(0, formula_magic_draft_school_points[school_id])
	for(var/form_id in formula_magic_draft_form_points)
		spent += max(0, formula_magic_draft_form_points[form_id])
	return spent

/datum/mind/proc/get_formula_magic_free_points()
	return max(0, get_formula_magic_total_points() - get_formula_magic_spent_points())

/datum/mind/proc/get_formula_magic_school_points()
	ensure_formula_magic_allocations()
	return formula_magic_draft_school_points.Copy()

/datum/mind/proc/get_formula_magic_form_points()
	ensure_formula_magic_allocations()
	return formula_magic_draft_form_points.Copy()

/datum/mind/proc/formula_magic_has_uncommitted_allocations()
	ensure_formula_magic_allocations()
	for(var/school_id in formula_magic_school_ids())
		if((formula_magic_draft_school_points[school_id] || 0) != (formula_magic_school_points[school_id] || 0))
			return TRUE
	for(var/form_id in formula_magic_form_ids())
		if((formula_magic_draft_form_points[form_id] || 0) != (formula_magic_form_points[form_id] || 0))
			return TRUE
	return FALSE

/datum/mind/proc/adjust_formula_magic_school_points(school_id, delta)
	if(!(school_id in formula_magic_school_ids()))
		return FALSE
	ensure_formula_magic_allocations()
	if(delta > 0 && get_formula_magic_free_points() < delta)
		return FALSE
	var/current_points = formula_magic_draft_school_points[school_id] || 0
	if(current_points + delta < 0)
		return FALSE
	if(delta < 0 && !formula_magic_can_reassign && current_points + delta < (formula_magic_school_points[school_id] || 0))
		return FALSE
	if(delta < 0 && get_formula_magic_school_word_points(school_id) > current_points + delta)
		return FALSE
	formula_magic_draft_school_points[school_id] = current_points + delta
	return TRUE

/datum/mind/proc/adjust_formula_magic_form_points(form_id, delta)
	if(!(form_id in formula_magic_form_ids()))
		return FALSE
	ensure_formula_magic_allocations()
	if(delta > 0 && get_formula_magic_free_points() < delta)
		return FALSE
	var/current_points = formula_magic_draft_form_points[form_id] || 0
	if(current_points + delta < 0)
		return FALSE
	if(delta < 0 && !formula_magic_can_reassign && current_points + delta < (formula_magic_form_points[form_id] || 0))
		return FALSE
	formula_magic_draft_form_points[form_id] = current_points + delta
	return TRUE

/datum/mind/proc/commit_formula_magic_allocations()
	ensure_formula_magic_allocations()
	if(!formula_magic_can_reassign && !formula_magic_has_uncommitted_allocations())
		return FALSE
	formula_magic_school_points = formula_magic_draft_school_points.Copy()
	formula_magic_form_points = formula_magic_draft_form_points.Copy()
	formula_magic_committed = TRUE
	formula_magic_can_reassign = FALSE
	refresh_formula_magic_preset_spells()
	return TRUE

/datum/mind/proc/unlock_formula_magic_reassignment()
	ensure_formula_magic_allocations()
	formula_magic_draft_school_points = formula_magic_school_points.Copy()
	formula_magic_draft_form_points = formula_magic_form_points.Copy()
	formula_magic_can_reassign = TRUE

/datum/mind/proc/know_formula_magic_word(word_id)
	if(!word_id)
		return FALSE
	ensure_formula_magic_allocations()
	if(!formula_magic_committed)
		return FALSE
	if(formula_magic_has_uncommitted_allocations())
		return FALSE
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word || !can_learn_formula_magic_word(word_id))
		return FALSE
	if(get_formula_magic_word_free_slots(word) <= 0)
		return FALSE
	formula_magic_known_words[word_id] = (formula_magic_known_words[word_id] || 0) + 1
	return TRUE

/datum/mind/proc/forget_formula_magic_word(word_id)
	if(!word_id)
		return FALSE
	ensure_formula_magic_allocations()
	if(!formula_magic_can_reassign)
		return FALSE
	var/current_count = formula_magic_known_words[word_id] || 0
	if(current_count <= 0)
		return FALSE
	if(current_count <= 1)
		formula_magic_known_words -= word_id
	else
		formula_magic_known_words[word_id] = current_count - 1
	return TRUE

/datum/mind/proc/get_formula_magic_known_word_counts()
	ensure_formula_magic_allocations()
	return formula_magic_known_words.Copy()

/datum/mind/proc/get_formula_magic_school_word_points(school_id)
	ensure_formula_magic_allocations()
	var/used = 0
	for(var/word_id in formula_magic_known_words)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(word?.school_id == school_id)
			used += formula_magic_known_words[word_id] || 0
	return used

/datum/mind/proc/get_formula_magic_word_free_slots(datum/formula_magic_word/word)
	if(!word)
		return 0
	if(word.role == FORMULA_WORD_FORM)
		return can_use_formula_magic_form(word.id, TRUE) ? 1 : 0
	if(!word.school_id)
		return (formula_magic_known_words[word.id] || 0) ? 0 : 1
	var/used = get_formula_magic_school_word_points(word.school_id)
	return max(0, (formula_magic_school_points[word.school_id] || 0) - used)

/datum/mind/proc/can_learn_formula_magic_word(word_id, committed_values = FALSE)
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word)
		return FALSE
	if(word.role == FORMULA_WORD_FORM)
		return can_use_formula_magic_form(word.id, committed_values)
	if(!word.school_id)
		return TRUE
	ensure_formula_magic_allocations()
	var/list/source = committed_values ? formula_magic_school_points : formula_magic_draft_school_points
	return (source[word.school_id] || 0) >= word.unlock_level

/datum/mind/proc/can_use_formula_magic_form(form_id, committed_values = FALSE)
	ensure_formula_magic_allocations()
	var/required = formula_magic_form_unlock_level(form_id)
	var/list/source = committed_values ? formula_magic_form_points : formula_magic_draft_form_points
	return (source[form_id] || 0) >= required

/datum/mind/proc/can_use_formula_magic_word(word_id)
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	if(!word)
		return FALSE
	if(!formula_magic_committed)
		return FALSE
	if(word.role == FORMULA_WORD_FORM)
		return can_use_formula_magic_form(word.id, TRUE)
	if(!word.school_id)
		return TRUE
	ensure_formula_magic_allocations()
	return (formula_magic_known_words[word_id] || 0) > 0

/datum/mind/proc/get_formula_magic_usable_word_entries()
	ensure_formula_magic_allocations()
	var/list/result = list()
	for(var/datum/formula_magic_word/word as anything in get_formula_magic_word_templates())
		if(can_use_formula_magic_word(word.id))
			result += list(word.get_entry())
	return result

/datum/mind/proc/build_formula_magic_formula(list/word_ids)
	if(!formula_magic_committed)
		return null
	if(formula_magic_has_uncommitted_allocations())
		return null
	var/datum/formula_magic_formula/formula = new
	for(var/word_id in word_ids)
		if(!can_use_formula_magic_word(word_id))
			qdel(formula)
			return null
		formula.add_word(word_id)
	if(!validate_formula_magic_formula(formula, TRUE))
		qdel(formula)
		return null
	apply_formula_magic_form_scaling(formula)
	apply_formula_magic_school_scaling(formula)
	apply_formula_magic_base_arcane(formula)
	return formula

/datum/mind/proc/apply_formula_magic_form_scaling(datum/formula_magic_formula/formula)
	if(!formula)
		return
	var/meteor_words = 0
	var/elemental_words = 0
	for(var/datum/formula_magic_word/word in formula.words)
		if(word.id == FORMULA_FORM_FALL)
			meteor_words++
		if(word.school_id && (word.role == FORMULA_WORD_ELEMENT || word.role == FORMULA_WORD_POST_EFFECT))
			elemental_words++
	if(meteor_words > 0)
		var/base_delay = (1 + elemental_words) SECONDS
		formula.delay = max(1, round(base_delay * (0.9 ** max(0, meteor_words - 1))))

/datum/mind/proc/apply_formula_magic_school_scaling(datum/formula_magic_formula/formula)
	var/list/school_counts = list()
	for(var/datum/formula_magic_word/word in formula.words)
		if(word.school_id)
			school_counts[word.school_id] = (school_counts[word.school_id] || 0) + 1
	var/highest_extra = 0
	for(var/school_id in school_counts)
		highest_extra = max(highest_extra, (school_counts[school_id] || 1) - 1)
	if(highest_extra > 0)
		formula.power = round(formula.power * (1 + highest_extra * 0.25))
	apply_formula_magic_word_speed(formula)

/datum/mind/proc/apply_formula_magic_word_speed(datum/formula_magic_formula/formula)
	var/new_total = 0
	var/index = 1
	for(var/datum/formula_magic_word/word in formula.words)
		var/base_time = formula.word_cast_times[index] || word.cast_time
		var/rank = word.school_id ? (formula_magic_known_words[word.id] || 0) : 0
		var/speed_mult = max(0.1, 1 - (rank * 0.1))
		var/adjusted = max(1, round(base_time * speed_mult))
		formula.word_cast_times[index] = adjusted
		new_total += adjusted
		index++
	var/touch_words = 0
	for(var/form_id in formula.forms)
		if(form_id == FORMULA_FORM_TOUCH)
			touch_words++
	if(touch_words > 0)
		var/touch_mult = 0.7 ** touch_words
		new_total = 0
		for(var/i in 1 to length(formula.word_cast_times))
			var/adjusted_touch_time = max(1, round((formula.word_cast_times[i] || 1) * touch_mult))
			formula.word_cast_times[i] = adjusted_touch_time
			new_total += adjusted_touch_time
	formula.cast_time = new_total

/datum/mind/proc/validate_formula_magic_formula(datum/formula_magic_formula/formula, feedback = FALSE)
	if(!formula || !formula.can_resolve())
		return FALSE
	var/arcane_rank = current?.get_skill_level(/datum/skill/magic/arcane) || 0
	var/slots_used = 0
	var/prefix_open = TRUE
	var/list/school_counts = list()
	var/list/form_counts = list()
	var/list/slot_keys = list()
	var/list/modifier_slot_counts = list()
	for(var/datum/formula_magic_word/word in formula.words)
		if(word.role == FORMULA_WORD_LINK || word.role == FORMULA_WORD_STABILIZER)
			if(!prefix_open)
				if(feedback && current)
					to_chat(current, span_warning("[word.name] must be spoken before the working formula begins."))
				return FALSE
		prefix_open = FALSE
		if(word.role == FORMULA_WORD_FORM)
			slot_keys["form:[word.id]"] = TRUE
		else if(word.school_id && (word.role == FORMULA_WORD_ELEMENT || word.role == FORMULA_WORD_POST_EFFECT))
			slot_keys["school:[word.school_id]"] = TRUE
		else if(word.role == FORMULA_WORD_MODIFIER || word.role == FORMULA_WORD_LINK || word.role == FORMULA_WORD_STABILIZER)
			modifier_slot_counts[word.id] = (modifier_slot_counts[word.id] || 0) + 1
			slot_keys["modifier:[word.id]:[modifier_slot_counts[word.id]]"] = TRUE
		if(word.role == FORMULA_WORD_FORM)
			form_counts[word.id] = (form_counts[word.id] || 0) + 1
		if(word.school_id)
			school_counts[word.school_id] = (school_counts[word.school_id] || 0) + 1
	slots_used = length(slot_keys)
	if(slots_used > max(1, arcane_rank))
		if(feedback && current)
			to_chat(current, span_warning("My arcane skill can only bind [max(1, arcane_rank)] active word types. Forms and schools count once each, but every modifier word counts separately."))
		return FALSE
	for(var/form_id in form_counts)
		if((form_counts[form_id] || 0) > (formula_magic_form_points[form_id] || 0))
			if(feedback && current)
				var/list/form_names = formula_magic_form_names()
				to_chat(current, span_warning("I have not invested enough into [form_names[form_id] || form_id] to repeat that form so far."))
			return FALSE
	for(var/school_id in school_counts)
		if((school_counts[school_id] || 0) > (formula_magic_school_points[school_id] || 0))
			if(feedback && current)
				to_chat(current, span_warning("I have not invested enough into [school_id] to repeat it this far."))
			return FALSE
	if((FORMULA_SCHOOL_PYROMANCY in formula.schools) && (FORMULA_SCHOOL_CRYOMANCY in formula.schools))
		formula.add_tag("unstable_opposition")
	if((FORMULA_SCHOOL_FULGURMANCY in formula.schools) && (FORMULA_SCHOOL_GEOMANCY in formula.schools))
		formula.add_tag("unstable_opposition")
	return TRUE

/datum/mind/proc/apply_formula_magic_base_arcane(datum/formula_magic_formula/formula)
	if(!formula || length(formula.schools) || length(formula.elements) || length(formula.post_effects))
		return
	formula.add_tag("damage_arcane")

/datum/mind/proc/save_formula_magic_preset(preset_name, list/word_ids)
	ensure_formula_magic_allocations()
	if(!formula_magic_committed)
		return FALSE
	if(!length(word_ids))
		return FALSE
	if(length(formula_magic_saved_formulas) >= FORMULA_PRESET_LIMIT)
		return FALSE
	var/name = sanitize(copytext("[preset_name]", 1, 48))
	if(!length(name))
		name = "Formula [length(formula_magic_saved_formulas) + 1]"
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(word_ids)
	if(!formula || !formula.can_resolve())
		qdel(formula)
		return FALSE
	formula_magic_saved_formulas += list(list(
		"name" = name,
		"words" = word_ids.Copy(),
		"summary" = formula.get_formula_text(),
		"mana_cost" = formula.mana_cost,
		"cast_time" = formula.cast_time,
		"complexity" = formula.complexity,
	))
	qdel(formula)
	refresh_formula_magic_preset_spells()
	return TRUE

/datum/mind/proc/delete_formula_magic_preset(index)
	ensure_formula_magic_allocations()
	if(index < 1 || index > length(formula_magic_saved_formulas))
		return FALSE
	formula_magic_saved_formulas.Cut(index, index + 1)
	refresh_formula_magic_preset_spells()
	return TRUE

/datum/mind/proc/get_formula_magic_presets()
	ensure_formula_magic_allocations()
	return formula_magic_saved_formulas.Copy()

/datum/mind/proc/get_formula_magic_progression_data()
	ensure_formula_magic_allocations()
	return list(
		"total_points" = get_formula_magic_total_points(),
		"spent_points" = get_formula_magic_spent_points(),
		"free_points" = get_formula_magic_free_points(),
		"school_points" = get_formula_magic_school_points(),
		"form_points" = get_formula_magic_form_points(),
		"committed_school_points" = formula_magic_school_points.Copy(),
		"committed_form_points" = formula_magic_form_points.Copy(),
		"known_word_counts" = get_formula_magic_known_word_counts(),
		"committed" = formula_magic_committed,
		"can_reassign" = formula_magic_can_reassign,
		"dirty" = formula_magic_has_uncommitted_allocations(),
	)

/datum/mind/proc/refresh_formula_magic_preset_spells()
	for(var/datum/action/cooldown/spell/formula_preset/existing in spell_list)
		RemoveSpell(existing)
	if(!current || !formula_magic_committed)
		return
	var/count = 0
	for(var/list/preset in formula_magic_saved_formulas)
		count++
		if(count > FORMULA_SPELL_ACTION_LIMIT)
			break
		AddSpell(new /datum/action/cooldown/spell/formula_preset(preset, count))


/proc/formula_magic_school_ids()
	return list(
		FORMULA_SCHOOL_PYROMANCY,
		FORMULA_SCHOOL_CRYOMANCY,
		FORMULA_SCHOOL_FULGURMANCY,
		FORMULA_SCHOOL_GEOMANCY,
		FORMULA_SCHOOL_KINESIS,
		FORMULA_SCHOOL_DISPLACEMENT,
		FORMULA_SCHOOL_AUGMENTATION,
		FORMULA_SCHOOL_CURSES,
		FORMULA_SCHOOL_ARTIFICE_WARDING,
		FORMULA_SCHOOL_LIFE,
	)

/proc/formula_magic_form_ids()
	return list(
		FORMULA_FORM_ORB,
		FORMULA_FORM_AURA,
		FORMULA_FORM_CLOAK,
		FORMULA_FORM_INSTANT,
		FORMULA_FORM_FALL,
		FORMULA_FORM_SUMMON,
		FORMULA_FORM_RUNE,
		FORMULA_FORM_GUIDANCE,
		FORMULA_FORM_WAVE,
		FORMULA_FORM_BREATH,
		FORMULA_FORM_NOVA,
		FORMULA_FORM_TOUCH,
	)

/proc/formula_magic_form_unlock_level(form_id)
	switch(form_id)
		if(FORMULA_FORM_ORB)
			return 1
		if(FORMULA_FORM_AURA)
			return 2
		if(FORMULA_FORM_CLOAK)
			return 2
		if(FORMULA_FORM_INSTANT)
			return 2
		if(FORMULA_FORM_FALL)
			return 3
		if(FORMULA_FORM_SUMMON)
			return 3
		if(FORMULA_FORM_RUNE)
			return 3
		if(FORMULA_FORM_GUIDANCE)
			return 4
		if(FORMULA_FORM_WAVE)
			return 2
		if(FORMULA_FORM_BREATH)
			return 2
		if(FORMULA_FORM_NOVA)
			return 2
		if(FORMULA_FORM_TOUCH)
			return 1
	return 1

/proc/formula_magic_form_names()
	return list(
		FORMULA_FORM_ORB = "Orb",
		FORMULA_FORM_AURA = "Aura",
		FORMULA_FORM_CLOAK = "Cloak",
		FORMULA_FORM_INSTANT = "Moment",
		FORMULA_FORM_FALL = "Meteor",
		FORMULA_FORM_SUMMON = "Summon",
		FORMULA_FORM_RUNE = "Rune",
		FORMULA_FORM_GUIDANCE = "Guidance",
		FORMULA_FORM_WAVE = "Wave",
		FORMULA_FORM_BREATH = "Breath",
		FORMULA_FORM_NOVA = "Nova",
		FORMULA_FORM_TOUCH = "Touch",
	)

/proc/formula_magic_school_from_aspect(datum/magic_aspect/aspect)
	if(!aspect)
		return null
	switch(aspect.type)
		if(/datum/magic_aspect/pyromancy)
			return FORMULA_SCHOOL_PYROMANCY
		if(/datum/magic_aspect/cryomancy)
			return FORMULA_SCHOOL_CRYOMANCY
		if(/datum/magic_aspect/fulgurmancy)
			return FORMULA_SCHOOL_FULGURMANCY
		if(/datum/magic_aspect/geomancy)
			return FORMULA_SCHOOL_GEOMANCY
		if(/datum/magic_aspect/kinesis, /datum/magic_aspect/telomancy)
			return FORMULA_SCHOOL_KINESIS
		if(/datum/magic_aspect/displacement)
			return FORMULA_SCHOOL_DISPLACEMENT
		if(/datum/magic_aspect/augmentation, /datum/magic_aspect/lesser_augmentation)
			return FORMULA_SCHOOL_AUGMENTATION
		if(/datum/magic_aspect/ferramancy, /datum/magic_aspect/battlewardry, /datum/magic_aspect/artifice, /datum/magic_aspect/exowardry, /datum/magic_aspect/autowardry)
			return FORMULA_SCHOOL_ARTIFICE_WARDING
	return null
