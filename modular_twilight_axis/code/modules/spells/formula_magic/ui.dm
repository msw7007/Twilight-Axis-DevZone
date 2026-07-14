/datum/formula_magic_panel
	var/mob/living/carbon/human/holder
	var/list/draft_words = list()

/datum/formula_magic_panel/New(mob/living/carbon/human/new_holder)
	. = ..()
	holder = new_holder

/datum/formula_magic_panel/Destroy(force)
	holder = null
	draft_words = null
	return ..()

/datum/formula_magic_panel/ui_state(mob/user)
	return GLOB.always_state

/datum/formula_magic_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FormulaSpellcraft", "Formula Spellcraft")
		ui.open()

/datum/formula_magic_panel/ui_data(mob/user)
	var/mob/living/carbon/human/H = holder
	if(istype(user, /mob/living/carbon/human))
		H = user

	var/datum/formula_magic_formula/preview
	if(H?.mind)
		preview = H.mind.build_formula_magic_formula(draft_words)
	if(!preview)
		preview = new /datum/formula_magic_formula()
		for(var/word_id in draft_words)
			preview.add_word(word_id)

	var/list/data = list()
	data["words"] = get_formula_magic_word_entries()
	data["draft_words"] = draft_words.Copy()
	data["draft_parts"] = formula_magic_display_parts(draft_words)
	data["preview"] = preview.get_summary()
	data["known_words"] = H?.mind?.formula_magic_known_words || list()
	data["known_word_counts"] = H?.mind?.get_formula_magic_known_word_counts() || list()
	data["progression"] = H?.mind?.get_formula_magic_progression_data() || list()
	data["school_points"] = H?.mind?.get_formula_magic_school_points() || list()
	data["form_points"] = H?.mind?.get_formula_magic_form_points() || list()
	data["school_names"] = formula_magic_school_names()
	data["school_access"] = H?.mind?.get_formula_magic_school_access() || list()
	data["form_names"] = formula_magic_form_names()
	data["form_unlocks"] = formula_magic_form_unlocks()
	data["presets"] = H?.mind?.get_formula_magic_presets() || list()
	qdel(preview)
	return data

/datum/formula_magic_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/living/carbon/human/H = holder
	if(istype(ui?.user, /mob/living/carbon/human))
		H = ui.user
	if(!H?.mind)
		return FALSE

	switch(action)
		if("adjust_school")
			var/school_id = params["school_id"]
			var/delta = text2num(params["delta"])
			if(istext(school_id) && delta)
				H.mind.adjust_formula_magic_school_points(school_id, delta)
				SStgui.update_uis(src)
			return TRUE

		if("adjust_form")
			var/form_id = params["form_id"]
			var/delta = text2num(params["delta"])
			if(istext(form_id) && delta)
				H.mind.adjust_formula_magic_form_points(form_id, delta)
				SStgui.update_uis(src)
			return TRUE

		if("add_word")
			var/word_id = params["word_id"]
			if(!istext(word_id) || !H.mind.can_use_formula_magic_word(word_id))
				return TRUE
			draft_words.Insert(length(draft_words) + 1, word_id)
			SStgui.update_uis(src)
			return TRUE

		if("remove_word")
			var/index = text2num(params["index"])
			if(index >= 1 && index <= length(draft_words))
				draft_words.Cut(index, index + 1)
				SStgui.update_uis(src)
			return TRUE

		if("remove_part")
			var/list/indexes = params["indexes"]
			if(islist(indexes))
				for(var/i in length(indexes) to 1 step -1)
					var/index = text2num(indexes[i])
					if(index >= 1 && index <= length(draft_words))
						draft_words.Cut(index, index + 1)
				SStgui.update_uis(src)
			return TRUE

		if("clear_formula")
			draft_words = list()
			SStgui.update_uis(src)
			return TRUE

		if("commit_allocations")
			H.mind.commit_formula_magic_allocations()
			SStgui.update_uis(src)
			return TRUE

		if("learn_word")
			var/word_id = params["word_id"]
			if(istext(word_id))
				H.mind.know_formula_magic_word(word_id)
				SStgui.update_uis(src)
			return TRUE

		if("forget_word")
			var/word_id = params["word_id"]
			if(istext(word_id))
				H.mind.forget_formula_magic_word(word_id)
				SStgui.update_uis(src)
			return TRUE

		if("save_preset")
			var/name = params["name"]
			H.mind.save_formula_magic_preset(name, draft_words)
			SStgui.update_uis(src)
			return TRUE

		if("load_preset")
			var/index = text2num(params["index"])
			var/list/presets = H.mind.get_formula_magic_presets()
			if(index >= 1 && index <= length(presets))
				var/list/preset = presets[index]
				var/list/preset_words = preset["words"]
				draft_words = preset_words?.Copy() || list()
				SStgui.update_uis(src)
			return TRUE

		if("delete_preset")
			var/index = text2num(params["index"])
			H.mind.delete_formula_magic_preset(index)
			SStgui.update_uis(src)
			return TRUE

	return FALSE

/proc/formula_magic_school_names()
	return list(
		FORMULA_SCHOOL_GENERAL = "General Magic",
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
		"arcane" = "Arcane",
	)

/proc/formula_magic_form_unlocks()
	var/list/result = list()
	for(var/form_id in formula_magic_form_ids())
		result[form_id] = formula_magic_form_unlock_level(form_id)
	return result

/proc/formula_magic_display_parts(list/word_ids)
	var/list/result = list()
	var/list/used = list()
	var/list/entries = get_formula_magic_word_entries()
	var/list/names_by_id = list()
	for(var/list/entry in entries)
		names_by_id[entry["id"]] = entry["name"]
	var/list/combo_names = list(
		"[FORMULA_FORM_ORB]|[FORMULA_FORM_INSTANT]" = "Meteor",
		"[FORMULA_FORM_CLOAK]|[FORMULA_FORM_TOUCH]" = "Breath",
		"[FORMULA_FORM_AURA]|[FORMULA_FORM_WAVE]" = "Nova",
		"[FORMULA_FORM_SUMMON]|[FORMULA_FORM_GUIDANCE]" = "Rune",
	)
	for(var/i in 1 to length(word_ids))
		if(used["[i]"])
			continue
		var/word_id = formula_magic_normalize_word_id(word_ids[i])
		var/paired = FALSE
		for(var/j in i + 1 to length(word_ids))
			if(used["[j]"])
				continue
			var/other_id = formula_magic_normalize_word_id(word_ids[j])
			var/combo_key = "[word_id]|[other_id]"
			var/reverse_key = "[other_id]|[word_id]"
			var/combo_name = combo_names[combo_key] || combo_names[reverse_key]
			if(!combo_name)
				continue
			used["[i]"] = TRUE
			used["[j]"] = TRUE
			result += list(list(
				"name" = combo_name,
				"words" = list(word_id, other_id),
				"indexes" = list(i, j),
			))
			paired = TRUE
			break
		if(paired)
			continue
		used["[i]"] = TRUE
		result += list(list(
			"name" = names_by_id[word_id] || word_id,
			"words" = list(word_id),
			"indexes" = list(i),
		))
	return result

/mob/living/carbon/human/verb/open_formula_spellcraft()
	set name = "Formula Spellcraft"
	set category = "RoleUnique"

	if(!mind)
		return
	if(!get_skill_level(/datum/skill/magic/arcane) && !LAZYLEN(mind.major_aspects) && !LAZYLEN(mind.minor_aspects))
		to_chat(src, span_warning("I lack the arcyne training to shape formula magic."))
		return

	var/datum/formula_magic_panel/panel = new(src)
	panel.ui_interact(src)
