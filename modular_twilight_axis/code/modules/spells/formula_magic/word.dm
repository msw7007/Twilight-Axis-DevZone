/datum/formula_magic_word
	var/id
	var/name = "Word"
	var/desc = ""
	var/school_id
	var/role = FORMULA_WORD_ELEMENT
	var/tier = 1
	var/mana_cost = 1
	var/cast_time = 10
	var/complexity = 1
	var/instability = 0
	var/unlock_level = 1
	var/learn_cost = 1
	var/repeatable = TRUE
	var/is_stop_word = FALSE
	var/list/tags = list()
	var/list/required_school_points = list()
	var/list/phrases = list()
	var/list/spoken_phrases = list()

/datum/formula_magic_word/proc/apply_to_part(datum/formula_magic_part/part)
	if(!part)
		return
	part.mana_cost += mana_cost
	part.cast_time += cast_time
	part.complexity += complexity
	for(var/tag in tags)
		part.add_tag(tag)
	if(school_id && !(school_id in part.schools))
		part.schools += school_id
	switch(role)
		if(FORMULA_WORD_FORM)
			part.forms += id
			if(!part.form_id)
				part.form_id = id
		if(FORMULA_WORD_ELEMENT)
			part.elements += id
		if(FORMULA_WORD_MODIFIER)
			part.modifiers += id

/datum/formula_magic_word/proc/get_entry()
	return list(
		"id" = id,
		"name" = name,
		"desc" = desc,
		"school_id" = school_id,
		"role" = role,
		"tier" = tier,
		"mana_cost" = mana_cost,
		"cast_time" = cast_time,
		"complexity" = complexity,
		"instability" = instability,
		"unlock_level" = unlock_level,
		"learn_cost" = learn_cost,
		"repeatable" = repeatable,
		"is_stop_word" = is_stop_word,
		"tags" = tags.Copy(),
		"required_school_points" = required_school_points.Copy(),
		"phrases" = phrases.Copy(),
	)

/datum/formula_magic_word/proc/get_phrase()
	if(length(phrases))
		return phrases[1]
	return "Asha."

/datum/formula_magic_word/proc/get_speech_phrases()
	if(length(spoken_phrases))
		return spoken_phrases.Copy()
	return list(get_phrase())
