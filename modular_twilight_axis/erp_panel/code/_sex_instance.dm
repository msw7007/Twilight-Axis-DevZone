// ==============================================
//  Инстанс действия с раздельными speed/force
// ==============================================

/datum/sex_action_instance_tgui
	var/datum/sex_action/action
	var/datum/sex_session_tgui/session
	var/action_type
	var/instance_id
	var/actor_node_id
	var/partner_node_id

	var/speed = SEX_SPEED_MID
	var/force = SEX_FORCE_MID
	var/continous = TRUE

	var/timer_id

/datum/sex_action_instance_tgui/New(datum/sex_session_tgui/S, datum/sex_action/A, actor_node, partner_node)
	..()
	session = S
	action = A
	action_type = A.type
	instance_id = "[REF(src)]"
	actor_node_id = actor_node
	partner_node_id = partner_node
	continous = A.continous

/datum/sex_action_instance_tgui/Destroy()
	if (timer_id)
		deltimer(timer_id)
		timer_id = null
	return ..()

/datum/sex_action_instance_tgui/proc/start()
	// on_start определён в /datum/sex_action
	action.on_start(session.user, session.target)
	loop_tick()

/datum/sex_action_instance_tgui/proc/loop_tick()
	// валидность
	if (QDELETED(session))
		return
	var/datum/sex_action_instance_tgui/I = session.current_actions?[instance_id]
	if (!I || I != src)
		return

	#ifndef LOCALTEST
	if (isnull(session.target.client))
		return session.stop_instance(instance_id)
	#endif

	if (!session.user.stamina_add(action.stamina_cost * get_stamina_cost_multiplier(force)))
		return session.stop_instance(instance_id)

	var/do_time = action.do_time / get_speed_multiplier(speed)
	if (!do_after(session.user, do_time, target = session.target))
		return session.stop_instance(instance_id)

	if (!session.can_perform_action_type(action.type, TRUE, actor_node_id, partner_node_id))
		return session.stop_instance(instance_id)

	action.on_perform(session.user, session.target)
	action.show_sex_effects(session.user)

	// начисление — без base_gain(); берём 1.0 как базу и умножители от органов/регуляторов
	var/datum/sex_organ/src_org = session.resolve_organ_datum(session.user, actor_node_id)
	var/datum/sex_organ/tgt_org = session.resolve_organ_datum(session.target, partner_node_id)

	var/base = 1
	var/mult = 1
	if (src_org && tgt_org)
		var/bonus = src_org.pleasure_bonus(tgt_org)
		if (isnum(bonus))
			mult = max(0, bonus)

	var/delta = base * mult * get_speed_multiplier(speed) * get_stamina_cost_multiplier(force)
	SEND_SIGNAL(session.user, COMSIG_SEX_RECEIVE_ACTION, delta, 0, TRUE, force, speed)

	session.sync_arousal_ui()
	SStgui.update_uis(session)

	if (!continous)
		return session.stop_instance(instance_id)

	timer_id = addtimer(CALLBACK(src, PROC_REF(loop_tick)), world.tick_lag, TIMER_STOPPABLE)


// Хелперы мультипликаторов
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
