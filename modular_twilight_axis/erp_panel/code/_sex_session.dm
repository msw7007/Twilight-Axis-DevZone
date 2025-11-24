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

	var/actor_arousal_ui = 0
	var/partner_arousal_ui = 0

	var/list/current_actions = list()

	var/list/locked_actor_categories = list()

	var/list/speed_names = list("МЕДЛЕННО", "ПОСТЕПЕННО", "БЫСТРО", "НЕУМОЛИМО")
	var/list/force_names = list("НЕЖНО", "НАСТОЙЧИВО", "ГРУБО", "ЖЕСТОКО")

	var/list/partners = list()
	var/current_partner_ref = null

	var/yield_to_partner = FALSE
	var/broadcast_timer_id

/datum/sex_session_tgui/New(mob/living/carbon/human/U, mob/living/carbon/human/T)
	. = ..()
	if(U)
		user = U
	if(T)
		target = T

	update_knotted_penis_flag()

	RegisterSignal(user, COMSIG_SEX_CLIMAX, PROC_REF(on_resolution_event))
	RegisterSignal(user, COMSIG_SEX_AROUSAL_CHANGED, PROC_REF(on_arousal_changed))
	if(target && target != user)
		RegisterSignal(target, COMSIG_SEX_AROUSAL_CHANGED, PROC_REF(on_arousal_changed))

	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	if(target && target != user)
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/sex_session_tgui/proc/update_knotted_penis_flag()
	has_knotted_penis = FALSE
	if(!user)
		return

	var/obj/item/organ/penis/P = user.getorganslot(ORGAN_SLOT_PENIS)
	if(!P)
		return

	switch(P.penis_type)
		if(PENIS_TYPE_KNOTTED, PENIS_TYPE_TAPERED_DOUBLE_KNOTTED, PENIS_TYPE_BARBED_KNOTTED)
			has_knotted_penis = TRUE

/datum/sex_session_tgui/Destroy()
	if(user)
		user.set_sex_surrender_to(null)
		UnregisterSignal(user, list(COMSIG_SEX_CLIMAX, COMSIG_SEX_AROUSAL_CHANGED))
		UnregisterSignal(user, list(COMSIG_SEX_CLIMAX, COMSIG_SEX_AROUSAL_CHANGED, COMSIG_MOVABLE_MOVED))
	if(target && target != user)
		UnregisterSignal(target, COMSIG_SEX_AROUSAL_CHANGED)
		UnregisterSignal(target, list(COMSIG_SEX_AROUSAL_CHANGED, COMSIG_MOVABLE_MOVED))
		

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(I)
			qdel(I)
	current_actions.Cut()
	locked_actor_categories.Cut()
	partners.Cut()
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
	out += list(list("id" = "body", "name" = "Тело", "busy" = FALSE, "side" = side))

	var/is_actor = (side == "actor")

	#define BUSY_FOR(id) (is_actor ? !slot_available_for(id) : FALSE)

	var/obj/item/bodypart/head/HD = M.get_bodypart(BODY_ZONE_HEAD)
	if(HD)
		out += list(list(
			"id"   = "mouth",
			"name" = "Рот",
			"busy" = BUSY_FOR("mouth"),
			"side" = side,
		))

	var/obj/item/bodypart/l_arm/LA = M.get_bodypart(BODY_ZONE_L_ARM)
	if(LA)
		out += list(list(
			"id"   = "left_hand",
			"name" = "Левая рука",
			"busy" = BUSY_FOR("left_hand"),
			"side" = side,
		))

	var/obj/item/bodypart/r_arm/RA = M.get_bodypart(BODY_ZONE_R_ARM)
	if(RA)
		out += list(list(
			"id"   = "right_hand",
			"name" = "Правая рука",
			"busy" = BUSY_FOR("right_hand"),
			"side" = side,
		))

	var/obj/item/bodypart/l_leg/LL = M.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/bodypart/r_leg/RL = M.get_bodypart(BODY_ZONE_R_LEG)
	if(LL || RL)
		out += list(list(
			"id"   = "legs",
			"name" = "Ноги",
			"busy" = BUSY_FOR("legs"),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_TAIL))
		out += list(list(
			"id"   = "tail",
			"name" = "Хвост",
			"busy" = BUSY_FOR("tail"),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_BREASTS))
		out += list(list(
			"id"   = "breasts",
			"name" = "Грудь",
			"busy" = BUSY_FOR("breasts"),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_VAGINA))
		out += list(list(
			"id"   = "genital_v",
			"name" = "Вагина",
			"busy" = BUSY_FOR("genital_v"),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_PENIS))
		out += list(list(
			"id"   = "genital_p",
			"name" = "Член",
			"busy" = BUSY_FOR("genital_p"),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_ANUS))
		out += list(list(
			"id"   = "genital_a",
			"name" = "Анус",
			"busy" = BUSY_FOR("genital_a"),
			"side" = side,
		))

	#undef BUSY_FOR

	return out

/datum/sex_session_tgui/proc/category_of_actor_node(id)
	switch(id)
		if("mouth")
			return "mouth"
		if("breasts")
			return "breasts"
		if("left_hand")
			return "left_hand"
		if("right_hand")
			return "right_hand"
		if("legs")
			return "legs"
		if("tail")
			return "tail"
		if("genital_v", "genital_p", "genital_a")
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
	for(var/key in GLOB.sex_panel_actions)
		var/datum/sex_panel_action/A = GLOB.sex_panel_actions[key]
		if(!A)
			continue
		if(!A.shows_on_menu(user, target))
			continue
		actions += list(list(
			"name" = A.name,
			"type" = key,
			"tags" = list(),
		))
	return actions

/datum/sex_session_tgui/proc/inherent_perform_check(datum/sex_panel_action/A)
	if(!target || !user)
		return FALSE
	if(user.stat != CONSCIOUS)
		return FALSE
	if(A.check_incapacitated && user.incapacitated())
		return FALSE

	var/dist = get_dist(user, target)
	if(dist > 1)
		return FALSE

	if(A.check_same_tile)
		var/same_tile = (dist == 0)
		var/has_aggressive_grab = (user.get_highest_grab_state_on(target) == GRAB_AGGRESSIVE)

		if(!same_tile && !has_aggressive_grab)
			return FALSE

	if(A.require_grab)
		var/grabstate = user.get_highest_grab_state_on(target)
		if(!grabstate || grabstate < A.required_grab_state)
			return FALSE

	return TRUE

/datum/sex_session_tgui/proc/can_perform_action_type(action_type, performing = FALSE, actor_node_id = null, partner_node_id = null)
	if(!action_type)
		return FALSE

	var/datum/sex_panel_action/A = SEX_PANEL_ACTION(action_type)
	if(!A)
		return FALSE

	var/a_id = actor_node_id
	if(!a_id)
		a_id = selected_actor_organ_id

	var/p_id = partner_node_id
	if(!p_id)
		p_id = selected_partner_organ_id

	var/a_type = a_id ? node_organ_type(a_id) : null
	var/p_type = p_id ? node_organ_type(p_id) : null

	if(A.required_init && a_type && A.required_init != a_type)
		return FALSE
	if(A.required_target && p_type && A.required_target != p_type)
		return FALSE

	if(performing)
		if(A.required_init && !a_type)
			return FALSE
		if(A.required_target && !p_type)
			return FALSE

		if(!inherent_perform_check(A))
			return FALSE

		return TRUE

	var/a_cat = a_id ? category_of_actor_node(a_id) : null
	if(a_cat && is_locked(a_cat))
		return FALSE

	if(!A.can_perform(user, target))
		return FALSE

	return TRUE

/datum/sex_session_tgui/proc/ui_key()
	return "EroticRolePlayPanel"

/datum/sex_session_tgui/ui_state(mob/user)
	return GLOB.conscious_state

/datum/sex_session_tgui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
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
	D["actor_arousal"] = clamp(round(actor_arousal_ui), 0, 100)

	if(can_see_partner_arousal())
		D["partner_arousal"] = clamp(round(partner_arousal_ui), 0, 100)
		D["partner_arousal_hidden"] = FALSE
	else
		D["partner_arousal"] = null
		D["partner_arousal_hidden"] = TRUE
		
	D["frozen"] = frozen
	D["do_until_finished"] = do_until_finished
	var/can_knot_now = FALSE
	if(has_knotted_penis && length(current_actions))
		for(var/id in current_actions)
			var/datum/sex_action_session/I = current_actions[id]
			if(!I || !I.action)
				continue
			if(I.session.user != user)
				continue
			if(node_organ_type(I.actor_node_id) != SEX_ORGAN_PENIS)
				continue
			if(!I.action.can_knot)
				continue
			can_knot_now = TRUE
			break

	D["has_knotted_penis"] = has_knotted_penis
	D["do_knot_action"] = do_knot_action
	D["can_knot_now"] = can_knot_now
	D["yield_to_partner"] = yield_to_partner
	D["status_organs"] = build_status_org_nodes(src.user)

	var/list/can = list()
	for(var/key in GLOB.sex_panel_actions)
		if(can_perform_action_type(key))
			can += key
	D["can_perform"] = can
	D["organ_filtered"] = actions_matching_nodes()

	var/list/cur_types = list()
	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(I && I.action_type)
			cur_types |= I.action_type

	D["current_actions"] = cur_types

	var/list/partners_data = list()
	if(user)
		partners_data += list(list(
			"ref" = REF(user),
			"name" = "[user.name]"
		))

	for(var/mob/living/carbon/human/M in partners)
		if(QDELETED(M))
			continue
		partners_data += list(list(
			"ref" = REF(M),
			"name" = M.name
		))

	if(!current_partner_ref && user)
		current_partner_ref = REF(user)

	D["partners"] = partners_data
	D["current_partner_ref"] = current_partner_ref

	var/mob/living/carbon/human/active_partner = locate(current_partner_ref)
	D["partner_name"] = active_partner ? active_partner.name : user?.name

	var/list/links = list()
	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I)
			continue

		var/datum/sex_organ/partner_org = resolve_organ_datum(target, I.partner_node_id)
		var/sens = partner_org ? partner_org.sensivity : 0
		var/pain = partner_org ? partner_org.pain : 0

		links += list(list(
			"id"                = I.instance_id,
			"actor_organ_id"    = I.actor_node_id,
			"partner_organ_id"  = I.partner_node_id,
			"action_type"       = I.action_type,
			"action_name"       = I.action?.name,
			"speed"             = I.speed,
			"force"             = I.force,
			"do_until_finished" = do_until_finished,
			"sensitivity"       = sens,
			"pain"              = pain,
		))

	D["active_links"] = links

	return D

/datum/sex_session_tgui/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_organ")
			var/side = params["side"]
			var/id = params["id"]
			if(side == "actor")
				selected_actor_organ_id = id
			else if(side == "partner")
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
			if(can_toggle_knot())
				do_knot_action = !do_knot_action
			SStgui.update_uis(src)
			return TRUE

		if("quick")
			var/op = params["op"]
			if(op == "increase")
				global_force = clamp(global_force + 1, SEX_FORCE_MIN, SEX_FORCE_MAX)
				global_speed = clamp(global_speed + 1, SEX_SPEED_MIN, SEX_SPEED_MAX)
			else if(op == "yield")
				yield_to_partner = !yield_to_partner

				var/mob/living/carbon/human/partner = locate(current_partner_ref)
				if(yield_to_partner && partner)
					user.set_sex_surrender_to(partner)
				else
					user.set_sex_surrender_to(null)

				if(yield_to_partner)
					stop_all_actions()

			SStgui.update_uis(src)
			return TRUE

		if("set_partner")
			var/ref = params["ref"]
			if(!ref)
				return
			for(var/mob/living/carbon/human/M in partners + list(user))
				if(REF(M) == ref)
					current_partner_ref = ref
					target = M
					SStgui.update_uis(src)
					return TRUE

		if("stop_all")
			stop_all_actions()
			SStgui.update_uis(src)
			return TRUE

		if("stop_link")
			var/id = params["id"]
			if(id)
				stop_instance(id)
				SStgui.update_uis(src)
				return TRUE

		if("set_link_speed")
			var/id = params["id"]
			var/value = clamp(text2num(params["value"]), SEX_SPEED_MIN, SEX_SPEED_MAX)
			var/datum/sex_action_session/I = current_actions[id]
			if(I)
				I.speed = value
				SStgui.update_uis(src)
				return TRUE

		if("set_link_force")
			var/id2 = params["id"]
			var/value2 = clamp(text2num(params["value"]), SEX_FORCE_MIN, SEX_FORCE_MAX)
			var/datum/sex_action_session/I2 = current_actions[id2]
			if(I2)
				I2.force = value2
				SStgui.update_uis(src)
				return TRUE

		if("toggle_link_finished")
			do_until_finished = !do_until_finished
			SStgui.update_uis(src)
			return TRUE

		if("set_arousal_value")
			var/target_type = params["target"]
			var/amount = clamp(text2num(params["amount"]), 0, 100)
			if(target_type == "actor" && user)
				SEND_SIGNAL(user, COMSIG_SEX_SET_AROUSAL, amount)
			else if(target_type == "partner" && target)
				SEND_SIGNAL(target, COMSIG_SEX_SET_AROUSAL, amount)
			SStgui.update_uis(src)
			return TRUE

		if("set_organ_tuning")
			var/id = params["id"]
			var/field = params["field"]
			var/value = text2num(params["value"])

			var/datum/sex_organ/O = resolve_organ_datum(user, id)
			if(!O)
				return FALSE

			switch(field)
				if("sensitivity")
					O.sensivity = clamp(value, 0, O.sensivity_max)

			SStgui.update_uis(src)
			return TRUE
		if("set_link_tuning")
			var/id = params["id"]
			var/field = params["field"]
			var/value = text2num(params["value"])

			var/datum/sex_action_session/I = current_actions[id]
			if(!I)
				return FALSE

			var/datum/sex_organ/partner_org = resolve_organ_datum(target, I.partner_node_id)
			if(!partner_org)
				return FALSE

			switch(field)
				if("sensitivity")
					partner_org.sensivity = clamp(value, 0, partner_org.sensivity_max)

			SStgui.update_uis(src)
			return TRUE

		if("flip")
			if(user)
				user.sexpanel_flip()
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

/datum/sex_session_tgui/proc/try_start_action(action_type)
	var/datum/sex_panel_action/A = SEX_PANEL_ACTION(action_type)
	if(!A)
		return

	var/a_id = pick_actor_node_for_action(A)
	var/p_id = pick_partner_node_for_action(A)

	if(!a_id || !p_id)
		return

	if(!can_perform_action_type(action_type, TRUE, a_id, p_id))
		return

	selected_actor_organ_id = a_id
	selected_partner_organ_id = p_id

	var/cat = category_of_actor_node(a_id)
	if(cat)
		locked_actor_categories |= cat

	var/datum/sex_action_session/I = new(src, A, a_id, p_id)
	I.speed = global_speed
	I.force = global_force

	current_actions[I.instance_id] = I
	INVOKE_ASYNC(I, TYPE_PROC_REF(/datum/sex_action_session, start))

	start_broadcast_loop()

	SStgui.update_uis(src)

/datum/sex_session_tgui/proc/stop_all_actions()
	var/list/ids = current_actions.Copy()
	for(var/id in ids)
		stop_instance(id)

	if(!length(current_actions))
		clear_actor_locks()

/datum/sex_session_tgui/proc/stop_instance(id)
	var/datum/sex_action_session/I = current_actions[id]
	if(!I)
		return

	current_actions -= id

	var/cat = category_of_actor_node(I.actor_node_id)
	if(cat)
		locked_actor_categories -= cat

	var/datum/sex_organ/src_org = resolve_organ_datum(user, I.actor_node_id)
	if(src_org)
		src_org.unbind()

	I.action.on_finish(user, target)
	qdel(I)

	if(!length(current_actions))
		clear_actor_locks()
		stop_broadcast_loop()

	SStgui.update_uis(src)

/datum/sex_session_tgui/proc/sync_arousal_ui()
	var/list/ad_user = list()
	var/list/ad_tgt = list()
	if(user)
		SEND_SIGNAL(user, COMSIG_SEX_GET_AROUSAL, ad_user)
	if(target)
		SEND_SIGNAL(target, COMSIG_SEX_GET_AROUSAL, ad_tgt)

	var/cur_u = ad_user["arousal"] || 0
	var/cur_t = ad_tgt["arousal"] || 0

	actor_arousal_ui = min(100, (cur_u / ERP_UI_MAX_AROUSAL) * 100)
	partner_arousal_ui = min(100, (cur_t / ERP_UI_MAX_AROUSAL) * 100)

/datum/sex_session_tgui/proc/on_arousal_changed()
	sync_arousal_ui()
	SStgui.update_uis(src)

/datum/sex_session_tgui/proc/on_resolution_event(mob/source)
	if(source != user)
		return

	if(do_until_finished)
		stop_all_actions()

	if(!selected_actor_organ_id || !selected_partner_organ_id)
		return

	var/datum/sex_organ/src_org = resolve_organ_datum(user, selected_actor_organ_id)
	var/datum/sex_organ/tgt_org = resolve_organ_datum(target, selected_partner_organ_id)
	if(!src_org || !tgt_org)
		return

	var/amt = 5

	if(src_org.stored_liquid && tgt_org.stored_liquid)
		src_org.stored_liquid.trans_to(tgt_org.stored_liquid, amt)
		return

	if(istype(src_org, /datum/sex_organ/penis))
		var/datum/sex_organ/penis/P = src_org
		var/move = min(amt, P.liquid_ammount)
		if(move <= 0)
			return

		if(tgt_org.stored_liquid)
			tgt_org.add_reagent(P.liquid_type, move)
		else
			var/mob/living/carbon/human/H = tgt_org.get_owner()
			var/turf/T = H ? get_turf(H) : get_turf(user)
			if(T)
				new /obj/effect/decal/cleanable/coom(T)

		P.liquid_ammount = max(0, P.liquid_ammount - move)
		return

/datum/sex_session_tgui/proc/resolve_organ_datum(mob/living/carbon/human/M, id)
	if(!M || !id)
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
		if("legs")
			var/obj/item/bodypart/l_leg/LL = M.get_bodypart(BODY_ZONE_L_LEG)
			if(LL && LL.sex_organ)
				return LL.sex_organ
			var/obj/item/bodypart/r_leg/RL = M.get_bodypart(BODY_ZONE_R_LEG)
			return RL?.sex_organ
		if("tail")
			var/obj/item/organ/tail/T = M.getorganslot(ORGAN_SLOT_TAIL)
			return T?.sex_organ
		if("breasts")
			var/obj/item/organ/breasts/B = M.getorganslot(ORGAN_SLOT_BREASTS)
			return B?.sex_organ
		if("genital_v")
			var/obj/item/organ/vagina/V = M.getorganslot(ORGAN_SLOT_VAGINA)
			return V?.sex_organ
		if("genital_p")
			var/obj/item/organ/penis/P = M.getorganslot(ORGAN_SLOT_PENIS)
			return P?.sex_organ
		if("genital_a")
			var/obj/item/bodypart/chest/A = M.get_bodypart(BODY_ZONE_CHEST)
			return A?.sex_organ
		if("body")
			return null

	return null

/datum/sex_session_tgui/proc/node_organ_type(id)
	switch(id)
		if("mouth")
			return SEX_ORGAN_MOUTH
		if("left_hand", "right_hand")
			return SEX_ORGAN_HANDS
		if("legs")
			return SEX_ORGAN_LEGS
		if("tail")
			return SEX_ORGAN_TAIL
		if("breasts")
			return SEX_ORGAN_BREASTS
		if("genital_v")
			return SEX_ORGAN_VAGINA
		if("genital_p")
			return SEX_ORGAN_PENIS
		if("genital_a")
			return SEX_ORGAN_ANUS
	return null

/datum/sex_session_tgui/proc/pick_actor_node_for_action(datum/sex_panel_action/A)
	if(selected_actor_organ_id)
		var/t = node_organ_type(selected_actor_organ_id)
		if((!A.required_init || A.required_init == t) && !is_locked(category_of_actor_node(selected_actor_organ_id)))
			return selected_actor_organ_id

	var/list/nodes = build_org_nodes(user, "actor")
	for(var/i in 1 to nodes.len)
		var/list/N = nodes[i]
		var/id = N["id"]
		if(id == "body")
			continue

		var/t2 = node_organ_type(id)
		if(A.required_init && A.required_init != t2)
			continue
		if(is_locked(category_of_actor_node(id)))
			continue

		return id

	return null

/datum/sex_session_tgui/proc/pick_partner_node_for_action(datum/sex_panel_action/A)
	if(selected_partner_organ_id)
		var/t = node_organ_type(selected_partner_organ_id)
		if(!A.required_target || A.required_target == t)
			return selected_partner_organ_id

	var/list/nodes = build_org_nodes(target, "partner")
	for(var/i in 1 to nodes.len)
		var/list/N = nodes[i]
		var/id = N["id"]
		if(id == "body")
			continue

		var/t2 = node_organ_type(id)
		if(A.required_target && A.required_target != t2)
			continue

		return id

	return null

/datum/sex_session_tgui/proc/start_broadcast_loop()
	if(broadcast_timer_id)
		return
	broadcast_timer_id = addtimer(CALLBACK(src, PROC_REF(broadcast_tick)), 5 SECONDS, TIMER_STOPPABLE)

/datum/sex_session_tgui/proc/stop_broadcast_loop()
	if(!broadcast_timer_id)
		return
	deltimer(broadcast_timer_id)
	broadcast_timer_id = null

/datum/sex_session_tgui/proc/broadcast_tick()
	if(QDELETED(src))
		broadcast_timer_id = null
		return

	if(!length(current_actions))
		broadcast_timer_id = null
		return

	var/list/candidates = list()

	for(var/id in current_actions)
		var/datum/sex_action_session/A = current_actions[id]
		if(!A || QDELETED(A))
			continue
		if(!A.action)
			continue
		if(A.session.user != user)
			continue
		candidates += A

	if(!length(candidates))
		broadcast_timer_id = null
		return

	var/datum/sex_action_session/choice = pick(candidates)
	var/mob/living/carbon/human/U = choice.session.user
	var/mob/living/carbon/human/T = choice.session.target

	if(U && T && choice.action)
		var/msg = choice.action.get_perform_message(U, T, TRUE)
		if(msg)
			U.visible_message(msg)

	broadcast_timer_id = addtimer(CALLBACK(src, PROC_REF(broadcast_tick)), 5 SECONDS, TIMER_STOPPABLE)

/datum/sex_session_tgui/proc/can_continue_action_session(datum/sex_action_session/I)
	if(!I || !I.action)
		return FALSE
	if(!user || !target)
		return FALSE

	if(!inherent_perform_check(I.action))
		return FALSE

	var/a_type = I.actor_node_id ? node_organ_type(I.actor_node_id) : null
	var/p_type = I.partner_node_id ? node_organ_type(I.partner_node_id) : null

	if(I.action.required_init && !a_type)
		return FALSE
	if(I.action.required_target && !p_type)
		return FALSE

	return TRUE

/datum/sex_session_tgui/proc/clear_actor_locks()
	if(locked_actor_categories)
		locked_actor_categories.Cut()

/datum/sex_session_tgui/proc/build_status_org_nodes(mob/living/carbon/human/M)
	var/list/out = list()

	var/list/base = build_org_nodes(M, "actor")
	for(var/i in 1 to base.len)
		var/list/N = base[i]
		var/id = N["id"]

		var/datum/sex_organ/O = resolve_organ_datum(M, id)
		var/sens = O ? O.sensivity : 0
		var/pain = O ? O.pain : 0

		var/fullness = 0
		if(O && O.stored_liquid && O.stored_liquid_max > 0)
			var/cur = O.stored_liquid.total_volume
			if(cur > 0)
				fullness = clamp(round((cur / O.stored_liquid_max) * 100), 0, 100)

		out += list(list(
			"id"          = id,
			"name"        = N["name"],
			"busy"        = N["busy"],
			"side"        = N["side"],
			"sensitivity" = sens,
			"pain"        = pain,
			"fullness"    = fullness,
		))

	return out

/datum/sex_session_tgui/proc/can_see_partner_arousal()
	if(!user || !target)
		return FALSE

	if(user == target)
		return FALSE

	if(HAS_TRAIT(user, TRAIT_EMPATH))
		return TRUE

	return FALSE

/datum/sex_session_tgui/proc/can_toggle_knot()
	if(!has_knotted_penis)
		return FALSE
	if(!length(current_actions))
		return FALSE

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I || !I.action)
			continue
		if(I.session.user != user)
			continue
		if(node_organ_type(I.actor_node_id) != SEX_ORGAN_PENIS)
			continue
		if(!I.action.can_knot)
			continue
		return TRUE

	return FALSE

/datum/sex_session_tgui/proc/is_maso_or_nympho(mob/living/carbon/human/M)
	if(!M)
		return FALSE

	if(M.has_flaw(/datum/charflaw/addiction/lovefiend))
		return TRUE

	if(M.has_flaw(/datum/charflaw/addiction/masochist))
		return TRUE

	return FALSE

/datum/sex_session_tgui/proc/on_moved(atom/movable/mover, atom/oldloc, direction)
	SIGNAL_HANDLER

	if(!length(current_actions))
		return

	stop_all_actions()

	if(ishuman(mover))
		var/mob/living/carbon/human/H = mover
		to_chat(H, span_notice("Движение прерывает интимные действия."))

/proc/get_or_create_sex_session_tgui(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user)
		return null

	var/list/sessions = return_sessions_with_user_tgui(user)
	var/datum/sex_session_tgui/session

	if(length(sessions))
		session = sessions[1]
	else
		session = new /datum/sex_session_tgui(user, target)

	if(target && target != user)
		if(!session.target)
			session.target = target
		else
			if(!(target in session.partners))
				session.partners += target

	session.update_knotted_penis_flag()

	return session

/datum/sex_session_tgui/proc/actions_matching_nodes()
	var/list/res = list()

	if(!selected_actor_organ_id || !selected_partner_organ_id)
		return res

	if(selected_actor_organ_id == "body" || selected_partner_organ_id == "body")
		return res

	for(var/key in GLOB.sex_panel_actions)
		var/datum/sex_panel_action/A = GLOB.sex_panel_actions[key]
		if(!A)
			continue

		var/a_type = node_organ_type(selected_actor_organ_id)
		var/p_type = node_organ_type(selected_partner_organ_id)

		if(A.required_init && (!a_type || A.required_init != a_type))
			continue

		if(A.required_target && (!p_type || A.required_target != p_type))
			continue

		res += key

	return res
