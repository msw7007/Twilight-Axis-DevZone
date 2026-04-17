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

/datum/preferences/proc/open_preferences_tgui(mob/user, tabchoice)
	if(!user || !user.client)
		return FALSE

	if(slot_randomized)
		load_character(default_slot)
		slot_randomized = FALSE

	handle_loadout_size(user)
	clean_loadout(user)

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

	data["book"] = list(
		"main_tab" = prefs_ui_main_tab,
		"sub_tab" = prefs_ui_sub_tab,
		"selected_region" = prefs_ui_selected_region,
	)

	data["header"] = build_preferences_header_data(user)
	data["character_page"] = build_preferences_character_page_data(user)
	data["settings_page"] = build_preferences_settings_page_data(user)

	return data

/datum/preferences/proc/build_preferences_header_data(mob/user)
	return list(
		"player_quality" = get_playerquality(user.ckey, text = TRUE),
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
			"player_quality" = get_playerquality(user.ckey, text = TRUE),
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
			"food" = culinary_preferences?.len ? "Configured" : "Not configured",
			"familiar" = familiar_prefs ? "Configured" : "Not configured",
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
				return open_preferences_tgui_menu(user, which)

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
			return process_link(user, list("preference" = "changeslot"))

		if("pq")
			return FALSE

		if("name")
			return process_link(user, list("preference" = "name", "task" = "input"))

		if("nickname")
			return process_link(user, list("preference" = "nickname", "task" = "input"))

		if("nickname_color")
			return process_link(user, list("preference" = "highlight_color", "task" = "input"))

		if("age")
			return process_link(user, list("preference" = "age", "task" = "input"))

		if("body_type")
			return process_link(user, list("preference" = "gender"))

		if("clothing_type")
			return process_link(user, list("preference" = "clothespref", "task" = "input"))

		if("titles_pref")
			return process_link(user, list("preference" = "titles", "task" = "input"))

		if("pronouns")
			return process_link(user, list("preference" = "pronouns", "task" = "input"))

		if("voice_pack")
			return process_link(user, list("preference" = "voicepack", "task" = "input"))

		if("voice_type")
			return process_link(user, list("preference" = "voicetype", "task" = "input"))

		if("voice_color")
			return process_link(user, list("preference" = "voice", "task" = "input"))

		if("voice_pitch")
			return process_link(user, list("preference" = "voice_pitch", "task" = "input"))

		if("faith")
			return process_link(user, list("preference" = "faith", "task" = "input"))

		if("patron")
			return process_link(user, list("preference" = "patron", "task" = "input"))

		if("domhand")
			return process_link(user, list("preference" = "domhand"))

		if("combat_music")
			return process_link(user, list("preference" = "combat_music", "task" = "input"))

		if("unrevivable")
			return process_link(user, list("preference" = "dnr"))

		if("race")
			return process_link(user, list("preference" = "species", "task" = "input"))

		if("subrace")
			return process_link(user, list("preference" = "subspecies", "task" = "input"))

		if("race_bonus")
			return process_link(user, list("preference" = "race_bonus_select", "task" = "input"))

		if("language")
			return process_link(user, list("preference" = "extra_language", "task" = "input"))

		if("origin")
			return process_link(user, list("preference" = "origin", "task" = "input"))

		if("food")
			return FALSE

		if("familiar")
			return FALSE

		if("statpack")
			return FALSE

		if("vice")
			return FALSE

		if("virtue")
			return FALSE

		if("descriptors")
			return process_link(user, list("preference" = "descriptors"))

		if("body_markings")
			return process_link(user, list("preference" = "markings"))

		if("customizers")
			return process_link(user, list("preference" = "customizers"))

		if("hairstyle")
			return process_link(user, list("preference" = "hairstyle", "task" = "input"))

		if("facial_hairstyle")
			return process_link(user, list("preference" = "facial_hairstyle", "task" = "input"))

		if("eyes")
			return process_link(user, list("preference" = "eyes", "task" = "input"))

		if("s_tone")
			return process_link(user, list("preference" = "s_tone", "task" = "input"))

		if("erpprefs")
			return process_link(user, list("preference" = "erpprefs", "task" = "input"))

	return FALSE
