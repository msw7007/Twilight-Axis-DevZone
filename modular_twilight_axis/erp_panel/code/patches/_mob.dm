
/mob/living
	var/sex_procs_active = FALSE
	
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
		if(!B.sex_organ)
			continue
		if(B.sex_organ in seen)
			continue

		if(istype(src, /mob/living/carbon/human/erp_proxy))
			if(!istype(B, /obj/item/bodypart/head) && !istype(B, /obj/item/bodypart/head/dullahan))
				continue

			seen += B.sex_organ
			result += B.sex_organ
			continue

		seen += B.sex_organ
		result += B.sex_organ

	result += legs_organ
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
			if(SEX_ORGAN_FILTER_LHAND)  id = SEX_ORGAN_FILTER_LHAND
			if(SEX_ORGAN_FILTER_RHAND)  id = SEX_ORGAN_FILTER_RHAND
			if(SEX_ORGAN_FILTER_LEGS)        id = SEX_ORGAN_FILTER_LEGS
			if(SEX_ORGAN_FILTER_MOUTH)       id = SEX_ORGAN_FILTER_MOUTH

	switch(id)
		if(SEX_ORGAN_FILTER_LHAND)
			if(handcuffed)
				return TRUE

			if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
				return TRUE

			var/obj/item/I = get_item_for_held_index(LEFT_HANDS)
			if(I && !is_sex_toy(I))
				return TRUE

			return FALSE

		if(SEX_ORGAN_FILTER_RHAND)
			if(handcuffed)
				return TRUE

			if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
				return TRUE

			var/obj/item/I = get_item_for_held_index(RIGHT_HANDS)
			if(I && !is_sex_toy(I))
				return TRUE

			return FALSE

		if(SEX_ORGAN_FILTER_LEGS)
			if(legcuffed)
				return TRUE

			return FALSE

		if(SEX_ORGAN_FILTER_MOUTH)
			if(is_mouth_covered())
				return TRUE

			return FALSE

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

/mob/living/carbon/human/erp_proxy
	var/obj/item/bodypart/source_part
	
/mob/living/carbon/human/erp_proxy/Initialize(mapload)
	..()
	invisibility = 101
	density = FALSE
	anchored = TRUE
	return INITIALIZE_HINT_NORMAL

/mob/living/carbon/human/erp_proxy/Life(seconds_per_tick)
	return

/obj/item/bodypart/head/dullahan/Destroy()
	. = ..()
	for(var/mob/living/carbon/human/erp_proxy/P in world)
		if(P.source_part == src)
			qdel(P)

/mob/living/proc/start_sex_session_with_dullahan_head(obj/item/bodypart/head/dullahan/H)
	var/mob/living/carbon/human/erp_proxy/P = create_dullahan_head_partner(H)

	var/datum/sex_session_tgui/S = new(src, P)
	S.set_partner_bodypart_override(H)

	S.current_partner_ref = REF(P)
	S.partners = list(P)

	S.ui_interact(src)
	return S

/mob/living/carbon/human/proc/apply_soft_arousal(delta = 0.25)
	if(delta <= 0)
		return
	if(cmode)
		return

	SEND_SIGNAL(src, COMSIG_SEX_RECEIVE_ACTION, delta, 0, FALSE, SEX_FORCE_LOW, SEX_SPEED_LOW)

/mob/living/carbon/human/proc/wash_sex_organs_for_clean(clean)
	var/zone = zone_selected
	if(!zone)
		return 0

	var/list/org_types = erp_body_zone_to_organs(zone)
	if(!length(org_types))
		return 0

	var/total_removed = 0

	for(var/t in org_types)
		if(t == SEX_ORGAN_PENIS || t == SEX_ORGAN_BREASTS)
			continue

		var/zone_for_type = sex_organ_to_zone(t)
		if(zone_for_type && !can_access_erp_zone(src, src, zone_for_type, FALSE, GRAB_PASSIVE))
			continue

		var/datum/sex_organ/O = get_sex_organ_by_type(t, FALSE)
		if(!O || !O.has_storage() || O.total_volume() <= 0)
			continue

		var/removed = O.wash_out()
		if(removed > 0)
			total_removed += removed

	if(total_removed > 0)
		to_chat(src, span_notice("Вода смывает с твоего тела посторонние жидкости."))

	return total_removed
