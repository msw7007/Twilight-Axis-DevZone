GLOBAL_LIST_EMPTY(formula_magic_words_by_id)
GLOBAL_LIST_EMPTY(formula_magic_word_entries)

/proc/init_formula_magic_words()
	GLOB.formula_magic_words_by_id = list()
	GLOB.formula_magic_word_entries = list()
	for(var/path in subtypesof(/datum/formula_magic_word))
		var/datum/formula_magic_word/word = new path
		if(!word.id)
			qdel(word)
			continue
		if(word.role == FORMULA_WORD_FORM && !(word.id in formula_magic_form_ids()) && !word.tags?["prebuilt_formula"])
			qdel(word)
			continue
		GLOB.formula_magic_words_by_id[word.id] = word
		GLOB.formula_magic_word_entries += list(word.get_entry())

/proc/resolve_formula_magic_word(word_or_path)
	if(istype(word_or_path, /datum/formula_magic_word))
		return word_or_path
	if(ispath(word_or_path, /datum/formula_magic_word))
		return new word_or_path
	if(istext(word_or_path))
		if(!length(GLOB.formula_magic_words_by_id))
			init_formula_magic_words()
		var/datum/formula_magic_word/template = GLOB.formula_magic_words_by_id[formula_magic_normalize_word_id(word_or_path)]
		if(template)
			return new template.type
	return null

/proc/formula_magic_normalize_word_id(word_id)
	switch(word_id)
		if("life")
			return "creation"
		if("death")
			return "bone"
	return word_id

/proc/get_formula_magic_word_entries()
	if(!length(GLOB.formula_magic_word_entries))
		init_formula_magic_words()
	return GLOB.formula_magic_word_entries.Copy()

/proc/get_formula_magic_word_templates()
	if(!length(GLOB.formula_magic_words_by_id))
		init_formula_magic_words()
	var/list/result = list()
	for(var/id in GLOB.formula_magic_words_by_id)
		result += GLOB.formula_magic_words_by_id[id]
	return result
