/datum/sex_action_session
	var/action_type
	var/datum/sex_panel_action/action
	var/datum/sex_session_tgui/session

	var/mob/living/carbon/human/actor
	var/mob/living/carbon/human/partner

	var/instance_id
	var/actor_node_id
	var/partner_node_id

	var/speed = SEX_SPEED_MID
	var/force = SEX_FORCE_MID

	var/timer_id
	var/next_tick_time = 0

/datum/sex_action_session/New(datum/sex_session_tgui/S, datum/sex_panel_action/A, actor_node, partner_node)
	. = ..()
	session = S

	if(A)
		action = new A.type
		action.session = src

	if(action)
		action_type = action.type

	instance_id = "[REF(src)]"
	actor_node_id = actor_node
	partner_node_id = partner_node

	actor = S.user
	var/mob/living/carbon/human/p = S.get_current_partner()
	if(!p)
		p = S.user
	partner = p

/datum/sex_action_session/Destroy()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	
	var/datum/sex_organ/src_org = session?.resolve_organ_datum(actor, actor_node_id)
	if(src_org)
		src_org.unbind()
	qdel(action)
	action = null
	return ..()

/datum/sex_action_session/proc/start()
	var/datum/sex_organ/src_org = session.resolve_organ_datum(actor, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(partner, partner_node_id)

	if(src_org)
		src_org.bind_with(tgt_org)

	action.on_start(actor, partner, src)
	loop_tick()

/datum/sex_action_session/proc/loop_tick()
	if(QDELETED(session))
		return
	if(QDELETED(actor) || QDELETED(partner))
		return session.stop_instance(instance_id)

	var/datum/sex_action_session/I = session.current_actions?[instance_id]
	if(!I || I != src)
		return

	if(isnull(partner))
		return session.stop_instance(instance_id)

	if(!session.can_continue_action_session(src))
		return session.stop_instance(instance_id)

	var/do_time = action.interaction_timer / get_speed_multiplier(speed)
	if(do_time < 0.1)
		do_time = 0.1

	if(world.time < next_tick_time)
		timer_id = addtimer(CALLBACK(src, PROC_REF(loop_tick)), world.tick_lag, TIMER_STOPPABLE)
		return

	if(action.stamina_cost)
		var/mob/living/carbon/human/U = actor
		if(U)
			U.sex_procs_active = TRUE
			var/success = U.stamina_add(action.stamina_cost * get_stamina_cost_multiplier(force))
			U.sex_procs_active = FALSE
			if(!success)
				return session.stop_instance(instance_id)

	var/delta = calc_delta()
	var/list/pain_deltas = update_organ_response(delta)
	var/self_pain_delta = pain_deltas?["self"] || 0
	var/target_pain_delta = pain_deltas?["target"] || 0

	apply_arousal_delta(delta, self_pain_delta, target_pain_delta)

	session.sync_arousal_ui()
	SStgui.update_uis(session)

	next_tick_time = world.time + do_time
	timer_id = addtimer(CALLBACK(src, PROC_REF(loop_tick)), world.tick_lag, TIMER_STOPPABLE)

/datum/sex_action_session/proc/update_organ_response(delta = 0)
	if(!session || !action)
		return list("self" = 0, "target" = 0)

	var/datum/sex_organ/src_org = session.resolve_organ_datum(actor, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(partner, partner_node_id)

	if(delta <= 0)
		delta = 1

	var/base_pain_self   = delta * 0.10
	var/base_pain_target = delta * 0.10

	var/self_pain_delta   = 0
	var/target_pain_delta = 0
	var/pain_mult = 0.0

	switch(force)
		if(SEX_FORCE_LOW)
			pain_mult = 0.0
		if(SEX_FORCE_MID)
			pain_mult = 0.01
		if(SEX_FORCE_HIGH)
			pain_mult = 1.0
		if(SEX_FORCE_EXTREME)
			pain_mult = 1.25

	self_pain_delta   = base_pain_self   * pain_mult
	target_pain_delta = base_pain_target * pain_mult
	var/speed_pain_mult = 1.0
	switch(speed)
		if(SEX_SPEED_LOW)
			speed_pain_mult = 0.8
		if(SEX_SPEED_MID)
			speed_pain_mult = 1.0
		if(SEX_SPEED_HIGH)
			speed_pain_mult = 1.2
		if(SEX_SPEED_EXTREME)
			speed_pain_mult = 1.4

	self_pain_delta   *= speed_pain_mult
	target_pain_delta *= speed_pain_mult

	self_pain_delta   *= ORG_PAIN_GAIN_RATE
	target_pain_delta *= ORG_PAIN_GAIN_RATE

	var/knot_pain_mult = 0
	var/mob/living/carbon/human/U = actor
	var/mob/living/carbon/human/T = partner
	if(U && T)
		var/datum/component/knotting/K = U.GetComponent(/datum/component/knotting)
		if(K && K.knotted_status == KNOTTED_AS_TOP && K.knotted_recipient == T)
			knot_pain_mult = 0.25

	target_pain_delta += knot_pain_mult

	if(src_org)
		src_org.adjust_pain(self_pain_delta)

	if(tgt_org)
		tgt_org.adjust_pain(target_pain_delta)

	return list(
		"self"   = max(0, self_pain_delta),
		"target" = max(0, target_pain_delta),
	)

/datum/sex_action_session/proc/calc_delta()
	if(!session || !action)
		return 0

	var/datum/sex_organ/src_org = session.resolve_organ_datum(actor, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(partner, partner_node_id)

	var/base = 1
	var/mult = 1

	if(src_org && tgt_org)
		var/bonus = src_org.pleasure_bonus(tgt_org)
		if(isnum(bonus))
			mult = 1 + bonus

	return base * mult

/datum/sex_action_session/proc/apply_arousal_delta(delta, self_pain_delta, target_pain_delta)
	if(delta <= 0 && self_pain_delta <= 0 && target_pain_delta <= 0)
		return

	var/mob/living/carbon/human/U = actor
	var/mob/living/carbon/human/T = partner

	var/user_sources   = get_arousal_source_count_for(U)
	var/target_sources = get_arousal_source_count_for(T)

	var/user_delta   = 0
	var/target_delta = 0

	if(action.affects_self_arousal && delta > 0)
		user_delta = delta
	if(action.affects_arousal && delta > 0)
		target_delta = delta

	if(user_sources > 1 && user_delta)
		user_delta /= user_sources
	if(target_sources > 1 && target_delta)
		target_delta /= target_sources

	if(self_pain_delta > 0 && U)
		if(session?.is_maso_or_nympho(U))
			user_delta += self_pain_delta
		else
			user_delta -= self_pain_delta

	if(target_pain_delta > 0 && T)
		if(session?.is_maso_or_nympho(T))
			target_delta += target_pain_delta
		else
			target_delta -= target_pain_delta

	var/total_user_pain = 0
	var/total_target_pain = 0

	if(U && actor_node_id && session)
		var/datum/sex_organ/user_org = session.resolve_organ_datum(U, actor_node_id)
		if(user_org)
			total_user_pain = max(0, user_org.pain)
			user_delta *= user_org.sensivity

	if(T && partner_node_id && session)
		var/datum/sex_organ/target_org = session.resolve_organ_datum(T, partner_node_id)
		if(target_org)
			total_target_pain = max(0, target_org.pain)
			target_delta *= target_org.sensivity

	if(U && (user_delta || total_user_pain))
		SEND_SIGNAL(U, COMSIG_SEX_RECEIVE_ACTION, user_delta, total_user_pain, TRUE, force, speed, actor_node_id)

	if(T && (target_delta || total_target_pain))
		SEND_SIGNAL(T, COMSIG_SEX_RECEIVE_ACTION, target_delta, total_target_pain, FALSE, force, speed, partner_node_id)

/datum/sex_action_session/proc/get_arousal_source_count_for(mob/living/carbon/human/M)
	if(!M || !session || !length(session.current_actions))
		return 1

	var/count = 0
	for(var/id in session.current_actions)
		var/datum/sex_action_session/S = session.current_actions[id]
		if(!S || QDELETED(S))
			continue
		if(!S.action)
			continue

		if(S.actor == M)
			if(!S.action.affects_self_arousal)
				continue
		else if(S.partner == M)
			if(!S.action.affects_arousal)
				continue
		else
			continue

		count++

	if(count <= 0)
		count = 1
	return count

/datum/sex_action_session/proc/get_priority_for(mob/living/carbon/human/U)
	if(!session || !action || !U)
		return -1

	var/organ_priority = 0
	if(actor_node_id)
		var/org_type = session.node_organ_type(actor_node_id)
		if(isnum(org_type))
			organ_priority = org_type

	var/role_priority = 0
	if(U == partner)
		role_priority = 100
	else if(U == actor)
		role_priority = 50

	return organ_priority + role_priority
