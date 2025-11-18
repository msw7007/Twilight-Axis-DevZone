/datum/sex_session_tgui
	var/mob/living/carbon/human/user
	var/mob/living/carbon/human/target

	var/selected_actor_organ_id
	var/selected_partner_organ_id

	var/global_speed = SEX_SPEED_MID
	var/global_force = SEX_FORCE_MID

	var/frozen = FALSE
	var/do_until_finished = TRUE
	var/has_knotted_penis = FALSE
	var/do_knot_action = FALSE

	var/arousal_ui = 0

	var/list/current_actions = list() // /datum/sex_action_instance_tgui

	var/list/locked_actor_categories = list()

	var/list/speed_names = list("МЕДЛЕННО", "ПОСТЕПЕННО", "БЫСТРО", "НЕУМОЛИМО")
	var/list/force_names = list("НЕЖНО", "НАСТОЙЧИВО", "ГРУБО", "ЖЕСТОКО")

	/// список партнёров (кроме user); храним как слабые ссылки на мобов
	var/list/partners = list()
	/// текущий выбранный партнёр (REF() строки, чтобы удобно гонять в tgui)
	var/current_partner_ref = null

	/// лог “романа” — список строк
	var/list/romance_log = list()
	/// ограничение на длину лога
	var/romance_log_max = 100

	/// флаг “поддаться”
	var/yield_to_partner = FALSE

/datum/sex_session_tgui/New(mob/living/carbon/human/U, mob/living/carbon/human/T)
	..()
	user = U
	target = T

	var/obj/item/organ/penis/P = user?.getorganslot(ORGAN_SLOT_PENIS)
	if(istype(P))
		switch(P.penis_type)
			if(PENIS_TYPE_KNOTTED, PENIS_TYPE_TAPERED_DOUBLE_KNOTTED, PENIS_TYPE_BARBED_KNOTTED)
				has_knotted_penis = TRUE

	RegisterSignal(user, COMSIG_SEX_CLIMAX, PROC_REF(on_resolution_event))
	RegisterSignal(user, COMSIG_SEX_AROUSAL_CHANGED, PROC_REF(on_arousal_changed), TRUE)

/datum/sex_session_tgui/Destroy()
	UnregisterSignal(user, list(COMSIG_SEX_CLIMAX, COMSIG_SEX_AROUSAL_CHANGED))
	for (var/id in current_actions)
		var/datum/sex_action_instance_tgui/I = current_actions[id]
		if (I) 
			qdel(I)
	current_actions.Cut()
	locked_actor_categories.Cut()
	return ..()

/datum/sex_session_tgui/proc/add_partner(mob/living/carbon/human/M)
	if(!M || M == user)
		return

	if(!(M in partners))
		partners += M

	if(!current_partner_ref)
		current_partner_ref = REF(M)

/datum/sex_session_tgui/proc/build_org_nodes(mob/living/carbon/human/M, side)
	var/list/out = list()
	out += list(list("id"="body","name"="Тело","busy"=FALSE,"side"=side))

	var/obj/item/bodypart/head/HD = M.get_bodypart(BODY_ZONE_HEAD)
	if (HD)
		out += list(list("id"="mouth","name"="Рот","busy"=is_locked("mouth"),"side"=side))
	var/obj/item/bodypart/l_arm/LA = M.get_bodypart(BODY_ZONE_L_ARM)
	if (LA)
		out += list(list("id"="left_hand","name"="Левая рука","busy"=is_locked("left_hand"),"side"=side))
	var/obj/item/bodypart/r_arm/RA = M.get_bodypart(BODY_ZONE_R_ARM)
	if (RA)
		out += list(list("id"="right_hand","name"="Правая рука","busy"=is_locked("right_hand"),"side"=side))

	if (M.getorganslot(ORGAN_SLOT_VAGINA))
		out += list(list("id"="genital_v","name"="Вагина","busy"=is_locked("genital"),"side"=side))
	if (M.getorganslot(ORGAN_SLOT_PENIS))
		out += list(list("id"="genital_p","name"="Пенис","busy"=is_locked("genital"),"side"=side))
	if (M.getorganslot(ORGAN_SLOT_ANUS))
		out += list(list("id"="genital_a","name"="Анус","busy"=is_locked("genital"),"side"=side))

	return out

/datum/sex_session_tgui/proc/category_of_actor_node(id)
	switch(id)
		if("mouth")     
			return "mouth"
		if("left_hand") 
			return "left_hand"
		if("right_hand")
			return "right_hand"
		if("genital_v","genital_p","genital_a")
			return "genital"
	return null

/datum/sex_session_tgui/proc/is_locked(category)
	return (category in locked_actor_categories)

/datum/sex_session_tgui/proc/slot_available_for(id)
	var/cat = category_of_actor_node(id)
	if(!cat)
		return FALSE
	return !is_locked(cat)

/datum/sex_session_tgui/proc/actions_for_menu()
	var/list/actions = list()
	for (var/action_type in GLOB.sex_actions)
		var/datum/sex_action/A = SEX_ACTION(action_type)
		if (!A)
			continue
		if (!A.shows_on_menu(user, target))
			continue
		actions += list(list("name"=A.name, "type"=action_type, "tags"=list()))
	return actions

/datum/sex_session_tgui/proc/inherent_perform_check(datum/sex_action/A)
	if(!target || !user)
		return FALSE
	if(user.stat != CONSCIOUS) 
		return FALSE
	if(A.check_incapacitated && user.incapacitated())
		return FALSE
	if(A.check_same_tile)
		var/same_tile = (get_turf(user) == get_turf(target))
		var/grab_bypass = (A.aggro_grab_instead_same_tile && user.get_highest_grab_state_on(target) == GRAB_AGGRESSIVE)
		if(!same_tile && !grab_bypass) 
			return FALSE
	if(A.require_grab)
		var/grabstate = user.get_highest_grab_state_on(target)
		if(!grabstate || grabstate < A.required_grab_state) 
			return FALSE
	return TRUE

/datum/sex_session_tgui/proc/can_perform_action_type(action_type, performing = FALSE, actor_node_id = null, partner_node_id = null)
	if(!action_type) 
		return FALSE
	var/datum/sex_action/A = SEX_ACTION(action_type)
	if(!A) 
		return FALSE

	if(!inherent_perform_check(A)) 
		return FALSE

	var/a_id = actor_node_id || selected_actor_organ_id
	var/p_id = partner_node_id || selected_partner_organ_id
	if(!a_id || !p_id) 
		return FALSE

	if(!performing && is_locked(category_of_actor_node(a_id))) 
		return FALSE
	if(!A.can_perform(user, target) && !performing) 
		return FALSE

	return TRUE

/datum/sex_session_tgui/proc/ui_key()
	return "EroticRolePlayPanel"

/datum/sex_session_tgui/ui_state(mob/user)
	return GLOB.conscious_state

/datum/sex_session_tgui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, ui_key(), "Утолить Желания")
		ui.open()

/datum/sex_session_tgui/ui_static_data(mob/user)
	var/list/D = list()
	D["actions"] = actions_for_menu()
	D["speed_names"] = speed_names.Copy()
	D["force_names"] = force_names.Copy()
	D["has_knotted_penis"] = has_knotted_penis
	return D

/datum/sex_session_tgui/ui_data(mob/user)
	var/list/D = list()
	D["title"] = "Соитие с [target?.name || "…"]"
	D["session_name"] = "Private Session"
	D["actor_name"] = user?.name || "—"
	D["partner_name"] = target?.name || "—"
	D["actor_organs"] = build_org_nodes(user, "actor")
	D["partner_organs"] = build_org_nodes(target, "partner")
	D["selected_actor_organ"] = selected_actor_organ_id
	D["selected_partner_organ"] = selected_partner_organ_id
	D["speed"] = global_speed
	D["force"] = global_force
	D["arousal"] = clamp(round(arousal_ui), 0, 100)
	D["frozen"] = frozen
	D["do_until_finished"] = do_until_finished
	D["do_knot_action"] = do_knot_action

	var/list/can = list()
	for (var/action_type in GLOB.sex_actions)
		if (can_perform_action_type(action_type))
			can += action_type
	D["can_perform"] = can

	// current_action — возьмём первый активный
	var/cur = null
	for (var/id in current_actions)
		var/datum/sex_action_instance_tgui/I = current_actions[id]
		if (I)
			cur = I.action_type
			break
	D["current_action"] = cur

	var/list/partners_data = list()

	partners_data += list(list(
		"ref" = REF(src.user),
		"name" = "[src.user.name] (я)"
	))

	for(var/mob/living/carbon/human/M in partners)
		if(QDELETED(M))
			continue
		partners_data += list(list(
			"ref" = REF(M),
			"name" = M.name
		))

	// если активный партнёр отвалился – самосвитч на себя
	if(!current_partner_ref)
		current_partner_ref = REF(src.user)

	D["partners"] = partners_data
	D["current_partner_ref"] = current_partner_ref
	D["romance_log"] = romance_log.Copy()
	
	// имя активного партнёра для удобства
	var/mob/living/carbon/human/active_partner = locate(current_partner_ref)
	D["partner_name"] = active_partner ? active_partner.name : src.user.name

	return D

/datum/sex_session_tgui/ui_act(action, list/params)
	. = ..()
	if (.)
		return

	switch(action)
		if("select_organ")
			var/side = params["side"]; var/id = params["id"]
			if (side == "actor") 
				selected_actor_organ_id = id
			else if (side == "partner") 
				selected_partner_organ_id = id
			SStgui.update_uis(src)
			return TRUE

		if("set_speed")
			global_speed = clamp(text2num(params["value"]), SEX_SPEED_MIN, SEX_SPEED_MAX)
			SStgui.update_uis(src)
			return TRUE

		if("set_force")
			global_force = clamp(text2num(params["value"]), SEX_FORCE_MIN, SEX_FORCE_MAX)
			SStgui.update_uis(src)
			return TRUE

		if("start_action")
			try_start_action(params["action_type"])
			SStgui.update_uis(src)
			return TRUE

		if("stop_action")
			stop_all_actions()
			SStgui.update_uis(src)
			return TRUE

		if("toggle_finished")
			do_until_finished = !do_until_finished
			SStgui.update_uis(src)
			return TRUE

		if("freeze_arousal")
			frozen = !frozen
			SStgui.update_uis(src)
			return TRUE

		if("toggle_knot")
			do_knot_action = !do_knot_action
			SStgui.update_uis(src)
			return TRUE

		if("quick")
			var/op = params["op"]
			if (op == "increase")
				global_force = clamp(global_force+1, SEX_FORCE_MIN, SEX_FORCE_MAX)
				global_speed = clamp(global_speed+1, SEX_SPEED_MIN, SEX_SPEED_MAX)
			else if (op == "yield")
				stop_all_actions()
			SStgui.update_uis(src)
			return TRUE

		if("set_partner")
			var/ref = params["ref"]
			if(!ref)
				return

			// проверка, что такой партнёр вообще в списке
			for(var/mob/living/carbon/human/M in partners + list(user))
				if(REF(M) == ref)
					current_partner_ref = ref
					target = M
					SStgui.update_uis(src)
					return TRUE

	return FALSE

/datum/sex_session_tgui/proc/update_partners_proximity()
	if(QDELETED(user))
		return

	var/list/new_partners = list()
	for(var/mob/living/carbon/human/M in partners)
		if(QDELETED(M))
			continue
		if(get_dist(user, M) > 2)
			continue
		new_partners += M

	partners = new_partners

	if(!length(partners))
		current_partner_ref = REF(user)
		target = user
	else
		if(!locate(current_partner_ref))
			var/mob/living/carbon/human/N = partners[1]
			current_partner_ref = REF(N)
			target = N

/datum/sex_session_tgui/proc/log_romance(message)
	if(!message)
		return
	romance_log += message
	if(length(romance_log) > romance_log_max)
		romance_log.Cut(1, 2) // срезать самый старый

/datum/sex_session_tgui/proc/try_start_action(action_type)
	if (!selected_actor_organ_id || !selected_partner_organ_id)
		return
	if (!can_perform_action_type(action_type))
		return
	if (!slot_available_for(selected_actor_organ_id))
		return

	var/datum/sex_action/A = SEX_ACTION(action_type)
	if (!A)
		return

	var/cat = category_of_actor_node(selected_actor_organ_id)
	if (cat) locked_actor_categories |= cat

	var/datum/sex_action_instance_tgui/I = new(src, A, selected_actor_organ_id, selected_partner_organ_id)
	I.speed = global_speed
	I.force = global_force

	current_actions[I.instance_id] = I
	INVOKE_ASYNC(I, TYPE_PROC_REF(/datum/sex_action_instance_tgui, start))

/datum/sex_session_tgui/proc/stop_all_actions()
	var/list/ids = current_actions.Copy()
	for (var/id in ids)
		stop_instance(id)

/datum/sex_session_tgui/proc/stop_instance(id)
	var/datum/sex_action_instance_tgui/I = current_actions[id]
	if (!I)
		return
	current_actions -= id

	var/cat = category_of_actor_node(I.actor_node_id)
	if (cat) locked_actor_categories -= cat

	I.action.on_finish(user, target)
	qdel(I)
	SStgui.update_uis(src)

/datum/sex_session_tgui/proc/sync_arousal_ui()
	var/list/ad = list()
	SEND_SIGNAL(user, COMSIG_SEX_GET_AROUSAL, ad)
	var/cur = ad["arousal"] || 0
	arousal_ui = min(100, (cur / ACTIVE_EJAC_THRESHOLD) * 100)

/datum/sex_session_tgui/proc/on_arousal_changed()
	sync_arousal_ui()
	SStgui.update_uis(src)

/datum/sex_session_tgui/proc/on_resolution_event(mob/source)
	if (!selected_actor_organ_id || !selected_partner_organ_id)
		return

	var/datum/sex_organ/src_org = resolve_organ_datum(user, selected_actor_organ_id)
	var/datum/sex_organ/tgt_org = resolve_organ_datum(target, selected_partner_organ_id)
	if (!src_org || !tgt_org)
		return

	var/amt = 5
	if (src_org.stored_liquid && tgt_org.stored_liquid)
		src_org.stored_liquid.trans_to(tgt_org.stored_liquid, amt)
	else if (istype(src_org, /datum/sex_organ/penis))
		var/datum/sex_organ/penis/P = src_org
		var/move = min(amt, P.liquid_ammount)
		if (move > 0)
			tgt_org.add_reagent(/datum/reagent/erpjuice/cum, move)
			P.liquid_ammount = max(0, P.liquid_ammount - move)

/datum/sex_session_tgui/proc/resolve_organ_datum(mob/living/carbon/human/M, id)
	if (!M || !id)
		return null
	switch(id)
		if("mouth")
			var/obj/item/bodypart/head/HD = M.get_bodypart(BODY_ZONE_HEAD)
			return HD?.sex_organ
		if("left_hand")
			var/obj/item/bodypart/l_arm/LA = M.get_bodypart(BODY_ZONE_L_ARM)
			return LA?.sex_organ
		if("right_hand")
			var/obj/item/bodypart/r_arm/RA = M.get_bodypart(BODY_ZONE_R_ARM)
			return RA?.sex_organ
		if("genital_v")
			var/obj/item/organ/vagina/V = M.getorganslot(ORGAN_SLOT_VAGINA)
			return V?.sex_organ
		if("genital_p")
			var/obj/item/organ/penis/P = M.getorganslot(ORGAN_SLOT_PENIS)
			return P?.sex_organ
		if("genital_a")
			var/obj/item/organ/anus/A = M.getorganslot(ORGAN_SLOT_ANUS)
			return A?.sex_organ
		if("body")
			return null
	return null
