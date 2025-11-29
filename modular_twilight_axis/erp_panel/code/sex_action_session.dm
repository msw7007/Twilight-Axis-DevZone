/datum/sex_action_session
	var/action_type
	var/datum/sex_panel_action/action
	var/datum/sex_session_tgui/session

	var/datum/sex_organ/init_organ
	var/datum/sex_organ/target_organ

	var/instance_id
	var/actor_node_id
	var/partner_node_id

	var/speed = SEX_SPEED_MID
	var/force = SEX_FORCE_MID

	var/continous = FALSE
	var/friction_count = 0

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
		continous = action.continous

	instance_id = "[REF(src)]"
	actor_node_id = actor_node
	partner_node_id = partner_node

/datum/sex_action_session/Destroy()
	var/datum/sex_organ/src_org = session?.resolve_organ_datum(session.user, actor_node_id)
	if(src_org)
		src_org.unbind()
	qdel(action)
	action = null
	return ..()

/datum/sex_action_session/proc/start()
	var/datum/sex_organ/src_org = session.resolve_organ_datum(session.user, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(session.target, partner_node_id)

	if(src_org)
		src_org.bind_with(tgt_org)

	action.on_start(session.user, session.target, src)
	loop_tick()

/datum/sex_action_session/proc/loop_tick()
	if(QDELETED(session))
		return
	if(QDELETED(session.user) || QDELETED(session.target))
		return session.stop_instance(instance_id)

	var/datum/sex_action_session/I = session.current_actions?[instance_id]
	if(!I || I != src)
		return

	if(isnull(session.target))//.client))
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
		if(!session.user.stamina_add(action.stamina_cost * get_stamina_cost_multiplier(force)))
			return session.stop_instance(instance_id)

	action.show_sex_effects(session.user)

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

	var/datum/sex_organ/src_org = session.resolve_organ_datum(session.user, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(session.target, partner_node_id)

	if(delta <= 0)
		delta = 1

	var/base_sens_self   = delta * 0.10
	var/base_sens_target = delta * 0.10
	var/base_pain_self   = delta * 0.10
	var/base_pain_target = delta * 0.10

	var/self_sens_delta   = 0
	var/self_pain_delta   = 0
	var/target_sens_delta = 0
	var/target_pain_delta = 0

	var/pleasure_mult = 1.0
	var/pain_mult = 0.0

	switch(force)
		if(SEX_FORCE_LOW)
			pleasure_mult = 0.5
			pain_mult = 0.0
		if(SEX_FORCE_MID)
			pleasure_mult = 1.0
			pain_mult = 0.0
		if(SEX_FORCE_HIGH)
			pleasure_mult = 1.25
			pain_mult = 1.0
		if(SEX_FORCE_EXTREME)
			pleasure_mult = 1.5
			pain_mult = 1.25

	self_sens_delta   = base_sens_self   * pleasure_mult
	target_sens_delta = base_sens_target * pleasure_mult

	self_pain_delta   = base_pain_self   * pain_mult
	target_pain_delta = base_pain_target * pain_mult

	var/speed_sens_mult = 1.0
	var/speed_pain_mult = 1.0
	switch(speed)
		if(SEX_SPEED_LOW)
			speed_sens_mult = 0.8
			speed_pain_mult = 0.8
		if(SEX_SPEED_MID)
			speed_sens_mult = 1.0
			speed_pain_mult = 1.0
		if(SEX_SPEED_HIGH)
			speed_sens_mult = 1.2
			speed_pain_mult = 1.2
		if(SEX_SPEED_EXTREME)
			speed_sens_mult = 1.4
			speed_pain_mult = 1.4

	self_sens_delta   *= speed_sens_mult
	target_sens_delta *= speed_sens_mult
	self_pain_delta   *= speed_pain_mult
	target_pain_delta *= speed_pain_mult

	self_sens_delta   *= ORG_SENS_GAIN_RATE
	target_sens_delta *= ORG_SENS_GAIN_RATE
	self_pain_delta   *= ORG_PAIN_GAIN_RATE
	target_pain_delta *= ORG_PAIN_GAIN_RATE

	var/knot_pain_mult = 0
	var/mob/living/carbon/human/U = session.user
	var/mob/living/carbon/human/T = session.target
	if(U && T)
		var/datum/component/knotting/K = U.GetComponent(/datum/component/knotting)
		if(K && K.knotted_status == KNOTTED_AS_TOP && K.knotted_recipient == T)
			knot_pain_mult = 0.25
	
	target_pain_delta += knot_pain_mult

	if(src_org)
		src_org.sensivity = clamp(src_org.sensivity + self_sens_delta, 0, src_org.sensivity_max)
		src_org.pain      = clamp(src_org.pain      + self_pain_delta, 0, src_org.pain_max)

	if(tgt_org)
		tgt_org.sensivity = clamp(tgt_org.sensivity + target_sens_delta, 0, tgt_org.sensivity_max)
		tgt_org.pain      = clamp(tgt_org.pain      + target_pain_delta, 0, tgt_org.pain_max)

	return list(
		"self"   = max(0, self_pain_delta),
		"target" = max(0, target_pain_delta),
	)

/datum/sex_action_session/proc/calc_delta()
	if(!session || !action)
		return 0

	var/datum/sex_organ/src_org = session.resolve_organ_datum(session.user, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(session.target, partner_node_id)

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

	var/mob/living/carbon/human/U = session.user
	var/mob/living/carbon/human/T = session.target

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

	var/user_pain   = 0
	var/target_pain = 0

	if(action.affects_self_pain && self_pain_delta > 0)
		user_pain = self_pain_delta
	if(action.affects_pain && target_pain_delta > 0)
		target_pain = target_pain_delta

	if(user_pain > 0 && U)
		if(session?.is_maso_or_nympho(U))
			user_delta += user_pain
		else
			user_delta -= user_pain

	if(target_pain > 0 && T)
		if(session?.is_maso_or_nympho(T))
			target_delta += target_pain
		else
			target_delta -= target_pain

	if(U && (user_delta || user_pain))
		SEND_SIGNAL(U, COMSIG_SEX_RECEIVE_ACTION, user_delta, user_pain, TRUE,  force, speed)
	if(T && (target_delta || target_pain))
		SEND_SIGNAL(T, COMSIG_SEX_RECEIVE_ACTION, target_delta, target_pain, FALSE, force, speed)

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

		if(S.session.user == M)
			if(!S.action.affects_self_arousal)
				continue
		else if(S.session.target == M)
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
	if(U == session.target)
		role_priority = 100
	else if(U == session.user)
		role_priority = 50

	return organ_priority + role_priority
