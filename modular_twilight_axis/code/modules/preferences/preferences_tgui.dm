
/**
 * Preferences TGUI hub
 * Backend kept neutral; frontend may style it as a book.
 */

/datum/preferences/ShowChoices(mob/user, tabchoice)
	return open_preferences_tgui(user, tabchoice)

/datum/preferences
	var/prefs_ui_main_tab = "character"
	var/prefs_ui_sub_tab = "appearance"
	var/prefs_ui_selected_region = "head"
	var/prefs_ui_expanded_panel = null // "food" / "familiar"
	var/prefs_ui_food_mode = null // "food" / "drink"
	var/prefs_ui_food_target = null // culinary preference key

/datum/preferences/proc/open_preferences_tgui(mob/user, tabchoice)
	if(!user || !user.client)
		return FALSE

	if(slot_randomized)
		load_character(default_slot)
		slot_randomized = FALSE

	handle_loadout_size(user)
	clean_loadout(user)

	validate_culinary_preferences()

	if(!isnull(tabchoice))
		switch(tabchoice)
			if(0)
				prefs_ui_main_tab = "character"
				prefs_ui_sub_tab = "appearance"
			if(1)
				prefs_ui_main_tab = "settings"
				prefs_ui_sub_tab = "general"
			if(2)
				prefs_ui_main_tab = "settings"
				prefs_ui_sub_tab = "ooc"
			if(3)
				prefs_ui_main_tab = "settings"
				prefs_ui_sub_tab = "keybinds"

	open_preferences_tgui_window(user)
	return TRUE

/datum/preferences/proc/open_preferences_tgui_window(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PreferencesBook", "Character Book")
		ui.open()

/datum/preferences/ui_state(mob/user)
	return GLOB.tgui_always_state

/datum/preferences/ui_static_data(mob/user)
	return list(
		"main_tabs" = list(
			list("id" = "character", "name" = "Character"),
			list("id" = "loadout", "name" = "Loadout"),
			list("id" = "roles", "name" = "Roles"),
			list("id" = "settings", "name" = "Settings"),
		),
		"sub_tabs" = list(
			"character" = list(
				list("id" = "appearance", "name" = "Appearance"),
			),
			"loadout" = list(
				list("id" = "overview", "name" = "Overview"),
			),
			"roles" = list(
				list("id" = "overview", "name" = "Overview"),
			),
			"settings" = list(
				list("id" = "general", "name" = "General + OOC"),
				list("id" = "ooc", "name" = "OOC"),
				list("id" = "keybinds", "name" = "Keybinds"),
			),
		),
		"body_regions" = list(
			list("id" = "head", "name" = "Head"),
			list("id" = "face", "name" = "Face"),
			list("id" = "torso", "name" = "Torso"),
			list("id" = "arms", "name" = "Arms"),
			list("id" = "hands", "name" = "Hands"),
			list("id" = "legs", "name" = "Legs"),
			list("id" = "feet", "name" = "Feet"),
			list("id" = "organs", "name" = "Organs"),
		),
	)

/datum/preferences/ui_data(mob/user)
	var/list/data = list()

	validate_culinary_preferences()

	data["book"] = list(
		"main_tab" = prefs_ui_main_tab,
		"sub_tab" = prefs_ui_sub_tab,
		"selected_region" = prefs_ui_selected_region,
	)

	data["expanded_panel"] = prefs_ui_expanded_panel
	data["header"] = build_preferences_header_data(user)
	data["character_page"] = build_preferences_character_page_data(user)
	data["settings_page"] = build_preferences_settings_page_data(user)
	data["culinary_panel"] = build_preferences_culinary_panel_data()
	data["familiar_panel"] = build_preferences_familiar_panel_data()

	return data

/datum/preferences/proc/build_preferences_header_data(mob/user)
	var/pq_text = "Unknown"
	var/pq_color = "#ffffff"
	var/pq_html = "[get_playerquality(user.ckey, text = TRUE)]"
	var/color_pos = findtext(pq_html, "color:")
	if(color_pos)
		var/color_start = color_pos + length("color:")
		while((color_start <= length(pq_html)) && (copytext(pq_html, color_start, color_start + 1) in list(" ", "\t", "'", "\"")))
			color_start++

		var/color_end = color_start
		while(color_end <= length(pq_html) && !(copytext(pq_html, color_end, color_end + 1) in list(";", "'", "\"")))
			color_end++

		var/extracted_color = trim(copytext(pq_html, color_start, color_end))
		if(length(extracted_color))
			pq_color = extracted_color

	var/text_start = findtext(pq_html, ">")
	if(text_start)
		text_start++
		var/text_end = findtext(pq_html, "<", text_start)
		if(text_end > text_start)
			pq_text = html_decode(copytext(pq_html, text_start, text_end))
		else
			pq_text = html_decode(pq_html)
	else
		pq_text = html_decode(pq_html)

	return list(
		"player_quality_text" = pq_text,
		"player_quality_color" = pq_color,
		"real_name" = real_name,
		"nickname" = nickname,
		"nickname_color" = highlight_color ? "#[highlight_color]" : "#FF0000",
		"species" = pref_species ? pref_species.base_name : "Unknown",
		"subspecies" = pref_species ? pref_species.sub_name : "Unknown",
		"voice_pack" = voice_pack ? "[voice_pack]" : "Default",
	)

/datum/preferences/proc/build_preferences_character_page_data(mob/user)
	var/body_type = "Other"
	if(gender == MALE)
		body_type = "Masculine"
	else if(gender == FEMALE)
		body_type = "Feminine"

	var/datum/faith/selected_faith = null
	if(selected_patron?.associated_faith)
		selected_faith = GLOB.faithlist[selected_patron.associated_faith]

	var/race_bonus_display = "None"
	if(length(pref_species.custom_selection) && race_bonus)
		for(var/bonus in pref_species.custom_selection)
			if(bonus == race_bonus)
				race_bonus_display = bonus
				break

	var/lang_output = "None"
	if(ispath(extra_language, /datum/language))
		var/datum/language/selected_lang = extra_language
		lang_output = initial(selected_lang.name)

	var/musicname = (combat_music?.shortname ? combat_music.shortname : combat_music?.name)

	return list(
		"identity" = list(
			"real_name" = real_name,
			"age" = "[age]",
			"body_type" = body_type,
			"clothing_type" = clothes_pref,
			"nickname" = nickname,
			"titles_pref" = titles_pref,
			"pronouns" = "[pronouns]",
			"race" = pref_species ? pref_species.base_name : "Unknown",
			"subrace" = pref_species ? pref_species.sub_name : "Unknown",
			"race_bonus" = race_bonus_display,
			"language" = lang_output,
			"origin" = "[virtue_origin]",
		),
		"voice" = list(
			"voice_pack" = voice_pack ? "[voice_pack]" : "Default",
			"voice_type" = voice_type,
			"voice_color" = voice_color ? "#[voice_color]" : "#a0a0a0",
			"voice_pitch" = "[voice_pitch]",
			"combat_music" = musicname ? musicname : "None",
		),
		"lore" = list(
			"faith" = selected_faith?.name || "None",
			"god" = selected_patron?.name || "None",
			"dominance" = (domhand == 1 ? "Left-handed" : "Right-handed"),
			"unrevivable" = (dnr_pref ? "Yes" : "No"),
		),
		"prefs" = list(
			"food" = "Configured",
			"familiar" = "Configured",
			"statpack" = statpack ? "[statpack.name]" : "None",
			"vice" = virtue ? "[virtue]" : "None",
			"virtue" = virtuetwo ? "[virtuetwo]" : "None",
		),
		"descriptors" = descriptor_entries ? descriptor_entries.Copy() : list(),
		"selected_region" = build_preferences_region_editor_data(user, prefs_ui_selected_region),
	)

/datum/preferences/proc/build_preferences_region_editor_data(mob/user, region)
	var/list/options = list()

	switch(region)
		if("head")
			options += list(
				list("id" = "hairstyle", "name" = "Hair"),
				list("id" = "facial_hairstyle", "name" = "Facial Hair"),
			)

		if("face")
			options += list(
				list("id" = "eyes", "name" = "Eyes"),
				list("id" = "s_tone", "name" = "Skin"),
				list("id" = "descriptors", "name" = "Descriptors"),
			)

		if("torso")
			options += list(
				list("id" = "markings", "name" = "Body Markings"),
				list("id" = "customizers", "name" = "Customizers"),
			)

		if("arms", "hands", "legs", "feet")
			options += list(
				list("id" = "markings", "name" = "Body Markings"),
				list("id" = "customizers", "name" = "Customizers"),
			)

		if("organs")
			options += list(
				list("id" = "erpprefs", "name" = "ERP Preferences"),
			)

	return list(
		"id" = region,
		"name" = capitalize(region),
		"options" = options,
	)

/datum/preferences/proc/build_preferences_settings_page_data(mob/user)
	return list(
		"general" = list(
			"ambientocclusion" = ambientocclusion,
			"auto_fit_viewport" = auto_fit_viewport,
			"widescreenpref" = widescreenpref,
			"pixel_size" = "",
			"tgui_pref" = tgui_pref,
			"tgui_lock" = tgui_lock,
			"tgui_fancy" = tgui_fancy,
			"windowflashing" = windowflashing,
			"tgui_theme" = tgui_theme,
		),
		"ooc" = list(
			"ooccolor" = ooccolor,
			"asaycolor" = asaycolor,
			"UI_style" = UI_style,
			"UI_style_color" = "",
			"chat_on_map" = chat_on_map,
			"see_rc_emotes" = FALSE,
			"nickname" = nickname,
			"nickname_color" = highlight_color ? "#[highlight_color]" : "#FF0000",
		),
		"keybinds_notice" = "Use existing keybind logic from preferences backend.",
	)

/datum/preferences/proc/get_food_icon_src(obj/item/reagent_containers/food/snacks/food_type)
	if(!food_type)
		return null
	var/image/dummy = image(initial(food_type.icon), null, initial(food_type.icon_state), initial(food_type.layer))
	return "data:image/png;base64,[icon2base64(getFlatIcon(dummy))]"

/datum/preferences/proc/get_drink_icon_src(drink_quality)
	var/obj/item/reagent_containers/glass/icon_type
	if(drink_quality <= 0)
		icon_type = /obj/item/reagent_containers/glass/cup/wooden
	else if(drink_quality <= 1)
		icon_type = /obj/item/reagent_containers/glass/cup
	else if(drink_quality <= 2)
		icon_type = /obj/item/reagent_containers/glass/bottle
	else if(drink_quality <= 3)
		icon_type = /obj/item/reagent_containers/glass/cup/silver
	else
		icon_type = /obj/item/reagent_containers/glass/cup/golden

	var/image/dummy = image(initial(icon_type.icon), null, initial(icon_type.icon_state), initial(icon_type.layer))
	return "data:image/png;base64,[icon2base64(getFlatIcon(dummy))]"

/datum/preferences/proc/build_culinary_food_entry(food_type)
	if(!food_type)
		return list(
			"name" = "None",
			"quality" = "",
			"icon" = null,
			"path" = "",
		)
	var/obj/item/reagent_containers/food/snacks/food_instance = food_type
	var/name = capitalize(initial(food_instance.name))
	var/faretype = "?"
	for(var/list/food_data in GLOB.food_with_faretypes)
		if(food_data["type"] == food_type)
			faretype = "[food_data["faretype"]]"
			break
	return list(
		"name" = name,
		"quality" = faretype,
		"icon" = get_food_icon_src(food_type),
		"path" = "[food_type]",
	)

/datum/preferences/proc/build_culinary_drink_entry(drink_type)
	if(!drink_type)
		return list(
			"name" = "None",
			"quality" = "",
			"icon" = null,
			"path" = "",
		)
	var/datum/reagent/consumable/drink_instance = drink_type
	var/name = capitalize(initial(drink_instance.name))
	var/quality = "[initial(drink_instance.quality)]"
	return list(
		"name" = name,
		"quality" = quality,
		"icon" = get_drink_icon_src(initial(drink_instance.quality)),
		"path" = "[drink_type]",
	)

/datum/preferences/proc/get_culinary_target_label(target)
	switch(target)
		if(CULINARY_FAVOURITE_FOOD)
			return "Favourite Food"
		if(CULINARY_FAVOURITE_DRINK)
			return "Favourite Drink"
		if(CULINARY_HATED_FOOD)
			return "Hated Food"
		if(CULINARY_HATED_DRINK)
			return "Hated Drink"
	return "Select"

/datum/preferences/proc/build_preferences_culinary_panel_data()
	validate_culinary_preferences()

	var/list/panel = list(
		"fav_food" = build_culinary_food_entry(culinary_preferences[CULINARY_FAVOURITE_FOOD]),
		"fav_drink" = build_culinary_drink_entry(culinary_preferences[CULINARY_FAVOURITE_DRINK]),
		"hated_food" = build_culinary_food_entry(culinary_preferences[CULINARY_HATED_FOOD]),
		"hated_drink" = build_culinary_drink_entry(culinary_preferences[CULINARY_HATED_DRINK]),
		"picker_mode" = prefs_ui_food_mode,
		"picker_target" = prefs_ui_food_target,
		"picker_target_label" = get_culinary_target_label(prefs_ui_food_target),
		"food_options" = list(),
		"drink_options" = list(),
	)

	for(var/list/food_data in GLOB.food_with_faretypes)
		var/food_type = food_data["type"]
		panel["food_options"] += list(list(
			"name" = capitalize(food_data["name"]),
			"quality" = "[food_data["faretype"]]",
			"icon" = get_food_icon_src(food_type),
			"path" = "[food_type]",
		))

	for(var/list/drink_data in GLOB.drink_with_qualities)
		var/drink_type = drink_data["type"]
		panel["drink_options"] += list(list(
			"name" = capitalize(drink_data["name"]),
			"quality" = "[drink_data["quality"]]",
			"icon" = get_drink_icon_src(drink_data["quality"]),
			"path" = "[drink_type]",
		))

	return panel

/datum/preferences/proc/get_familiar_pronoun_text(pronoun_code)
	switch(pronoun_code)
		if(HE_HIM)
			return "he/him"
		if(SHE_HER)
			return "she/her"
		if(THEY_THEM)
			return "they/them"
		if(IT_ITS)
			return "it/its"
	return "they/them"

/datum/preferences/proc/get_familiar_display_name(specie)
	if(!specie)
		return "None selected"
	for(var/name in GLOB.familiar_types)
		if(GLOB.familiar_types[name] == specie)
			return "[name]"
	return "[specie]"

/datum/preferences/proc/build_preferences_familiar_panel_data()
	if(!familiar_prefs)
		return list()

	var/list/data = list(
		"name" = familiar_prefs.familiar_name ? familiar_prefs.familiar_name : "",
		"pronouns" = get_familiar_pronoun_text(familiar_prefs.familiar_pronouns),
		"headshot" = familiar_prefs.familiar_headshot_link,
		"flavortext" = familiar_prefs.familiar_flavortext ? familiar_prefs.familiar_flavortext : "",
		"ooc_notes" = familiar_prefs.familiar_ooc_notes ? familiar_prefs.familiar_ooc_notes : "",
		"ooc_extra_link" = familiar_prefs.familiar_ooc_extra_link ? familiar_prefs.familiar_ooc_extra_link : "",
		"specie_name" = get_familiar_display_name(familiar_prefs.familiar_specie),
		"lore_blurb" = familiar_prefs.familiar_specie ? GLOB.familiar_lore_blurbs[familiar_prefs.familiar_specie] : "",
		"in_queue" = (parent in GLOB.familiar_queue),
	)
	return data

/datum/preferences/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	var/mob/user = parent?.mob
	if(!user && ui)
		user = ui.user

	switch(action)
		if("set_main_tab")
			var/new_tab = params["tab"]
			if(new_tab)
				prefs_ui_main_tab = new_tab
				switch(prefs_ui_main_tab)
					if("character")
						prefs_ui_sub_tab = "appearance"
					if("loadout", "roles")
						prefs_ui_sub_tab = "overview"
					if("settings")
						prefs_ui_sub_tab = "general"
			return TRUE

		if("set_sub_tab")
			var/new_sub_tab = params["sub_tab"]
			if(new_sub_tab)
				prefs_ui_sub_tab = new_sub_tab
			return TRUE

		if("select_body_region")
			var/new_region = params["region"]
			if(new_region)
				prefs_ui_selected_region = new_region
			return TRUE

		if("set_pref")
			var/pref_id = params["pref_id"]
			var/value = params["value"]
			apply_preferences_tgui_pref(pref_id, value, user)
			save_preferences()
			return TRUE

		if("toggle_bool")
			var/pref_id = params["pref_id"]
			apply_preferences_tgui_toggle(pref_id, user)
			save_preferences()
			return TRUE

		if("toggle_panel")
			var/panel = params["panel"]
			if(prefs_ui_expanded_panel == panel)
				prefs_ui_expanded_panel = null
				prefs_ui_food_mode = null
				prefs_ui_food_target = null
			else
				prefs_ui_expanded_panel = panel
				if(panel != "food")
					prefs_ui_food_mode = null
					prefs_ui_food_target = null
			if(ui)
				ui.send_update()
			return TRUE

		if("culinary_open_picker")
			prefs_ui_expanded_panel = "food"
			prefs_ui_food_mode = params["mode"]
			prefs_ui_food_target = params["target"]
			if(ui)
				ui.send_update()
			return TRUE

		if("culinary_close_picker")
			prefs_ui_food_mode = null
			prefs_ui_food_target = null
			if(ui)
				ui.send_update()
			return TRUE

		if("culinary_select")
			var/selected_path = text2path(params["path"])
			if(selected_path && prefs_ui_food_target)
				var/opposite_preference = null
				switch(prefs_ui_food_target)
					if(CULINARY_FAVOURITE_FOOD)
						opposite_preference = CULINARY_HATED_FOOD
					if(CULINARY_HATED_FOOD)
						opposite_preference = CULINARY_FAVOURITE_FOOD
					if(CULINARY_FAVOURITE_DRINK)
						opposite_preference = CULINARY_HATED_DRINK
					if(CULINARY_HATED_DRINK)
						opposite_preference = CULINARY_FAVOURITE_DRINK

				if(opposite_preference && culinary_preferences[opposite_preference] == selected_path)
					to_chat(user, span_warning("You can't set the same item as both favorite and hated!"))
				else
					culinary_preferences[prefs_ui_food_target] = selected_path
					save_preferences()

			prefs_ui_food_mode = null
			prefs_ui_food_target = null
			if(ui)
				ui.send_update()
			return TRUE

		if("culinary_reset")
			reset_culinary_preferences()
			save_preferences()
			if(ui)
				ui.send_update()
			return TRUE

		if("familiar_edit")
			var/field = params["field"]
			if(!familiar_prefs)
				return FALSE

			switch(field)
				if("familiar_name")
					var/new_name = input(user, "Choose your Familiar character's name:", "Identity", familiar_prefs.familiar_name) as text|null
					if(isnull(new_name))
						return TRUE
					if(new_name)
						new_name = reject_bad_name(new_name)
						if(new_name)
							familiar_prefs.familiar_name = new_name
							to_chat(user, span_notice("Familiar name set to [new_name]."))
						else
							to_chat(user, span_warning("Invalid familiar name."))
				if("familiar_headshot")
					to_chat(user, span_notice("Please use a relatively SFW image of the head and shoulder area."))
					to_chat(user, span_notice("Ensure it's a direct image link."))
					var/new_headshot_link = input(user, "Input the headshot link (https):", "Headshot", familiar_prefs.familiar_headshot_link) as text|null
					if(isnull(new_headshot_link))
						return TRUE
					if(new_headshot_link == "")
						familiar_prefs.familiar_headshot_link = null
					else if(valid_headshot_link(user, new_headshot_link))
						familiar_prefs.familiar_headshot_link = new_headshot_link
						to_chat(user, span_notice("Successfully updated Familiar headshot picture."))
				if("familiar_flavortext")
					to_chat(user, span_notice("Flavortext should not include nonphysical nonsensory attributes such as backstory or internal thoughts."))
					var/new_flavortext = input(user, "Input your Familiar character description:", "Flavortext", familiar_prefs.familiar_flavortext) as message|null
					if(isnull(new_flavortext))
						return TRUE
					if(new_flavortext == "")
						familiar_prefs.familiar_flavortext = null
						familiar_prefs.familiar_flavortext_display = null
					else
						familiar_prefs.familiar_flavortext = new_flavortext
						var/ft = html_encode(parsemarkdown_basic(familiar_prefs.familiar_flavortext))
						ft = replacetext(ft, "\n", "<BR>")
						familiar_prefs.familiar_flavortext_display = ft
				if("familiar_ooc_notes")
					var/new_ooc_notes = input(user, "Input your OOC preferences:", "OOC notes", familiar_prefs.familiar_ooc_notes) as message|null
					if(isnull(new_ooc_notes))
						return TRUE
					if(new_ooc_notes == "")
						familiar_prefs.familiar_ooc_notes = null
						familiar_prefs.familiar_ooc_notes_display = null
					else
						familiar_prefs.familiar_ooc_notes = new_ooc_notes
						var/ooc = html_encode(parsemarkdown_basic(familiar_prefs.familiar_ooc_notes))
						ooc = replacetext(ooc, "\n", "<BR>")
						familiar_prefs.familiar_ooc_notes_display = ooc
				if("familiar_ooc_extra")
					var/link = input(user, "Input the accessory link (https)", "Familiar OOC Extra", familiar_prefs.familiar_ooc_extra_link) as text|null
					if(isnull(link))
						return TRUE
					if(link == "")
						familiar_prefs.familiar_ooc_extra = null
						familiar_prefs.familiar_ooc_extra_link = null
					else if(link == " ")
						familiar_prefs.familiar_ooc_extra = null
						familiar_prefs.familiar_ooc_extra_link = null
					else
						var/static/list/valid_ext = list("jpg", "jpeg", "png", "gif", "mp4", "mp3")
						if(valid_headshot_link(user, link, FALSE, valid_ext))
							familiar_prefs.familiar_ooc_extra_link = link
							var/ext = lowertext(splittext(link, ".")[length(splittext(link, "."))])
							switch(ext)
								if("jpg", "jpeg", "png", "gif")
									familiar_prefs.familiar_ooc_extra = "<div align='center'><br><img src='[link]'/></div>"
								if("mp4")
									familiar_prefs.familiar_ooc_extra = "<div align='center'><br><video width='288' height='288' controls><source src='[link]' type='video/mp4'></video></div>"
								if("mp3")
									familiar_prefs.familiar_ooc_extra = "<div align='center'><br><audio controls><source src='[link]' type='audio/mp3'></audio></div>"
			save_preferences()
			if(ui)
				ui.send_update()
			return TRUE

		if("familiar_pick_pronouns")
			if(!familiar_prefs)
				return FALSE

			var/list/pronoun_options = list(
				"he/him" = HE_HIM,
				"she/her" = SHE_HER,
				"they/them" = THEY_THEM,
				"it/its" = IT_ITS,
			)

			var/choice = tgui_input_list(user, "Select your familiar's pronouns:", "PRONOUNS", pronoun_options)
			if(choice)
				familiar_prefs.familiar_pronouns = pronoun_options[choice]
				save_preferences()

			if(ui)
				ui.send_update()
			SStgui.update_uis(src)
			return TRUE

		if("familiar_pick_specie")
			if(!familiar_prefs)
				return FALSE

			var/list/all_types = GLOB.familiar_types.Copy()
			var/choice = tgui_input_list(user, "Select a Familiar type:", "FAMILIAR TYPE", all_types)
			if(choice)
				var/specie_path = all_types[choice]
				if(specie_path)
					familiar_prefs.familiar_specie = specie_path
					save_preferences()

			if(ui)
				ui.send_update()
			SStgui.update_uis(src)
			return TRUE

		if("familiar_toggle_queue")
			if(user.client in GLOB.familiar_queue)
				GLOB.familiar_queue -= user.client
				to_chat(user, span_notice("You have been removed from the Familiar queue."))
			else
				if(!familiar_prefs?.familiar_name || !familiar_prefs?.familiar_flavortext_display || !familiar_prefs?.familiar_specie)
					to_chat(user, span_warning("You must set your Familiar's name, description, and type before joining the queue."))
				else
					GLOB.familiar_queue += user.client
					to_chat(user, span_notice("You have been added to the Familiar queue."))
			if(ui)
				ui.send_update()
			return TRUE

		if("open_loadout")
			if(user)
				handle_loadout_size(user)
				clean_loadout(user)
				loadoutpanel.ui_interact(user)
			return TRUE

		if("open_roles")
			if(user)
				return process_link(user, list(
					"preference" = "job",
					"task" = "menu",
				))

		if("open_pref_menu")
			var/which = params["which"]
			if(user && which)
				var/result = open_preferences_tgui_menu(user, which)
				if(result && ui)
					SStgui.update_uis(src)
				return result

		if("open_theme_picker")
			if(user)
				var/datum/theme_picker/picker = new(user)
				picker.ui_interact(user)
			return TRUE

		if("save_prefs")
			save_preferences()
			save_character()
			if(user)
				to_chat(user, span_notice("CHARACTER SAVED."))
			return TRUE

		if("done_prefs")
			save_preferences()
			save_character()
			if(ui)
				ui.close()
			return TRUE

		if("toggle_unrevivable")
			dnr_pref = !dnr_pref
			save_preferences()
			save_character()

			if(ui)
				ui.send_update()
			SStgui.update_uis(src)

			return TRUE

	return FALSE

/datum/preferences/proc/apply_preferences_tgui_pref(pref_id, value, mob/user)
	switch(pref_id)
		if("real_name")
			real_name = sanitize_name(value)

		if("nickname")
			nickname = copytext_char("[value]", 1, MAX_NAME_LEN)

		if("nickname_color")
			highlight_color = sanitize_hexcolor(value, 6, TRUE, "#FF0000")

		if("ooccolor")
			ooccolor = sanitize_hexcolor(value, 6, TRUE, GLOB.normal_ooc_colour)

		if("asaycolor")
			asaycolor = sanitize_hexcolor(value, 6, TRUE, "#ff4500")

		if("UI_style")
			if(value in GLOB.available_ui_styles)
				UI_style = value

	if(user)
		update_preview_icon()

/datum/preferences/proc/apply_preferences_tgui_toggle(pref_id, mob/user)
	switch(pref_id)
		if("ambientocclusion")
			ambientocclusion = !ambientocclusion
		if("auto_fit_viewport")
			auto_fit_viewport = !auto_fit_viewport
		if("widescreenpref")
			widescreenpref = !widescreenpref
		if("tgui_pref")
			tgui_pref = !tgui_pref
		if("tgui_lock")
			tgui_lock = !tgui_lock
		if("tgui_fancy")
			tgui_fancy = !tgui_fancy
		if("windowflashing")
			windowflashing = !windowflashing
		if("chat_on_map")
			chat_on_map = !chat_on_map
		if("hotkeys")
			hotkeys = !hotkeys
		if("buttons_locked")
			buttons_locked = !buttons_locked

/datum/preferences/proc/open_preferences_tgui_menu(mob/user, which)
	if(!user || !user.client || !which)
		return FALSE

	switch(which)
		if("changeslot")
			var/list/choices = list()
			if(path)
				var/savefile/S = new /savefile(path)
				if(S)
					for(var/i = 1, i <= max_save_slots, i++)
						var/name
						S.cd = "/character[i]"
						S["real_name"] >> name
						if(!name)
							name = "Slot[i]"
						choices[name] = i

			var/choice = tgui_input_list(user, "CHOOSE A HERO", "ROGUETOWN", choices)
			if(choice)
				choice = choices[choice]
				if(!load_character(choice))
					random_character(null, FALSE, FALSE)
					save_character()
				return TRUE
			return FALSE

		if("pq")
			check_pq_menu(user.ckey)
			return TRUE

		if("name")
			var/new_name = tgui_input_text(user, "The name of this vessel?", "IDENTITY", real_name, encode = FALSE)
			if(isnull(new_name))
				return FALSE
			if(new_name)
				new_name = reject_bad_name(new_name)
				if(new_name)
					real_name = new_name
					return TRUE
				to_chat(user, "<font color='red'>Invalid name. Your name should be at least 2 and at most [MAX_NAME_LEN] characters long. It may only contain the characters A-Z, a-z, -, ', . and ,.</font>")
			return FALSE

		if("nickname")
			var/new_name = tgui_input_text(user, "Choose your character's nickname (For Highlighting):", "NICKNAME", nickname, encode = FALSE)
			if(isnull(new_name))
				return FALSE
			if(new_name)
				new_name = reject_bad_name(new_name)
				if(new_name)
					nickname = new_name
					return TRUE
				to_chat(user, "<font color='red'>Invalid name. Your name should be at least 2 and at most [MAX_NAME_LEN] characters long. It may only contain the characters A-Z, a-z, -, ', . and ,.</font>")
			return FALSE

		if("nickname_color")
			var/new_color = color_pick_sanitized(user, "Choose your character's nickname highlight color:", "Character Preference", "#"+highlight_color)
			if(new_color)
				highlight_color = sanitize_hexcolor(new_color)
				return TRUE
			return FALSE

		if("age")
			var/new_age = tgui_input_list(user, "Choose your character's age (18-[pref_species.max_age])", "YILS LIVED", pref_species.possible_ages)
			if(new_age)
				age = new_age

				var/list/hairs
				if((age == AGE_OLD) && (OLDGREY in pref_species.species_traits))
					hairs = pref_species.get_oldhc_list()
				else
					hairs = pref_species.get_hairc_list()

				hair_color = hairs[pick(hairs)]
				facial_hair_color = hair_color

				switch(age)
					if(AGE_ADULT)
						to_chat(user, "You preside in your 'prime', whatever this may be, and gain no bonus nor endure any penalty for your time spent alive.")
					if(AGE_MIDDLEAGED)
						to_chat(user, "Muscles ache and joints begin to slow as Aeon's grasp begins to settle upon your shoulders. (-1 SPD, +1 WIL +1 FOR)")
					if(AGE_OLD)
						to_chat(user, "In a place as lethal as PSYDONIA, the elderly are all but marvels... or beneficiaries of the habitually privileged. (-1 STR, -2 SPE, -1 PER, -2 CON, +2 INT, +1 FOR)")

				ResetJobs()
				to_chat(user, "<font color='red'>Classes reset.</font>")
				return TRUE
			return FALSE

		if("body_type")
			var/pickedGender = "male"
			if(gender == "male")
				pickedGender = "female"
			if(pickedGender && pickedGender != gender)
				gender = pickedGender
				to_chat(user, "<font color='red'>Your character will now use a [friendlyGenders[pickedGender]] sprite.</font>")
				genderize_customizer_entries()
				return TRUE
			return FALSE

		if("clothing_type")
			if(clothes_pref == CLOTHES_M)
				clothes_pref = CLOTHES_F
			else
				clothes_pref = CLOTHES_M
			to_chat(user, "<font color='red'>Your character's titles are now [clothes_pref].</font>")
			return TRUE

		if("titles_pref")
			if(titles_pref == TITLES_M)
				titles_pref = TITLES_F
			else
				titles_pref = TITLES_M
			to_chat(user, "<font color='red'>Your character's titles are now [titles_pref].</font>")
			return TRUE

		if("pronouns")
			var/pronouns_input = tgui_input_list(user, "Choose your character's pronouns", "PRONOUNS", GLOB.pronouns_list)
			if(pronouns_input)
				pronouns = pronouns_input
				ResetJobs()
				to_chat(user, "<font color='red'>Your character's pronouns are now [pronouns].</font>")
				to_chat(user, "<font color='red'><b>Your classes have been reset.</b></font>")
				return TRUE
			return FALSE

		if("voice_pack")
			var/voicepack_input = tgui_input_list(user, "Choose your character's emote voice pack", "VOICE PACK", GLOB.voice_packs_list)
			if(voicepack_input)
				voice_pack = voicepack_input
				if(voicepack_input != "Default")
					to_chat(user, span_red("<font color='red'>Your character will now audibly emote with a [lowertext(voicepack_input)] affect.") + span_notice("<br>This will override your Voice Identity and Class-specific voice packs.</font>"))
				else
					to_chat(user, "<font color='red'>Your character will now audibly emote in accordance to their Voice Identity and any Racial / Class-specific voice packs.</font>")
				return TRUE
			return FALSE

		if("voice_type")
			var/voicetype_input = tgui_input_list(user, "Choose your character's voice type", "VOICE TYPE", GLOB.voice_types_list)
			if(voicetype_input)
				voice_type = voicetype_input
				to_chat(user, "<font color='red'>Your character will now vocalize with a [lowertext(voice_type)] affect.</font>")
				return TRUE
			return FALSE

		if("voice_color")
			var/new_voice = input(user, "Choose your character's voice color:", "Character Preference", "#"+voice_color) as color|null
			if(new_voice)
				if(color_hex2num(new_voice) < 230)
					to_chat(user, "<font color='red'>This voice color is too dark for mortals.</font>")
					return FALSE
				voice_color = sanitize_hexcolor(new_voice)
				return TRUE
			return FALSE

		if("voice_pitch")
			var/new_voice_pitch = tgui_input_number(user, "Choose your character's voice pitch ([MIN_VOICE_PITCH] to [MAX_VOICE_PITCH], lower is deeper):", "Voice Pitch", voice_pitch, MAX_VOICE_PITCH, MIN_VOICE_PITCH, round_value = FALSE)
			if(new_voice_pitch)
				if(new_voice_pitch < MIN_VOICE_PITCH || new_voice_pitch > MAX_VOICE_PITCH)
					to_chat(user, "<font color='red'>Value must be between [MIN_VOICE_PITCH] and [MAX_VOICE_PITCH].</font>")
					return FALSE
				voice_pitch = new_voice_pitch
				return TRUE
			return FALSE

		if("faith")
			var/list/faiths_named = list()
			for(var/path as anything in GLOB.preference_faiths)
				var/datum/faith/faith = GLOB.faithlist[path]
				if(!faith.name)
					continue
				faiths_named[faith.name] = faith

			var/faith_input = tgui_input_list(user, "The world rots. Which truth you bear?", "FAITH", faiths_named)
			if(faith_input)
				var/datum/faith/faith = faiths_named[faith_input]
				to_chat(user, "<font color='yellow'>Вера: [faith.translated_name]</font>")
				to_chat(user, "Описание: [faith.desc]")
				to_chat(user, "<font color='red'>Последователи: [faith.worshippers]</font>")
				selected_patron = GLOB.patronlist[faith.godhead] || GLOB.patronlist[pick(GLOB.patrons_by_faith[faith_input])]
				return TRUE
			return FALSE

		if("patron")
			var/list/patrons_named = list()
			for(var/path as anything in GLOB.patrons_by_faith[selected_patron?.associated_faith || initial(default_patron.associated_faith)])
				var/datum/patron/patron = GLOB.patronlist[path]
				if(!patron.name)
					continue
				patrons_named[patron.name] = patron

			var/god_input = tgui_input_list(user, "The first amongst many.", "PATRON", patrons_named)
			if(god_input)
				selected_patron = patrons_named[god_input]
				to_chat(user, "<font color='yellow'>Покровитель: [selected_patron.translated_name]</font>")
				to_chat(user, "<font color='#FFA500'>Домены: [selected_patron.domain]</font>")
				to_chat(user, "Описание: [selected_patron.desc]")
				to_chat(user, "<font color='red'>Последователи: [selected_patron.worshippers]</font>")
				return TRUE
			return FALSE

		if("domhand")
			if(domhand == 1)
				domhand = 2
			else
				domhand = 1
			return TRUE

		if("combat_music")
			if(!combat_music_helptext_shown)
				to_chat(user, span_notice("<span class='bold'>Combat Music Override</span>\n") + \
				"Options other than \"Default\" override whatever the game dynamically sets for you, \
				which is influenced by your job class, villain status, or certain events.\n\
				You can change this later through \"Combat Mode Music\" in the Options tab.\"</span>")
				combat_music_helptext_shown = TRUE

			var/track_select = tgui_input_list(user, "To you, the Signal sounds like:", "COMBAT MUSIC", GLOB.cmode_tracks_by_name, combat_music?.name)
			if(track_select)
				combat_music = GLOB.cmode_tracks_by_name[track_select]
				to_chat(user, span_notice("Selected track: <b>[track_select]</b>."))
				if(combat_music.desc)
					to_chat(user, "<i>[combat_music.desc]</i>")
				if(combat_music.credits)
					to_chat(user, span_info("Song name: <b>[combat_music.credits]</b>"))
				return TRUE
			return FALSE

		if("race")
			var/list/species = list()
			for(var/A in GLOB.roundstart_races)
				var/datum/species/race = GLOB.species_list[A]
				race = new race()
				if(user.client)
					if(race.patreon_req > user.client.patreonlevel())
						continue
					if(race.is_subrace == TRUE)
						continue
					if(race.base_name == pref_species.base_name)
						continue
				else
					continue
				species[race.base_name] += race

			species = sortList(species)

			var/result = tgui_input_list(user, "By what shape are you bound?", "RACE", species)
			if(result)
				var/datum/species/race_chosen = species[result]
				set_new_race(race_chosen, user)
				return TRUE
			return FALSE

		if("subrace")
			var/list/species = list()
			for(var/A in GLOB.roundstart_races)
				var/datum/species/race = GLOB.species_list[A]
				race = new race()
				if(user.client)
					if(race.base_name != pref_species.base_name)
						continue
					if(race.sub_name == pref_species.sub_name)
						continue
				else
					continue
				species[race.sub_name] += race

			var/result = tgui_input_list(user, "By what shape are you bound?", "SUBRACE", species)
			if(result)
				var/datum/species/subrace_chosen = species[result]
				set_new_race(subrace_chosen, user)
				return TRUE
			return FALSE

		if("race_bonus")
			if(length(pref_species.custom_selection))
				var/choice = tgui_input_list(user, "What has fate blessed your race with?", "BONUS", pref_species.custom_selection)
				if(choice)
					race_bonus = choice
					return TRUE
			return FALSE

		if("language")
			var/static/list/selectable_languages = list(
				/datum/language/elvish,
				/datum/language/dwarvish,
				/datum/language/orcish,
				/datum/language/hellspeak,
				/datum/language/draconic,
				/datum/language/raneshi,
				/datum/language/grenzelhoftian,
				/datum/language/kazengunese,
				/datum/language/lingyuese,
				/datum/language/gyedzenese,
				/datum/language/valorian,
				/datum/language/etruscan,
				/datum/language/gronnic,
				/datum/language/otavan,
				/datum/language/aavnic,
			)

			var/list/choices = list("None")
			for(var/language in selectable_languages)
				if(language in pref_species.languages)
					continue
				var/datum/language/a_language = new language()
				choices[a_language.name] = language

			var/chosen_language = tgui_input_list(user, "Choose your character's extra language:", "EXTRA LANGUAGE", choices)
			if(chosen_language)
				if(chosen_language == "None")
					extra_language = "None"
				else
					extra_language = choices[chosen_language]
				return TRUE
			return FALSE

		if("origin")
			var/datum/origin_picker_panel/origin_picker = new(src)
			origin_picker.ui_interact(user)
			return TRUE

		if("statpack")
			return FALSE

		if("vice")
			return FALSE

		if("virtue")
			return FALSE

		if("descriptors")
			show_descriptors_ui(user)
			return TRUE

		if("body_markings")
			ShowMarkings(user)
			return TRUE

		if("customizers")
			ShowCustomizers(user)
			return TRUE

		// if("hairstyle")
		// 	var/list/listy = pref_species.get_hair_list()
		// 	var/new_hair = tgui_input_list(user, "Choose your character's hairstyle:", "HAIR", listy)
		// 	if(new_hair)
		// 		hairstyle = new_hair
		// 		return TRUE
		// 	return FALSE

		// if("facial_hairstyle")
		// 	var/list/listy = pref_species.get_facial_hair_list()
		// 	var/new_facial_hair = tgui_input_list(user, "Choose your character's facial hairstyle:", "FACIAL HAIR", listy)
		// 	if(new_facial_hair)
		// 		facial_hairstyle = new_facial_hair
		// 		return TRUE
		// 	return FALSE

		// if("eyes")
		// 	var/list/listy = GLOB.eye_colors
		// 	var/new_eyes = tgui_input_list(user, "Choose your character's eye color:", "EYES", listy)
		// 	if(new_eyes)
		// 		eye_color = listy[new_eyes]
		// 		return TRUE
		// 	return FALSE

		if("s_tone")
			var/list/listy = pref_species.get_skin_list()
			var/new_s_tone = tgui_input_list(user, "Choose your character's skin tone:", "SKINTONE", listy)
			if(new_s_tone)
				skin_tone = listy[new_s_tone]
				features["mcolor"] = sanitize_hexcolor(skin_tone)
				try_update_mutant_colors()
				return TRUE
			return FALSE

		if("erpprefs")
			to_chat(user, "<span class='notice'>["<span class='bold'>Erotic Roleplay preferences. If you put 'anything goes' or 'no limits' here, do not be surprised if people take you up on it.</span>"]</span>")
			to_chat(user, "<font color = '#d6d6d6'>Leave blank to clear.</font>")
			var/new_erpprefs = tgui_input_text(user, "Input your preferences:", "ERP Preferences", erpprefs, multiline = TRUE, encode = FALSE, bigmodal = TRUE)
			if(isnull(new_erpprefs))
				return FALSE
			if(new_erpprefs == "")
				erpprefs = null
				erpprefs_cached = null
				to_chat(user, "<span class='notice'>Successfully deleted ERP preferences.</span>")
				return TRUE
			erpprefs = new_erpprefs
			erpprefs_cached = parsemarkdown_basic(html_encode(erpprefs), hyperlink = TRUE)
			to_chat(user, "<span class='notice'>Successfully updated ERP Preferences.</span>")
			log_game("[user] has set their ERP preferences'.")
			return TRUE

	return FALSE

/datum/preferences/proc/open_pq_tgui(mob/user)
	if(!user || !user.client)
		return FALSE

	var/datum/pq_viewer/V = new(user.ckey)
	V.ui_interact(user)

	return TRUE
