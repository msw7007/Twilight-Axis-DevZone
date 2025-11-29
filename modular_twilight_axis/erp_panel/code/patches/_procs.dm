/mob/living/proc/start_sex_session_tgui(mob/living/T)
	if(!T)
		return

	var/datum/sex_session_tgui/S = get_sex_session_tgui(src, T)

	if(!S)
		S = get_any_sex_session_tgui_for(src)

	if(S)
		if(istype(T, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = T
			S.add_partner(H)
			S.target = H
			S.current_partner_ref = REF(H)

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

