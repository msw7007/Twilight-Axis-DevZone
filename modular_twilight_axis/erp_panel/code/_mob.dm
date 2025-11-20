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

/mob/living/carbon/human/proc/get_sex_organs()
	var/list/result = list()
	var/list/seen = list()

	for(var/obj/item/organ/O in internal_organs)
		if(O.sex_organ && !(O.sex_organ in seen))
			seen += O.sex_organ
			result += O.sex_organ

	for(var/obj/item/bodypart/B in bodyparts)
		if(B.sex_organ && !(B.sex_organ in seen))
			seen += B.sex_organ
			result += B.sex_organ

	return result

/mob/living/carbon/human/proc/get_sex_organs_by_type(organ_type)
	var/list/result = list()
	for(var/datum/sex_organ/O in get_sex_organs())
		if(O.organ_type == organ_type)
			result += O
	return result

/mob/living/carbon/human/proc/get_sex_organ_by_type(organ_type, only_free = FALSE)
	for(var/datum/sex_organ/O in get_sex_organs())
		if(O.organ_type != organ_type)
			continue
		if(only_free && (O.is_active()))
			continue
		return O
	return null

/mob/living/carbon/human/proc/reset_sex_organs_after_sleep()
	for(var/datum/sex_organ/O in get_sex_organs())
		if(!O)
			continue
		O.reset_after_sleep()

/mob/living/carbon/human/handle_sleep()
	. = ..()
	if(IsSleeping())
		reset_sex_organs_after_sleep()
