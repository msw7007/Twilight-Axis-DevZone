/mob/living/proc/start_sex_session_tgui(mob/living/T)
	if(!T)
		return

//	if(!ishuman(src) || !ishuman(T))
//		return

	var/datum/sex_session_tgui/S = get_sex_session_tgui(src, T)

	if(S)
		if(istype(T, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = T
			S.add_partner(H)
			S.target = H
			S.current_partner_ref = REF(H)

		S.ui_interact(src)
		return S

	S = get_any_sex_session_tgui_for(src)

	if(S)
		if(istype(T, /mob/living/carbon/human))
			var/mob/living/carbon/human/H2 = T
			S.add_partner(H2)
			S.current_partner_ref = REF(H2)
		S.ui_interact(src)
		return S

	S = new(src, T)
	LAZYADD(GLOB.sex_sessions, S)

	if(istype(T, /mob/living/carbon/human))
		S.add_partner(T)

	S.ui_interact(src)
	return S

/proc/get_sex_session_tgui(mob/giver, mob/taker)
	for (var/datum/D in GLOB.sex_sessions)
		if (istype(D, /datum/sex_session_tgui))
			var/datum/sex_session_tgui/S = D
			if (S.user == giver && S.target == taker)
				return S
	return null

/proc/get_any_sex_session_tgui_for(mob/living/carbon/human/user)
	if(!user)
		return null

	for(var/datum/sex_session_tgui/S in GLOB.sex_sessions)
		if(QDELETED(S))
			continue
		if(S.user == user)
			return S

	return null

/proc/return_sessions_with_user_tgui(mob/living/carbon/human/U)
	var/list/sessions = list()
	for (var/datum/D in GLOB.sex_sessions)
		if (istype(D, /datum/sex_session_tgui))
			var/datum/sex_session_tgui/S = D
			if (U == S.user || U == S.target)
				sessions |= S
	return sessions

/proc/return_highest_priority_action_tgui(list/sessions = list(), mob/living/carbon/human/U)
	var/datum/sex_session_tgui/best_session = null
	var/best_score = -1

	for (var/datum/D in sessions)
		if (!istype(D, /datum/sex_session_tgui))
			continue
		var/datum/sex_session_tgui/S = D

		var/datum/sex_action_session/I = null
		for (var/id in S.current_actions)
			I = S.current_actions[id]
			if (I)
				break
		if (!I || !I.action)
			continue

		var/init_type = S.node_organ_type(I.actor_node_id)
		if (!init_type)
			init_type = 0

		var/score = init_type
		if (U == S.target)
			score += 100
		else if (U == S.user)
			score += 50

		if (score > best_score)
			best_score = score
			best_session = S

	return best_session

/proc/create_dullahan_head_partner(obj/item/bodypart/head/dullahan/H)
    var/mob/living/carbon/human/erp_proxy/P = new()
    P.source_part = H
    P.name = "Голова [H.original_owner.name]"
    return P

/proc/is_erp_zone_blocked_by_clothes(mob/living/carbon/human/user, mob/living/carbon/human/H, zone)
	if(!H || !zone)
		return FALSE

	if(user && has_aggressive_zone_grab(user, H, zone))
		return FALSE

	if(!get_location_accessible(H, zone, skipundies = TRUE))
		return TRUE

	return FALSE

/proc/sex_organ_to_zone(organ_type)
	switch(organ_type)
		if(SEX_ORGAN_PENIS, SEX_ORGAN_VAGINA, SEX_ORGAN_ANUS)
			return BODY_ZONE_PRECISE_GROIN
		if(SEX_ORGAN_BREASTS)
			return BODY_ZONE_CHEST
		if(SEX_ORGAN_MOUTH)
			return BODY_ZONE_PRECISE_MOUTH
	return null

/proc/has_aggressive_zone_grab(mob/living/carbon/human/grabber, mob/living/carbon/human/grabbed, zone)
	if(!grabber || !grabbed || !zone)
		return FALSE
	if(!iscarbon(grabbed))
		return FALSE

	var/mob/living/carbon/C = grabbed

	var/has_zone_grab = FALSE
	for(var/obj/item/grabbing/G in C.grabbedby)
		if(G.sublimb_grabbed == zone)
			has_zone_grab = TRUE
			break

	if(!has_zone_grab)
		return FALSE

	var/grabstate = grabber.get_highest_grab_state_on(grabbed)
	if(grabstate && grabstate >= GRAB_AGGRESSIVE)
		return TRUE

	return FALSE
