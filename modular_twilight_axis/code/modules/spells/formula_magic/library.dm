/datum/mind/proc/formula_magic_make_library_entry(preset_name, list/word_ids)
	var/list/words = formula_magic_normalized_word_list(word_ids)
	var/datum/formula_magic_formula/formula = build_formula_magic_formula(words)
	var/name = sanitize(copytext("[preset_name || formula_magic_default_formula_name(words)]", 1, 48))
	if(!length(name))
		name = formula_magic_default_formula_name(words)
	var/list/requirements = get_formula_magic_formula_requirements(words)
	var/list/entry = list(
		"name" = name,
		"words" = words.Copy(),
		"summary" = formula?.get_formula_text() || "Empty formula",
		"mana_cost" = formula?.mana_cost || 1,
		"cast_time" = formula?.cast_time || FORMULA_DEFAULT_WORD_DELAY,
		"complexity" = formula?.complexity || 1,
		"interrupt_chance" = formula?.interrupt_chance || 10,
		"word_cast_times" = formula?.word_cast_times?.Copy() || list(),
		"arcane_required" = requirements["arcane_required"],
		"reading_required" = requirements["reading_required"],
		"requirements" = requirements["requirements"],
		"export_json" = formula_magic_export_json(name, words),
	)
	qdel(formula)
	return entry

/datum/mind/proc/find_formula_magic_preset_by_name(preset_name)
	if(!formula_magic_saved_formulas || !length(preset_name))
		return 0
	var/needle = lowertext("[preset_name]")
	for(var/i in 1 to length(formula_magic_saved_formulas))
		var/list/preset = formula_magic_saved_formulas[i]
		if(lowertext("[preset["name"]]") == needle)
			return i
	return 0

/datum/mind/proc/get_formula_magic_formula_slot_limit()
	return 1 + ((current?.get_skill_level(/datum/skill/magic/arcane) || 0) * 2)

/datum/mind/proc/save_formula_magic_preset(preset_name, list/word_ids)
	if(!formula_magic_saved_formulas)
		formula_magic_saved_formulas = list()
	var/list/entry = formula_magic_make_library_entry(preset_name, word_ids)
	var/existing_index = find_formula_magic_preset_by_name(entry["name"])
	if(existing_index)
		formula_magic_saved_formulas[existing_index] = entry
		refresh_formula_magic_preset_spells()
		return existing_index
	if(length(formula_magic_saved_formulas) >= get_formula_magic_formula_slot_limit())
		return FALSE
	formula_magic_saved_formulas += list(entry)
	refresh_formula_magic_preset_spells()
	return length(formula_magic_saved_formulas)

/datum/mind/proc/get_formula_magic_presets()
	if(!formula_magic_saved_formulas)
		formula_magic_saved_formulas = list()
	return formula_magic_saved_formulas.Copy()

/datum/mind/proc/delete_formula_magic_preset(index)
	if(!formula_magic_saved_formulas || index < 1 || index > length(formula_magic_saved_formulas))
		return FALSE
	formula_magic_saved_formulas.Cut(index, index + 1)
	refresh_formula_magic_preset_spells()
	return TRUE

/datum/mind/proc/rename_formula_magic_preset(index, new_name)
	if(!formula_magic_saved_formulas || index < 1 || index > length(formula_magic_saved_formulas))
		return FALSE
	var/list/preset = formula_magic_saved_formulas[index]
	preset["name"] = sanitize(copytext("[new_name || preset["name"]]", 1, 48))
	refresh_formula_magic_preset_spells()
	return TRUE

/datum/mind/proc/update_formula_magic_preset(index, list/word_ids, new_name = null)
	if(!formula_magic_saved_formulas || index < 1 || index > length(formula_magic_saved_formulas))
		return FALSE
	var/list/preset = formula_magic_saved_formulas[index]
	formula_magic_saved_formulas[index] = formula_magic_make_library_entry(new_name || preset["name"], word_ids)
	refresh_formula_magic_preset_spells()
	return TRUE

/datum/mind/proc/formula_magic_export_json(preset_name, list/word_ids)
	var/list/words = formula_magic_normalized_word_list(word_ids)
	return json_encode(list("kind" = "twilight_axis_formula", "version" = 2, "name" = preset_name || formula_magic_default_formula_name(words), "words" = words))

/datum/mind/proc/formula_magic_import_json(raw_json, save_import = FALSE)
	var/list/decoded = safe_json_decode(raw_json)
	if(!islist(decoded))
		return FALSE
	var/list/words = formula_magic_normalized_word_list(decoded["words"])
	if(save_import)
		return save_formula_magic_preset(decoded["name"], words)
	return words

/datum/mind/proc/refresh_formula_magic_preset_spells()
	for(var/datum/action/cooldown/spell/formula_preset/existing in spell_list)
		RemoveSpell(existing)
	if(!formula_magic_saved_formulas)
		return
	var/count = 0
	var/slot_limit = get_formula_magic_formula_slot_limit()
	for(var/list/preset in formula_magic_saved_formulas)
		count++
		if(count > slot_limit)
			break
		AddSpell(new /datum/action/cooldown/spell/formula_preset(preset, count))


/datum/mind/proc/enable_formula_magic_spell_learning()
	formula_magic_replaces_spell_learning = TRUE
	if(current)
		RemoveSpell(/datum/action/cooldown/spell/learnspell)
	return TRUE
