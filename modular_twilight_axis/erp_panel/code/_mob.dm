/mob/living/carbon/human
	var/datum/weakref/sex_surrender_ref

/mob/living/carbon/human/proc/set_sex_surrender_to(mob/living/carbon/human/M)
	if(M)
		sex_surrender_ref = WEAKREF(M)
	else
		sex_surrender_ref = null

/mob/living/carbon/human/proc/is_surrendering_to(mob/living/carbon/human/M)
	if(!M || !sex_surrender_ref)
		return FALSE

	var/mob/living/carbon/human/target = sex_surrender_ref.resolve()
	if(!target || QDELETED(target))
		sex_surrender_ref = null
		return FALSE

	return target == M

/mob/living/carbon/human/examine(mob/user)
	. = ..()
	var/t = get_sex_examine_text()
	if(t)
		. += "<span class='love_mid'>[t]</span>"

/mob/living/carbon/human/proc/get_sex_examine_text()
	var/list/sessions = return_sessions_with_user_tgui(src)
	if(!length(sessions))
		return null

	var/list/parts = list()
	var/list/active_names = list()

	for(var/datum/sex_session_tgui/S in sessions)
		if(!length(S.current_actions))
			continue

		var/list/participants = list()

		if(S.user && S.user != src)
			participants |= S.user
		if(S.target && S.target != src)
			participants |= S.target

		for(var/mob/living/carbon/human/M in S.partners)
			if(M != src)
				participants |= M

		for(var/mob/living/carbon/human/M2 in participants)
			if(!(M2.name in active_names))
				active_names += M2.name

	if(active_names.len)
		parts += "[src] тесно сплетается с [english_list(active_names)]."

	if(has_status_effect(/datum/status_effect/mouth_full))
		parts += "[src] выглядит так, будто рот у [src.p_them()] до краёв чем-то наполнен."

	if(!parts.len)
		return null

	return parts.Join(" ")

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

/mob/living/carbon/human/proc/is_sex_node_restrained(node_id)
	if(!node_id)
		return FALSE

	var/id = node_id
	if(istext(id))
		switch(id)
			if("left_hand")   id = "left_hand"
			if("right_hand")  id = "right_hand"
			if("legs")        id = "legs"
			if("mouth")       id = "mouth"

	switch(id)
		if("left_hand")
			if(handcuffed)
				return TRUE

			if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
				return TRUE

			var/obj/item/I = get_item_for_held_index(LEFT_HANDS)
			if(I && !is_sex_toy(I))
				return TRUE

			return FALSE

		if("right_hand")
			if(handcuffed)
				return TRUE

			if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
				return TRUE

			var/obj/item/I = get_item_for_held_index(RIGHT_HANDS)
			if(I && !is_sex_toy(I))
				return TRUE

			return FALSE

		if("legs")
			if(legcuffed)
				return TRUE

			return FALSE

		if("mouth")
			if(is_mouth_covered())
				return TRUE

			return FALSE

	return FALSE


/mob/living/carbon/human/proc/is_sex_node_blocked_by_clothes(node_id)
	if(!node_id)
		return FALSE

	var/zone = BODY_ZONE_CHEST

	switch(node_id)
		if(SEX_ORGAN_MOUTH)
			zone = BODY_ZONE_PRECISE_MOUTH
		if(SEX_ORGAN_PENIS, SEX_ORGAN_VAGINA, SEX_ORGAN_ANUS)
			zone = BODY_ZONE_PRECISE_GROIN


	if(!zone)
		return FALSE

	if(!get_location_accessible(src, zone, skipundies = TRUE))
		return TRUE

	return FALSE

/mob/living/carbon/human/grippedby(mob/living/carbon/user, instant = FALSE)
	if(is_surrendering_to(user))
		instant = TRUE
		var/old_surrendering = surrendering
		surrendering = TRUE

		. = ..()

		surrendering = old_surrendering
		return .

	. = ..()
	return .


/mob/living/carbon/human/proc/sexpanel_flip(dir_step = 0)
	if(lying)
		if(lying == 270)
			lying = 90
		else
			lying = 270
		update_transform()
		lying_prev = lying

/mob/living/carbon/human/proc/get_mouth_sex_organ()
	var/obj/item/bodypart/head/HD = get_bodypart(BODY_ZONE_HEAD)
	return HD?.sex_organ

/mob/living/carbon/human/proc/swallow_from_mouth(amount = 5)
	if(amount <= 0 || !reagents)
		return FALSE

	var/datum/sex_organ/mouth/M = get_mouth_sex_organ()
	if(!M || !M.stored_liquid)
		remove_status_effect(/datum/status_effect/mouth_full)
		return FALSE

	if(M.stored_liquid.total_volume <= 0)
		remove_status_effect(/datum/status_effect/mouth_full)
		return FALSE

	var/to_swallow = min(amount, M.stored_liquid.total_volume)
	if(to_swallow <= 0)
		remove_status_effect(/datum/status_effect/mouth_full)
		return FALSE

	M.stored_liquid.trans_to(reagents, to_swallow)

	if(M.stored_liquid.total_volume <= 0)
		remove_status_effect(/datum/status_effect/mouth_full)

	return TRUE
