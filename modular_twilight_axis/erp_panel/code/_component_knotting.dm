
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
		var/obj/item/organ/penis/penis = top.getorganslot(ORGAN_SLOT_PENIS)
		var/datum/sex_session/session = get_sex_session(top, btm)
		if(session)
			session.perform_sex_action(btm, penis?.penis_size > DEFAULT_PENIS_SIZE ? 6.0 : 3.0, 2, FALSE)
			var/datum/component/arousal/btm_arousal = btm.GetComponent(/datum/component/arousal)
			btm_arousal?.try_ejaculate()
		if(prob(50))
			to_chat(top, span_love("I feel [btm] tightening over my knot."))
			to_chat(btm, span_love("I feel [top] rubbing inside."))
		return TRUE

	if(btm.pulling == top || top.pulling == btm)
		return TRUE

	return FALSE
