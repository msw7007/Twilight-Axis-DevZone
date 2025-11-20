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

/datum/sex_action_session/New(datum/sex_session_tgui/S, datum/sex_panel_action/A, actor_node, partner_node)
	. = ..()
	session = S
	action = A
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
	return ..()

/datum/sex_action_session/proc/start()
	var/datum/sex_organ/src_org = session.resolve_organ_datum(session.user, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(session.target, partner_node_id)

	if(src_org)
		src_org.bind_with(tgt_org)

	action.on_start(session.user, session.target)
	loop_tick()

/datum/sex_action_session/proc/loop_tick()
	if(QDELETED(session))
		return
	if(QDELETED(session.user) || QDELETED(session.target))
		return session.stop_instance(instance_id)

	var/datum/sex_action_session/I = session.current_actions?[instance_id]
	if(!I || I != src)
		return

	#ifndef LOCALTEST
	if(isnull(session.target.client))
		return session.stop_instance(instance_id)
	#endif

	if(action.stamina_cost)
		if(!session.user.stamina_add(action.stamina_cost * get_stamina_cost_multiplier(force)))
			return session.stop_instance(instance_id)

	var/do_time = action.interaction_timer / get_speed_multiplier(speed)
	if(do_time < 0)
		do_time = 0

	if(!do_after(session.user, do_time, target = session.target))
		return session.stop_instance(instance_id)

	if(!session.can_continue_action_session(src))
		return session.stop_instance(instance_id)

	action.on_perform(session.user, session.target)
	action.show_sex_effects(session.user)

	var/list/pain_deltas = update_organ_response()
	var/self_pain_delta = pain_deltas?["self"] || 0
	var/target_pain_delta = pain_deltas?["target"] || 0

	var/delta = calc_delta()
	apply_arousal_delta(delta, self_pain_delta, target_pain_delta)

	session.sync_arousal_ui()
	SStgui.update_uis(session)

	timer_id = addtimer(CALLBACK(src, PROC_REF(loop_tick)), world.tick_lag, TIMER_STOPPABLE)

/datum/sex_action_session/proc/update_organ_response()
	if(!session || !action)
		return list("self" = 0, "target" = 0)

	var/datum/sex_organ/src_org = session.resolve_organ_datum(session.user, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(session.target, partner_node_id)

	var/self_sens_delta = 0
	var/self_pain_delta = 0
	var/target_sens_delta = 0
	var/target_pain_delta = 0

	switch(force)
		if(SEX_FORCE_LOW)
			self_sens_delta += 0.01
			target_sens_delta += 0.02
		if(SEX_FORCE_MID)
			self_sens_delta += 0.02
			target_sens_delta += 0.04
		if(SEX_FORCE_HIGH)
			self_sens_delta += 0.03
			target_sens_delta += 0.06
			target_pain_delta += 0.02
		if(SEX_FORCE_EXTREME)
			self_sens_delta += 0.04
			target_sens_delta += 0.08
			self_pain_delta += 0.01
			target_pain_delta += 0.03

	switch(speed)
		if(SEX_SPEED_LOW)
			self_sens_delta *= 0.8
			target_sens_delta *= 0.8
		if(SEX_SPEED_HIGH)
			self_sens_delta *= 1.2
			target_sens_delta *= 1.2
		if(SEX_SPEED_EXTREME)
			self_sens_delta *= 1.4
			target_sens_delta *= 1.4
			self_pain_delta *= 1.2
			target_pain_delta *= 1.2

	if(src_org)
		src_org.sensivity = max(0, src_org.sensivity + self_sens_delta)
		src_org.pain = max(0, src_org.pain + self_pain_delta)

	if(tgt_org)
		tgt_org.sensivity = max(0, tgt_org.sensivity + target_sens_delta)
		src_org.pain = max(0, src_org.pain + target_pain_delta)

	return list(
		"self" = max(0, self_pain_delta),
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
			mult = max(0.25, 1 + (bonus / 10))

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

/proc/get_speed_multiplier(s)
	switch(s)
		if(SEX_SPEED_LOW) return 1.0
		if(SEX_SPEED_MID) return 1.5
		if(SEX_SPEED_HIGH) return 2.0
		if(SEX_SPEED_EXTREME) return 2.5
	return 1.0

/proc/get_stamina_cost_multiplier(f)
	switch(f)
		if(SEX_FORCE_LOW) return 1.0
		if(SEX_FORCE_MID) return 1.5
		if(SEX_FORCE_HIGH) return 2.0
		if(SEX_FORCE_EXTREME) return 2.5
	return 1.0
