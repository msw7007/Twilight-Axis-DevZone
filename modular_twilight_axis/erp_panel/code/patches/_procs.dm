/mob/living/proc/start_sex_session_tgui(mob/living/target_mob)
	if(!target_mob)
		return

	if(!ishuman(src) || !ishuman(target_mob))
		return

	var/datum/sex_session_tgui/session_object = get_sex_session_tgui(src, target_mob)

	if(session_object)
		if(istype(target_mob, /mob/living/carbon/human))
			var/mob/living/carbon/human/human_object = target_mob
			session_object.add_partner(human_object)
			session_object.target = human_object
			session_object.current_partner_ref = REF(human_object)

		session_object.ui_interact(src)
		return session_object

	session_object = get_any_sex_session_tgui_for(src)

	if(session_object)
		if(istype(target_mob, /mob/living/carbon/human))
			var/mob/living/carbon/human/human_object2 = target_mob
			session_object.add_partner(human_object2)
			session_object.current_partner_ref = REF(human_object2)
		session_object.ui_interact(src)
		return session_object

	session_object = new(src, target_mob)
	LAZYADD(GLOB.sex_sessions, session_object)

	if(istype(target_mob, /mob/living/carbon/human))
		session_object.add_partner(target_mob)

	session_object.ui_interact(src)
	return session_object

/proc/get_sex_session_tgui(mob/giver, mob/taker)
	for (var/datum/datum_candidate in GLOB.sex_sessions)
		if (istype(datum_candidate, /datum/sex_session_tgui))
			var/datum/sex_session_tgui/session_object = datum_candidate
			if(QDELETED(session_object))
				continue

			if (session_object.user == giver && session_object.target == taker)
				return session_object
	return null

/proc/get_any_sex_session_tgui_for(mob/living/carbon/human/user)
	if(!user)
		return null

	for(var/datum/sex_session_tgui/session_object in GLOB.sex_sessions)
		if(QDELETED(session_object))
			continue
		if(session_object.user == user)
			return session_object

	return null

/proc/return_sessions_with_user_tgui(mob/living/carbon/human/user)
	var/list/sessions = list()
	for (var/datum/datum_candidate in GLOB.sex_sessions)
		if (istype(datum_candidate, /datum/sex_session_tgui))
			var/datum/sex_session_tgui/session_object = datum_candidate
			if (user == session_object.user || user == session_object.target)
				sessions |= session_object
	return sessions

/proc/create_dullahan_head_partner(obj/item/bodypart/head/dullahan/head_dullahan)
    var/mob/living/carbon/human/erp_proxy/proxy_object = new()
    proxy_object.source_part = head_dullahan
    proxy_object.name = "Голова [head_dullahan.original_owner.name]"
    return proxy_object

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
		for(var/obj/item/grabbing/grab_object in target.grabbedby)
			if(grab_object.sublimb_grabbed == zone)
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

/proc/collect_passive_links_for(mob/living/carbon/human/H)
	if(!H)
		return list()

	var/list/passive_links = list()
	for(var/datum/sex_session_tgui/session in GLOB.sex_sessions)
		if(!session || QDELETED(session))
			continue

		if(session.user == H)
			continue

		if(!(H in session.partners))
			continue

		for(var/id in session.current_actions)
			var/datum/sex_action_session/I = session.current_actions[id]
			if(!I || QDELETED(I))
				continue
			if(I.partner != H)
				continue

			var/datum/sex_organ/tuned_org = session.resolve_organ_datum(I.partner, I.partner_node_id)
			var/sens = tuned_org ? tuned_org.sensivity : 0
			var/pain = tuned_org ? tuned_org.pain : 0

			passive_links += list(list(
				"id"                = I.instance_id,
				"actor_organ_id"    = I.actor_node_id,
				"partner_organ_id"  = I.partner_node_id,
				"action_type"       = I.action_type,
				"action_name"       = I.action?.name,
				"speed"             = I.speed,
				"force"             = I.force,
				"do_until_finished" = session.do_until_finished,
				"sensitivity"       = sens,
				"pain"              = pain,
			))

	return passive_links
