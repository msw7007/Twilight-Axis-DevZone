/datum/formula_magic_panel
	var/mob/living/carbon/human/holder
	var/list/draft_words = list()
	var/draft_name = ""
	var/loaded_preset_index = 0
	var/loaded_preset_name = ""
	var/list/loaded_preset_words = list()

/datum/formula_magic_panel/New(mob/living/carbon/human/new_holder)
	. = ..()
	holder = new_holder

/datum/formula_magic_panel/Destroy(force)
	holder = null
	draft_words = null
	loaded_preset_words = null
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
	var/datum/formula_magic_formula/preview = H?.mind?.build_formula_magic_formula(draft_words)
	if(!preview)
		preview = new /datum/formula_magic_formula()
	var/list/data = list()
	data["words"] = get_formula_magic_word_entries()
	data["draft_words"] = draft_words.Copy()
	data["draft_parts"] = formula_magic_display_parts(draft_words)
	data["preview"] = preview.get_summary()
	data["draft_name"] = length(draft_name) ? draft_name : formula_magic_default_formula_name(draft_words)
	data["loaded_preset_index"] = loaded_preset_index
	data["loaded_preset_name"] = loaded_preset_name
	data["loaded_preset_changed"] = loaded_preset_index && (!formula_magic_word_lists_match(draft_words, loaded_preset_words) || (length(draft_name) && draft_name != loaded_preset_name))
	var/list/known_words = list()
	var/list/known_counts = H?.mind?.get_formula_magic_known_word_counts() || list()
	for(var/word_id in known_counts)
		if((known_counts[word_id] || 0) > 0)
			known_words += word_id
	data["known_words"] = known_words
	data["known_word_counts"] = known_counts
	data["progression"] = H?.mind?.get_formula_magic_progression_data() || list()
	data["school_points"] = H?.mind?.get_formula_magic_school_points() || list()
	data["form_points"] = H?.mind?.get_formula_magic_form_points() || list()
	data["school_names"] = formula_magic_school_names()
	data["school_access"] = H?.mind?.get_formula_magic_school_access() || list()
	data["form_names"] = formula_magic_form_names()
	data["form_unlocks"] = formula_magic_form_unlocks()
	data["presets"] = H?.mind?.get_formula_magic_presets() || list()
	data["formula_slot_limit"] = H?.mind?.get_formula_magic_formula_slot_limit() || 1
	data["max_mana"] = H?.max_stamina || 0
	var/list/draft_validation = H?.mind?.validate_formula_magic_word_list(draft_words) || list()
	data["draft_validation"] = draft_validation
	data["draft_export_json"] = H?.mind?.formula_magic_export_json(data["draft_name"], draft_words) || ""
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
		if("add_word")
			var/word_id = params["word_id"]
			if(istext(word_id) && H.mind.can_use_formula_magic_word(word_id))
				draft_words += formula_magic_normalize_word_id(word_id)
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
			draft_name = ""
			loaded_preset_index = 0
			loaded_preset_name = ""
			loaded_preset_words = list()
			SStgui.update_uis(src)
			return TRUE
		if("save_preset")
			var/list/validation = H.mind.validate_formula_magic_word_list(draft_words)
			if(!validation["valid"])
				to_chat(H, span_warning("The formula is not valid enough to save."))
				return TRUE
			var/raw_name = params["name"]
			var/name_source = (istext(raw_name) && length(raw_name)) ? raw_name : (draft_name || formula_magic_default_formula_name(draft_words))
			var/name = sanitize(copytext("[name_source]", 1, 48))
			var/saved_index = H.mind.save_formula_magic_preset(name, draft_words)
			if(saved_index)
				draft_name = name
				loaded_preset_index = saved_index
				loaded_preset_name = name
				loaded_preset_words = draft_words.Copy()
			SStgui.update_uis(src)
			return TRUE
		if("load_preset")
			var/index = text2num(params["index"])
			var/list/presets = H.mind.get_formula_magic_presets()
			if(index >= 1 && index <= length(presets))
				var/list/preset = presets[index]
				var/list/preset_words = preset["words"]
				draft_words = preset_words?.Copy() || list()
				draft_name = preset["name"] || formula_magic_default_formula_name(draft_words)
				loaded_preset_index = index
				loaded_preset_name = draft_name
				loaded_preset_words = draft_words.Copy()
				SStgui.update_uis(src)
			return TRUE
		if("delete_preset")
			var/index = text2num(params["index"])
			if(H.mind.delete_formula_magic_preset(index))
				if(index == loaded_preset_index)
					loaded_preset_index = 0
					loaded_preset_name = ""
					loaded_preset_words = list()
				else if(index < loaded_preset_index)
					loaded_preset_index--
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
					if(index == loaded_preset_index)
						draft_name = new_name
						loaded_preset_name = new_name
					SStgui.update_uis(src)
			return TRUE
		if("update_preset")
			var/list/validation = H.mind.validate_formula_magic_word_list(draft_words)
			if(!validation["valid"])
				to_chat(H, span_warning("The formula is not valid enough to update."))
				return TRUE
			H.mind.update_formula_magic_preset(text2num(params["index"]), draft_words)
			SStgui.update_uis(src)
			return TRUE
		if("update_loaded_preset")
			if(loaded_preset_index)
				var/list/validation = H.mind.validate_formula_magic_word_list(draft_words)
				if(!validation["valid"])
					to_chat(H, span_warning("The formula is not valid enough to update."))
					return TRUE
				var/raw_name = params["name"]
				var/name_source = (istext(raw_name) && length(raw_name)) ? raw_name : (draft_name || loaded_preset_name)
				if(H.mind.update_formula_magic_preset(loaded_preset_index, draft_words, name_source))
					draft_name = name_source
					loaded_preset_name = name_source
					loaded_preset_words = draft_words.Copy()
			SStgui.update_uis(src)
			return TRUE
		if("revert_loaded_preset")
			if(loaded_preset_index && length(loaded_preset_words))
				draft_words = loaded_preset_words.Copy()
				draft_name = loaded_preset_name
			SStgui.update_uis(src)
			return TRUE
		if("import_formula")
			var/raw_json = params["json"]
			if(istext(raw_json))
				var/list/imported = H.mind.formula_magic_import_json(raw_json, FALSE)
				if(islist(imported))
					draft_words = imported.Copy()
					draft_name = formula_magic_default_formula_name(draft_words)
					loaded_preset_index = 0
					loaded_preset_name = ""
					loaded_preset_words = list()
					SStgui.update_uis(src)
			return TRUE
		if("create_formula_scroll")
			var/list/validation = H.mind.validate_formula_magic_word_list(draft_words)
			if(!validation["valid"])
				to_chat(H, span_warning("The formula is not valid enough to scribe."))
				return TRUE
			var/obj/item/paper/scroll/formula_magic/scroll = new(get_turf(H))
			scroll.set_formula_magic_scroll(params["name"], draft_words, H.mind)
			H.put_in_hands(scroll, TRUE)
			return TRUE
		if("read_formula_scroll")
			var/obj/item/paper/scroll/formula_magic/scroll
			for(var/obj/item/paper/scroll/formula_magic/held in H.held_items)
				scroll = held
				break
			if(scroll)
				draft_words = scroll.formula_words.Copy()
				draft_name = scroll.formula_name || formula_magic_default_formula_name(draft_words)
				loaded_preset_index = 0
				loaded_preset_name = ""
				loaded_preset_words = list()
				SStgui.update_uis(src)
			return TRUE
		if("adjust_form")
			var/form_id = params["form_id"]
			var/delta = text2num(params["delta"])
			if(istext(form_id) && delta)
				H.mind.adjust_formula_magic_form_points(form_id, delta)
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
		if("adjust_school")
			var/school_id = params["school_id"]
			var/delta = text2num(params["delta"])
			if(istext(school_id) && delta)
				H.mind.adjust_formula_magic_school_points(school_id, delta)
				SStgui.update_uis(src)
			return TRUE
	return FALSE
