/mob/living/carbon/human/examine(mob/user)
	. = ..()
	var/t = get_romance_partners_text()
	if(t)
		. += "<span class='love_mid'>[t]</span>"

/mob/living/carbon/human/proc/get_romance_partners_text()
	var/list/sessions = return_sessions_with_user(src)
	if(!length(sessions))
		return null

	var/list/names = list()
	for(var/datum/sex_session_tgui/S in sessions)
		for(var/mob/living/carbon/human/M in S.partners)
			if(M == src)
				continue
			if(!(M.name in names))
				names += M.name

	if(!length(names))
		return null

	return "[src] тесно сплетается с [english_list(names)]."

/mob/living/carbon/human/proc/get_examine_details()
	var/list/details = list()
	// ...
	var/t = get_romance_partners_text()
	if(t)
		details["romance"] = t
	return details
