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
	var/list/presets = H?.mind?.get_formula_magic_presets() || list()
	var/reading_rank = H?.get_skill_level(/datum/skill/misc/reading) || 0
	for(var/list/preset as anything in presets)
		if(reading_rank < (preset["reading_required"] || 0))
			preset["export_json"] = ""
	data["presets"] = presets
	var/list/draft_validation = H?.mind?.validate_formula_magic_word_list(draft_words) || list()
	data["draft_validation"] = draft_validation
	data["draft_export_json"] = (reading_rank >= (draft_validation["reading_required"] || 0)) ? (H?.mind?.formula_magic_export_json("Draft formula", draft_words) || "") : ""
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

		if("import_formula")
			var/raw_json = params["json"]
			if(istext(raw_json))
				var/list/decoded = safe_json_decode(raw_json)
				if(!islist(decoded))
					return TRUE
				var/list/import_words = H.mind.formula_magic_normalized_word_list(decoded["words"])
				var/reading_required = H.mind.get_formula_magic_arcane_requirement(import_words)
				if(H.get_skill_level(/datum/skill/misc/reading) < reading_required)
					to_chat(H, span_warning("I need Reading [reading_required] to import that formula."))
					return TRUE
				H.mind.formula_magic_import_json(raw_json, TRUE)
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

		if("rename_preset")
			var/index = text2num(params["index"])
			var/list/presets = H.mind.get_formula_magic_presets()
			if(index >= 1 && index <= length(presets))
				var/list/preset = presets[index]
				var/new_name = tgui_input_text(H, "Rename this formula.", "Formula Name", preset["name"], MAX_NAME_LEN)
				if(new_name)
					H.mind.rename_formula_magic_preset(index, new_name)
					SStgui.update_uis(src)
			return TRUE

		if("update_preset")
			var/index = text2num(params["index"])
			if(index >= 1)
				H.mind.update_formula_magic_preset(index, draft_words)
				SStgui.update_uis(src)
			return TRUE

		if("create_formula_scroll")
			var/name = params["name"]
			var/list/validation = H.mind.validate_formula_magic_word_list(draft_words)
			var/reading_required = validation["reading_required"] || 0
			if(H.get_skill_level(/datum/skill/misc/reading) < reading_required)
				to_chat(H, span_warning("I need Reading [reading_required] to scribe that formula."))
				return TRUE
			if(!validation["valid"])
				to_chat(H, span_warning("The formula is not valid enough to scribe."))
				return TRUE
			var/obj/item/paper/scroll/formula_magic/scroll = new(get_turf(H))
			scroll.set_formula_magic_scroll(name, draft_words, H.mind)
			H.put_in_hands(scroll, TRUE)
			return TRUE

		if("read_formula_scroll")
			var/obj/item/paper/scroll/formula_magic/scroll
			for(var/obj/item/paper/scroll/formula_magic/held in H.held_items)
				scroll = held
				break
			if(!scroll)
				to_chat(H, span_warning("I need to hold a formula scroll."))
				return TRUE
			if(H.get_skill_level(/datum/skill/misc/reading) < scroll.reading_required)
				to_chat(H, span_warning("I need Reading [scroll.reading_required] to read that formula."))
				return TRUE
			draft_words = scroll.formula_words.Copy()
			SStgui.update_uis(src)
			return TRUE

	return FALSE

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
