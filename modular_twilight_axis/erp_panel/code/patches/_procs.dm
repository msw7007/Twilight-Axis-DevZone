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
			if(QDELETED(S))
				continue

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

/proc/create_dullahan_head_partner(obj/item/bodypart/head/dullahan/H)
    var/mob/living/carbon/human/erp_proxy/P = new()
    P.source_part = H
    P.name = "Голова [H.original_owner.name]"
    return P

/proc/sex_organ_to_zone(organ_type)
	switch(organ_type)
		if(SEX_ORGAN_PENIS, SEX_ORGAN_VAGINA, SEX_ORGAN_ANUS)
			return BODY_ZONE_PRECISE_GROIN
		if(SEX_ORGAN_BREASTS)
			return BODY_ZONE_CHEST
		if(SEX_ORGAN_MOUTH)
			return BODY_ZONE_PRECISE_MOUTH
	return null

/proc/can_access_erp_zone(mob/living/carbon/human/user, mob/living/carbon/human/target,	zone, require_grab = FALSE,	min_grab_state = GRAB_PASSIVE)
	if(!target || !zone)
		return FALSE

	var/has_zone_grab = FALSE
	var/grabstate = 0

	if(user)
		for(var/obj/item/grabbing/G in target.grabbedby)
			if(G.sublimb_grabbed == zone)
				has_zone_grab = TRUE
				break

		grabstate = user.get_highest_grab_state_on(target) || 0

	var/has_enough_grab = (grabstate >= min_grab_state)

	if(require_grab && !(has_zone_grab && has_enough_grab))
		return FALSE

	if(has_zone_grab && has_enough_grab)
		return TRUE

	if(!get_location_accessible(target, zone, skipundies = TRUE))
		return FALSE

	return TRUE

/proc/get_penis_organ_type_for_style(style)
	switch(style)
		if("Plain")
			return /obj/item/organ/penis
		if("Knotted")
			return /obj/item/organ/penis/knotted
		if("Flared")
			return /obj/item/organ/penis/equine
		if("Knotted 2")
			return /obj/item/organ/penis/tapered_mammal
		if("Tapered")
			return /obj/item/organ/penis/tapered
		if("Hemi")
			return /obj/item/organ/penis/tapered_double
		if("Knotted Hemi")
			return /obj/item/organ/penis/tapered_double_knotted
		if("Barbed")
			return /obj/item/organ/penis/barbed
		if("Barbed, Knotted")
			return /obj/item/organ/penis/barbed_knotted
		if("Tentacled")
			return /obj/item/organ/penis/tentacle

	return /obj/item/organ/penis

/proc/erp_filter_to_body_zone(organ_id)
    if(!organ_id)
        return BODY_ZONE_CHEST

    switch(organ_id)
        if(SEX_ORGAN_FILTER_MOUTH)
            return BODY_ZONE_HEAD

        if(SEX_ORGAN_FILTER_LHAND)
            return BODY_ZONE_L_ARM

        if(SEX_ORGAN_FILTER_RHAND)
            return BODY_ZONE_R_ARM

        if(SEX_ORGAN_FILTER_LEGS)
            return BODY_ZONE_R_LEG

        if(SEX_ORGAN_FILTER_TAIL)
            return BODY_ZONE_CHEST

        if(SEX_ORGAN_FILTER_BREASTS)
            return BODY_ZONE_CHEST

        if(SEX_ORGAN_FILTER_VAGINA, SEX_ORGAN_FILTER_PENIS, SEX_ORGAN_FILTER_ANUS)
            return BODY_ZONE_CHEST

    return BODY_ZONE_CHEST

/proc/erp_body_zone_to_organs(zone)
	var/list/types = list()
	switch(zone)
		if(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_CHEST)
			types += SEX_ORGAN_VAGINA
			types += SEX_ORGAN_ANUS
		if(BODY_ZONE_PRECISE_MOUTH)
			types += SEX_ORGAN_MOUTH
	return types
