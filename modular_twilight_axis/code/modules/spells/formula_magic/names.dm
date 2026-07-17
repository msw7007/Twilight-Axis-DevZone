/proc/formula_magic_default_formula_name(list/word_ids)
	var/datum/formula_magic_combo_formula/combo = formula_magic_find_exact_combo_formula(word_ids)
	if(combo)
		return combo.name
	var/list/modifiers = list()
	var/list/elements = list()
	var/list/forms = list()
	for(var/word_id in word_ids)
		var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
		if(!word)
			continue
		switch(word.role)
			if(FORMULA_WORD_MODIFIER)
				modifiers += word.id
			if(FORMULA_WORD_ELEMENT)
				elements += word.id
			if(FORMULA_WORD_FORM)
				forms += word.id
	if(!length(forms) && !length(elements) && !length(modifiers))
		return "Formula"
	var/list/parts = list()
	if(length(modifiers) >= 4)
		parts += "Giant"
	else if(length(modifiers) >= 3)
		parts += "Huge"
	else if(length(modifiers) >= 2)
		parts += "Great"
	if(length(modifiers))
		parts += formula_magic_modifier_name_phrase(modifiers[1])
	if(length(elements))
		parts += formula_magic_element_name_phrase(elements[1])
	if(length(forms))
		parts += formula_magic_form_name_phrase(forms[length(forms)])
	return jointext(parts, " ")

/proc/formula_magic_modifier_name_phrase(word_id)
	switch(word_id)
		if("widen")
			return "Wide"
		if("efficient")
			return "Efficient"
		if("ricochet")
			return "Ricocheting"
		if("chain")
			return "Chained"
		if("pierce")
			return "Piercing"
		if("existence")
			return "Lingering"
		if("shrapnel")
			return "Shrapnel"
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	return word?.name || "[word_id]"

/proc/formula_magic_element_name_phrase(word_id)
	switch(word_id)
		if("fire")
			return "Fiery"
		if("frost")
			return "Frost"
		if("frostbite")
			return "Freezing"
		if("lightning")
			return "Lightning"
		if("discharge")
			return "Discharging"
		if("stone")
			return "Stone"
		if("dirt")
			return "Earthen"
		if("force")
			return "Kinetic"
		if("repulse")
			return "Repulsive"
		if("pull")
			return "Pulling"
		if("shift")
			return "Shifting"
		if("iron")
			return "Iron"
		if("blade")
			return "Bladed"
	var/datum/formula_magic_word/word = resolve_formula_magic_word(word_id)
	return word?.name || "[word_id]"

/proc/formula_magic_form_name_phrase(word_id)
	var/list/names = formula_magic_form_names()
	return names[word_id] || resolve_formula_magic_word(word_id)?.name || "[word_id]"
