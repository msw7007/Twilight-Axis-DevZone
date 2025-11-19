/mob/living/proc/start_sex_session_tgui(mob/living/T)
	if(!T)
		return
	var/datum/sex_session_tgui/old = get_sex_session_tgui(src, T)
	if(old)
		old.ui_interact(src)
		return old

	var/datum/sex_session_tgui/S = new(src, T)
	LAZYADD(GLOB.sex_sessions, S)
	S.ui_interact(src)
	S.add_partner(T)
	return S

/proc/get_sex_session_tgui(mob/giver, mob/taker)
	for (var/datum/D in GLOB.sex_sessions)
		if (istype(D, /datum/sex_session_tgui))
			var/datum/sex_session_tgui/S = D
			if (S.user == giver && S.target == taker)
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
	var/datum/best_session = null
	var/best_score = -1

	for (var/datum/D in sessions)
		if (!istype(D, /datum/sex_session_tgui))
			continue
		var/datum/sex_session_tgui/S = D

		// берём первый инстанс
		var/datum/sex_action/A = null
		for (var/id in S.current_actions)
			var/datum/sex_action_session/I = S.current_actions[id]
			if (I)
				A = I.action
				break
		if (!A)
			continue

		var/score = 0
		if (U == S.target)
			score = A.target_priority
		else if (U == S.user)
			score = A.user_priority

		if (score > best_score)
			best_score = score
			best_session = S

	return best_session
