
/datum/component/knotting/should_remove_knot_on_movement(mob/living/carbon/human/top, mob/living/carbon/human/btm)
	var/list/arousal_data = list()
	SEND_SIGNAL(top, COMSIG_SEX_GET_AROUSAL, arousal_data)

	var/dist = get_dist(top, btm)

	if(dist <= 1)
		var/grabstate = top.get_highest_grab_state_on(btm)
		if(grabstate && grabstate >= GRAB_AGGRESSIVE)
			return FALSE

	if(dist > 1 && dist < 6)
		return FALSE

	if(arousal_data["arousal"] < AROUSAL_HARD_ON_THRESHOLD)
		knot_remove()
		return TRUE

	if(dist > 1)
		knot_remove(forceful_removal = TRUE)
		return TRUE

	var/lupine_op = top.STASTR > (btm.STACON + 3)
	if(!lupine_op && top.m_intent == MOVE_INTENT_RUN && (top.mobility_flags & MOBILITY_STAND))
		knot_remove(forceful_removal = TRUE)
		return TRUE

	return FALSE

/datum/component/knotting/handle_special_movement_cases(mob/living/carbon/human/top, mob/living/carbon/human/btm)
	if(top.m_intent == MOVE_INTENT_WALK && (btm in top.buckled_mobs))
		var/obj/item/organ/penis/P = top.getorganslot(ORGAN_SLOT_PENIS)
		var/strength = (P && P.penis_size > DEFAULT_PENIS_SIZE) ? 6.0 : 3.0

		SEND_SIGNAL(btm, COMSIG_SEX_RECEIVE_ACTION, strength, 0, FALSE, SEX_FORCE_MID, SEX_SPEED_HIGH, SEX_ORGAN_FILTER_VAGINA)

		var/datum/component/arousal/btm_arousal = btm.GetComponent(/datum/component/arousal)
		btm_arousal?.try_ejaculate()

		if(prob(50))
			to_chat(top, span_love("I feel [btm] tightening over my knot."))
			to_chat(btm, span_love("I feel [top] rubbing inside."))

		if(get_dist(top, btm) > 1)
			tugging_knot = TRUE
			for(var/i in 1 to 2)
				if(get_dist(top, btm) <= 1) break
				step_towards(btm, top)
			tugging_knot = FALSE
		btm.face_atom(top)
		top.set_pull_offsets(btm, GRAB_AGGRESSIVE)

		return TRUE

	if(top.pulling == btm)
		if(get_dist(top, btm) > 1)
			tugging_knot = TRUE
			step_towards(btm, top)
			tugging_knot = FALSE
		btm.face_atom(top)
		top.set_pull_offsets(btm, GRAB_AGGRESSIVE)
		return TRUE

	if(btm.pulling == top)
		knot_remove(forceful_removal = TRUE)
		return TRUE

	return FALSE

/datum/component/knotting/can_knot(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!target || !ishuman(target))
		return FALSE

	if(get_dist(user, target) > 1)
		return FALSE

	var/list/sessions = return_sessions_with_user_tgui(user)
	var/linked = FALSE

	for(var/datum/sex_session_tgui/S in sessions)
		if(QDELETED(S))
			continue
		if(!length(S.current_actions))
			continue

		for(var/id in S.current_actions)
			var/datum/sex_action_session/I = S.current_actions[id]
			if(!I || QDELETED(I) || !I.action)
				continue

			if(I.actor != user || I.partner != target)
				continue

			if(S.node_organ_type(I.actor_node_id) != SEX_ORGAN_PENIS)
				continue
			if(!I.action.can_knot)
				continue

			linked = TRUE
			break

		if(linked)
			break

	if(!linked)
		return FALSE

	if(!check_knot_penis_type())
		return FALSE

	var/list/arousal_data = list()
	SEND_SIGNAL(user, COMSIG_SEX_GET_AROUSAL, arousal_data)
	if(arousal_data["arousal"] < AROUSAL_HARD_ON_THRESHOLD)
		if(!knotted_status)
			to_chat(user, span_notice("My knot was too soft to tie."))
		if(knotted_recipient != target)
			to_chat(target, span_notice("I feel their deflated knot slip out."))
		return FALSE

	return TRUE

