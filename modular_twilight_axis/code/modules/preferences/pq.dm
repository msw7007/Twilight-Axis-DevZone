
/datum/pq_viewer
	var/target_ckey

/datum/pq_viewer/New(_ckey)
	. = ..()
	target_ckey = ckey(_ckey)

/datum/pq_viewer/ui_state(mob/user)
	return GLOB.tgui_always_state

/datum/pq_viewer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PreferencesPQ", "Player Quality")
		ui.open()

/datum/pq_viewer/ui_data(mob/user)
	var/list/data = list()

	var/canonical_ckey = replacetext(replacetext(replacetext(replacetext(lowertext(target_ckey), " ", ""), "_", ""), ".", ""), "-", "")
	var/folder_prefix = copytext(canonical_ckey, 1, 2)

	var/pq_html = "[get_playerquality(canonical_ckey, TRUE, TRUE)]"
	var/pq_color = "#ffffff"

	var/color_pos = findtext(pq_html, "color:")
	if(color_pos)
		var/start = color_pos + length("color:")
		while((start <= length(pq_html)) && (copytext(pq_html, start, start + 1) in list(" ", "\t", "'", "\"")))
			start++

		var/end = start
		while(end <= length(pq_html) && !(copytext(pq_html, end, end + 1) in list(";", "'", "\"")))
			end++

		pq_color = trim(copytext(pq_html, start, end))

	data["pq_text"] = strip_html_tags(pq_html)
	data["pq_color"] = pq_color
	data["pq_value"] = get_playerquality(canonical_ckey, FALSE, TRUE)
	data["commends"] = get_commends(canonical_ckey)
	data["round_points"] = get_roundpoints(canonical_ckey)
	data["rounds_survived"] = get_roundsplayed(canonical_ckey)

	var/list/entries = list()
	var/file_path = "data/player_saves/[folder_prefix]/[canonical_ckey]/playerquality.txt"

	if(fexists(file_path))
		var/list/listy = world.file2list(file_path)
		for(var/i = listy.len to 1 step -1)
			if(listy[i])
				entries += list(list(
					"text" = listy[i]
				))

	data["entries"] = entries

	return data

/proc/strip_html_tags(text)
	var/result = ""
	var/inside = FALSE

	for(var/i = 1 to length(text))
		var/c = copytext(text, i, i + 1)
		if(c == "<")
			inside = TRUE
			continue
		if(c == ">")
			inside = FALSE
			continue
		if(!inside)
			result += c

	return result
