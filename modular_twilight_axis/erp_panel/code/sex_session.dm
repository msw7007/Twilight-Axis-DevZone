/datum/sex_session_tgui
	var/mob/living/carbon/human/user
	var/mob/living/carbon/human/target

	var/obj/item/bodypart/partner_bodypart_override

	var/selected_actor_organ_id
	var/selected_partner_organ_id

	var/global_speed = SEX_SPEED_MID
	var/global_force = SEX_FORCE_MID

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

	var/arousal_frozen = FALSE

/datum/sex_session_tgui/New(mob/living/carbon/human/U, mob/living/carbon/human/T)
	. = ..()
	if(U)
		user = U
	if(T && T != U)
		target = T
		if(!(T in partners))
			partners += T
		current_partner_ref = REF(T)
	else
		target = user
		if(user)
			current_partner_ref = REF(user)

	update_knotted_penis_flag()

	if(user)
		RegisterSignal(user, COMSIG_SEX_CLIMAX, PROC_REF(on_resolution_event))
		RegisterSignal(user, COMSIG_SEX_AROUSAL_CHANGED, PROC_REF(on_arousal_changed))
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	if(target && target != user)
		RegisterSignal(target, COMSIG_SEX_AROUSAL_CHANGED, PROC_REF(on_arousal_changed))
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/sex_session_tgui/Destroy()
	if(user)
		user.set_sex_surrender_to(null)
		UnregisterSignal(user, list(COMSIG_SEX_CLIMAX, COMSIG_SEX_AROUSAL_CHANGED, COMSIG_MOVABLE_MOVED))
	if(target && target != user)
		UnregisterSignal(target, list(COMSIG_SEX_AROUSAL_CHANGED, COMSIG_MOVABLE_MOVED))

	partner_bodypart_override = null

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(I)
			qdel(I)
	current_actions.Cut()
	locked_actor_categories.Cut()
	for(var/mob/living/carbon/human/M in partners)
		if(istype(M, /mob/living/carbon/human/erp_proxy))
			qdel(M)
	partners.Cut()
	LAZYREMOVE(GLOB.sex_sessions, src)
	return ..()

/datum/sex_session_tgui/proc/update_knotted_penis_flag()
	has_knotted_penis = FALSE
	if(!user)
		return

	var/obj/item/organ/penis/P = user.getorganslot(ORGAN_SLOT_PENIS)
	if(!P || !P.sex_organ)
		return

	var/datum/sex_organ/penis/PO = P.sex_organ
	if(istype(PO) && PO.have_knot)
		has_knotted_penis = TRUE

/datum/sex_session_tgui/proc/add_partner(mob/living/carbon/human/M)
	if(!M || M == user)
		return

	if(!(M in partners))
		partners += M

	if(!current_partner_ref)
		current_partner_ref = REF(M)

/datum/sex_session_tgui/proc/get_partner_display_name(mob/living/carbon/human/M)
	if(partner_bodypart_override && M && M == target)
		if(istype(partner_bodypart_override, /obj/item/bodypart/head/dullahan))
			return "Голова [M.name]"
		return "[partner_bodypart_override.name] ([M.name])"

	return M?.name || "—"

/datum/sex_session_tgui/proc/set_partner_bodypart_override(obj/item/bodypart/B)
	partner_bodypart_override = B

/datum/sex_session_tgui/proc/get_current_partner()
	if(current_partner_ref)
		var/mob/living/carbon/human/M = locate(current_partner_ref)
		if(M && !QDELETED(M))
			return M
	if(target && !QDELETED(target))
		return target
	return user

/datum/sex_session_tgui/proc/build_org_nodes(mob/living/carbon/human/M, side)
	if(side == "partner" && partner_bodypart_override && M == target)
		return build_org_nodes_for_bodypart(partner_bodypart_override, side)

	var/list/out = list()
	out += list(list(
		"id" = SEX_ORGAN_FILTER_ALL,
		"name" = "Все",
		"busy" = FALSE,
		"side" = side,
	))

	out += list(list(
		"id" = SEX_ORGAN_FILTER_BODY,
		"name" = "Тело",
		"busy" = FALSE,
		"side" = side,
	))

	var/is_actor = (side == "actor")

	#define BUSY_FOR(id) (is_actor ? !slot_available_for(id) : is_partner_node_reserved(id, M))

	var/obj/item/bodypart/head/HD = M.get_bodypart(BODY_ZONE_HEAD)
	if(HD)
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_MOUTH,
			"name" = "Рот",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_MOUTH),
			"side" = side,
		))

	var/obj/item/bodypart/l_arm/LA = M.get_bodypart(BODY_ZONE_L_ARM)
	if(LA)
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_LHAND,
			"name" = "Левая рука",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_LHAND),
			"side" = side,
		))

	var/obj/item/bodypart/r_arm/RA = M.get_bodypart(BODY_ZONE_R_ARM)
	if(RA)
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_RHAND,
			"name" = "Правая рука",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_RHAND),
			"side" = side,
		))

	var/obj/item/bodypart/l_leg/LL = M.get_bodypart(BODY_ZONE_L_LEG)
	var/obj/item/bodypart/r_leg/RL = M.get_bodypart(BODY_ZONE_R_LEG)
	if(LL || RL)
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_LEGS,
			"name" = "Ноги",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_LEGS),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_TAIL))
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_TAIL,
			"name" = "Хвост",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_TAIL),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_BREASTS))
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_BREASTS,
			"name" = "Грудь",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_BREASTS),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_VAGINA))
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_VAGINA,
			"name" = "Вагина",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_VAGINA),
			"side" = side,
		))

	if(M.getorganslot(ORGAN_SLOT_PENIS))
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_PENIS,
			"name" = "Член",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_PENIS),
			"side" = side,
		))

	var/obj/item/bodypart/chest/C = M.get_bodypart(BODY_ZONE_CHEST)
	if(C)
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_ANUS,
			"name" = "Анус",
			"busy" = BUSY_FOR(SEX_ORGAN_FILTER_ANUS),
			"side" = side,
		))

	#undef BUSY_FOR

	return out

/datum/sex_session_tgui/proc/build_org_nodes_for_bodypart(obj/item/bodypart/B, side)
	var/list/out = list()
	out += list(list("id" = SEX_ORGAN_FILTER_BODY, "name" = "Тело", "busy" = FALSE, "side" = side))

	if(istype(B, /obj/item/bodypart/head) || istype(B, /obj/item/bodypart/head/dullahan))
		out += list(list(
			"id"   = SEX_ORGAN_FILTER_MOUTH,
			"name" = "Рот",
			"busy" = FALSE,
			"side" = side,
		))

	return out

/datum/sex_session_tgui/proc/category_of_actor_node(id)
	switch(id)
		if(SEX_ORGAN_FILTER_MOUTH)
			return SEX_ORGAN_FILTER_MOUTH
		if(SEX_ORGAN_FILTER_BREASTS)
			return SEX_ORGAN_FILTER_BREASTS
		if(SEX_ORGAN_FILTER_LHAND)
			return SEX_ORGAN_FILTER_LHAND
		if(SEX_ORGAN_FILTER_RHAND)
			return SEX_ORGAN_FILTER_RHAND
		if(SEX_ORGAN_FILTER_LEGS)
			return SEX_ORGAN_FILTER_LEGS
		if(SEX_ORGAN_FILTER_TAIL)
			return SEX_ORGAN_FILTER_TAIL
		if(SEX_ORGAN_FILTER_VAGINA, SEX_ORGAN_FILTER_PENIS, SEX_ORGAN_FILTER_ANUS)
			return SEX_ORGAN_FILTER_GENITAL
		if(SEX_ORGAN_FILTER_BODY)
			return "body"
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

	var/mob/living/carbon/human/U = user
	var/mob/living/carbon/human/T = get_current_partner()

	var/a_sel = selected_actor_organ_id
	var/p_sel = selected_partner_organ_id

	for(var/key in GLOB.sex_panel_actions)
		var/datum/sex_panel_action/A = GLOB.sex_panel_actions[key]
		if(!A)
			continue
		if(!A.shows_on_menu(U, T))
			continue

		if(A.required_init || A.required_target)
			if(!U)
				continue

			if(!(partner_bodypart_override && A.required_target == SEX_ORGAN_MOUTH))
				var/list/orgs = A.get_action_organs(U, T, FALSE, FALSE)
				if(!orgs)
					continue

			if(a_sel && a_sel != SEX_ORGAN_FILTER_ALL)
				if(a_sel == SEX_ORGAN_FILTER_BODY)
					if(A.required_init)
						continue
				else
					var/a_type = node_organ_type(a_sel)
					if(A.required_init && a_type && A.required_init != a_type)
						continue

			if(p_sel && p_sel != SEX_ORGAN_FILTER_ALL)
				var/list/targets = A.get_filter_target_organ_types()

				if(p_sel == SEX_ORGAN_FILTER_BODY)
					if(targets && targets.len)
						continue
				else
					var/p_type = node_organ_type(p_sel)
					if(targets && targets.len)
						if(!p_type || !(p_type in targets))
							continue
					else if(A.required_target && p_type && A.required_target != p_type)
						continue

		actions += list(list(
			"name" = A.name,
			"type" = key,
			"tags" = list(),
		))

	return actions

/datum/sex_session_tgui/proc/inherent_perform_check(datum/sex_panel_action/A, mob/living/carbon/human/U, mob/living/carbon/human/T)
	if(!T || !U)
		return FALSE
	if(U.stat != CONSCIOUS)
		return FALSE
	if(A.check_incapacitated && U.incapacitated())
		return FALSE

	var/atom/real_target = T
	if(partner_bodypart_override && T == target)
		real_target = partner_bodypart_override

	var/dist = get_dist(U, real_target)
	if(dist > 1)
		return FALSE

	if(A.check_same_tile)
		var/same_tile = (get_turf(U) == get_turf(real_target))
		var/grabstate = U.get_highest_grab_state_on(T)
		var/grab_bypass = (grabstate && grabstate >= GRAB_PASSIVE)

		if(!same_tile && !grab_bypass)
			return FALSE

	if(A.require_grab)
		var/grabstate2 = U.get_highest_grab_state_on(T)
		if(isnull(grabstate2) || grabstate2 < A.required_grab_state)
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

	return can_execute_action(A, a_id, p_id, performing)

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
	D["speed_names"] = speed_names.Copy()
	D["force_names"] = force_names.Copy()
	D["has_knotted_penis"] = has_knotted_penis
	return D

/datum/sex_session_tgui/ui_data(mob/user)
	update_knotted_penis_flag()
	var/list/D = list()

	var/mob/living/carbon/human/active_partner = get_current_partner()

	D["actions"] = actions_for_menu()
	D["title"] = "Соитие с [get_partner_display_name(active_partner)]"
	D["session_name"] = "Private Session"
	D["actor_name"] = src.user?.name || "—"
	D["partner_name"] = get_partner_display_name(active_partner)
	D["actor_organs"] = build_org_nodes(src.user, "actor")
	D["partner_organs"] = build_org_nodes(active_partner, "partner")
	D["selected_actor_organ"] = selected_actor_organ_id
	D["selected_partner_organ"] = selected_partner_organ_id
	D["speed"] = global_speed
	D["force"] = global_force

	if(can_see_partner_arousal())
		D["partner_arousal"] = clamp(round(partner_arousal_ui), 0, 100)
		D["partner_arousal_hidden"] = FALSE
	else
		D["partner_arousal"] = null
		D["partner_arousal_hidden"] = TRUE

	var/list/ad_user = list()
	if(src.user)
		SEND_SIGNAL(src.user, COMSIG_SEX_GET_AROUSAL, ad_user)

	var/cur_u = ad_user["arousal"] || 0
	var/is_frozen = ad_user["frozen"] || FALSE
	actor_arousal_ui = min(100, (cur_u / ERP_UI_MAX_AROUSAL) * 100)
	arousal_frozen = is_frozen
	D["actor_arousal"] = clamp(round(actor_arousal_ui), 0, 100)
	D["frozen"] = arousal_frozen
	var/charge_u = ad_user["charge"] || 0
	D["actor_charge"] = round(charge_u)
	
	D["do_until_finished"] = do_until_finished
	var/can_knot_now = FALSE
	if(has_knotted_penis && length(current_actions))
		for(var/id in current_actions)
			var/datum/sex_action_session/I = current_actions[id]
			if(!I || !I.action)
				continue
			if(I.session.user != src.user)
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

	var/mob/living/carbon/human/human_viewer = src.user
	D["status_organs"] = build_status_org_nodes(human_viewer)

	var/list/can = list()
	for(var/key in GLOB.sex_panel_actions)
		if(can_start_action_now(key))
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
	if(src.user)
		partners_data += list(list(
			"ref" = REF(src.user),
			"name" = "[src.user.name]"
		))

	for(var/mob/living/carbon/human/M in partners)
		if(QDELETED(M))
			continue
		partners_data += list(list(
			"ref" = REF(M),
			"name" = M.name
		))

	if(!current_partner_ref && src.user)
		current_partner_ref = REF(src.user)

	D["partners"] = partners_data
	D["current_partner_ref"] = current_partner_ref

	active_partner = get_current_partner()
	D["partner_name"] = get_partner_display_name(active_partner)

	var/list/links = list()
	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I)
			continue

		var/datum/sex_organ/tuned_org = resolve_organ_datum(I.actor, I.actor_node_id)
		if(!tuned_org)
			tuned_org = resolve_organ_datum(I.partner, I.partner_node_id)

		var/sens = tuned_org ? tuned_org.sensivity : 0
		var/pain = tuned_org ? tuned_org.pain : 0

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

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		D["passive_links"] = collect_passive_links_for(H)
	else
		D["passive_links"] = list()

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

				var/mob/living/carbon/human/partner = get_current_partner()
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
					if(M != user)
						target = M
					partner_bodypart_override = null
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
			else if(target_type == "partner")
				var/mob/living/carbon/human/P = get_current_partner()
				if(P)
					SEND_SIGNAL(P, COMSIG_SEX_SET_AROUSAL, amount)
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
			var/value = text2num(params["value"])

			var/datum/sex_action_session/I = current_actions[id]
			if(!I)
				return FALSE

			var/datum/sex_organ/user_org = resolve_organ_datum(I.actor, I.actor_node_id)
			if(!user_org)
				return FALSE

			user_org.sensivity = clamp(value, 0, user_org.sensivity_max)

			SStgui.update_uis(src)
			return TRUE

		if("flip")
			if(user)
				if(!islist(user.mob_timers))
					user.mob_timers = list()

				var/last = user.mob_timers["sexpanel_flip"] || 0
				if(world.time < last + 1 SECONDS)
					return FALSE

				user.mob_timers["sexpanel_flip"] = world.time
				user.sexpanel_flip()
			SStgui.update_uis(src)
			return TRUE

		if("freeze_arousal")
			if(user)
				SEND_SIGNAL(user, COMSIG_SEX_FREEZE_AROUSAL)

				var/list/ad = list()
				SEND_SIGNAL(user, COMSIG_SEX_GET_AROUSAL, ad)
				arousal_frozen = !!ad["frozen"]

			SStgui.update_uis(src)
			return TRUE

		if("toggle_erect")
			var/target_state = params["state"]
			var/id = params["id"]
			if(!id || id != SEX_ORGAN_FILTER_PENIS)
				return FALSE

			var/datum/sex_organ/O = resolve_organ_datum(user, id)
			if(!O)
				return FALSE

			var/obj/item/organ/penis/P = user.getorganslot(ORGAN_SLOT_PENIS)
			if(!P)
				return FALSE

			if(target_state == "auto")
				P.disable_manual_erect()
			else if(target_state == "none")
				P.set_manual_erect_state(ERECT_STATE_NONE)
			else if(target_state == "partial")
				P.set_manual_erect_state(ERECT_STATE_PARTIAL)
			else if(target_state == "hard")
				P.set_manual_erect_state(ERECT_STATE_HARD)

			update_knotted_penis_flag()
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
		partner_bodypart_override = null
	else
		if(!locate(current_partner_ref))
			var/mob/living/carbon/human/N = partners[1]
			current_partner_ref = REF(N)
			target = N
			partner_bodypart_override = null

/datum/sex_session_tgui/proc/try_start_action(action_type)
	var/datum/sex_panel_action/A = SEX_PANEL_ACTION(action_type)
	if(!A)
		return

	var/a_id = pick_actor_node_for_action(A)
	var/p_id = pick_partner_node_for_action(A)

	if(!a_id || !p_id)
		return

	if(!can_execute_action(A, a_id, p_id, TRUE))
		return

	var/datum/sex_action_session/existing = find_existing_action_session(A, a_id, p_id)
	if(existing)
		existing.speed = global_speed
		existing.force = global_force
		SStgui.update_uis(src)
		return

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

	var/datum/sex_organ/src_org = resolve_organ_datum(I.actor, I.actor_node_id)
	if(src_org)
		src_org.unbind()

	I.action.on_finish(I.actor, I.partner)
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

	var/mob/living/carbon/human/P = get_current_partner()
	if(P)
		SEND_SIGNAL(P, COMSIG_SEX_GET_AROUSAL, ad_tgt)

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

	if(!selected_actor_organ_id)
		return

	var/datum/sex_organ/src_org = resolve_organ_datum(user, selected_actor_organ_id)
	if(!src_org)
		return

	var/mob/living/carbon/human/P = get_current_partner()

	if(selected_partner_organ_id && P)
		var/datum/sex_organ/tgt_org = resolve_organ_datum(P, selected_partner_organ_id)
		if(tgt_org)
			src_org.bind_with(tgt_org)

	var/moved = src_org.inject_liquid()
	if(moved <= 0)
		return

/datum/sex_session_tgui/proc/resolve_organ_from_bodypart(obj/item/bodypart/B, id)
	if(!B || !id)
		return null

	if(istype(B, /obj/item/bodypart/head) || istype(B, /obj/item/bodypart/head/dullahan))
		if(id == SEX_ORGAN_FILTER_MOUTH)
			return B.sex_organ

	return null

/datum/sex_session_tgui/proc/resolve_organ_datum(mob/living/carbon/human/M, id)
	if(!M || !id)
		return null

	if(M == target && partner_bodypart_override)
		var/datum/sex_organ/over_org = resolve_organ_from_bodypart(partner_bodypart_override, id)
		if(over_org)
			return over_org

	switch(id)
		if(SEX_ORGAN_FILTER_MOUTH)
			var/obj/item/bodypart/head/HD = M.get_bodypart(BODY_ZONE_HEAD)
			return HD?.sex_organ
		if(SEX_ORGAN_FILTER_LHAND)
			var/obj/item/bodypart/l_arm/LA = M.get_bodypart(BODY_ZONE_L_ARM)
			return LA?.sex_organ
		if(SEX_ORGAN_FILTER_RHAND)
			var/obj/item/bodypart/r_arm/RA = M.get_bodypart(BODY_ZONE_R_ARM)
			return RA?.sex_organ
		if(SEX_ORGAN_FILTER_LEGS)
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				return H.ensure_legs_organ()
			return null
		if(SEX_ORGAN_FILTER_TAIL)
			var/obj/item/organ/tail/T = M.getorganslot(ORGAN_SLOT_TAIL)
			return T?.sex_organ
		if(SEX_ORGAN_FILTER_BREASTS)
			var/obj/item/organ/breasts/B = M.getorganslot(ORGAN_SLOT_BREASTS)
			return B?.sex_organ
		if(SEX_ORGAN_FILTER_VAGINA)
			var/obj/item/organ/vagina/V = M.getorganslot(ORGAN_SLOT_VAGINA)
			return V?.sex_organ
		if(SEX_ORGAN_FILTER_PENIS)
			var/obj/item/organ/penis/P = M.getorganslot(ORGAN_SLOT_PENIS)
			return P?.sex_organ
		if(SEX_ORGAN_FILTER_ANUS)
			var/obj/item/bodypart/chest/A = M.get_bodypart(BODY_ZONE_CHEST)
			return A?.sex_organ
		if(SEX_ORGAN_FILTER_BODY)
			if(ishuman(M))
				var/mob/living/carbon/human/H2 = M
				return H2.ensure_body_organ()
			return null

	return null

/datum/sex_session_tgui/proc/node_organ_type(id)
	switch(id)
		if(SEX_ORGAN_FILTER_MOUTH)
			return SEX_ORGAN_MOUTH
		if(SEX_ORGAN_FILTER_LHAND, SEX_ORGAN_FILTER_RHAND)
			return SEX_ORGAN_HANDS
		if(SEX_ORGAN_FILTER_LEGS)
			return SEX_ORGAN_LEGS
		if(SEX_ORGAN_FILTER_TAIL)
			return SEX_ORGAN_TAIL
		if(SEX_ORGAN_FILTER_BREASTS)
			return SEX_ORGAN_BREASTS
		if(SEX_ORGAN_FILTER_VAGINA)
			return SEX_ORGAN_VAGINA
		if(SEX_ORGAN_FILTER_PENIS)
			return SEX_ORGAN_PENIS
		if(SEX_ORGAN_FILTER_ANUS)
			return SEX_ORGAN_ANUS
	return null

/datum/sex_session_tgui/proc/pick_actor_node_for_action(datum/sex_panel_action/A)
	if(!A)
		return null

	if(!A.required_init)
		var/body_cat = category_of_actor_node(SEX_ORGAN_FILTER_BODY)
		if(!is_locked(body_cat))
			return SEX_ORGAN_FILTER_BODY
		return null

	if(selected_actor_organ_id)
		var/sel_type = node_organ_type(selected_actor_organ_id)
		if(sel_type && sel_type == A.required_init)
			var/sel_cat = category_of_actor_node(selected_actor_organ_id)
			if(!is_locked(sel_cat))
				return selected_actor_organ_id

	var/list/nodes = build_org_nodes(user, "actor")
	for(var/i in 1 to nodes.len)
		var/list/N = nodes[i]
		var/id = N["id"]

		if(id == SEX_ORGAN_FILTER_BODY)
			continue

		var/t = node_organ_type(id)
		if(!t || t != A.required_init)
			continue

		var/cat = category_of_actor_node(id)
		if(is_locked(cat))
			continue

		return id

	return null

/datum/sex_session_tgui/proc/pick_partner_node_for_action(datum/sex_panel_action/A)
	var/mob/living/carbon/human/P = get_current_partner()
	if(!P)
		return null

	if(!A.required_target)
		return SEX_ORGAN_FILTER_BODY

	if(selected_partner_organ_id)
		var/t = node_organ_type(selected_partner_organ_id)
		if(A.required_target == t)
			return selected_partner_organ_id

	var/list/nodes = build_org_nodes(P, "partner")
	for(var/i in 1 to nodes.len)
		var/list/N = nodes[i]
		var/id = N["id"]
		if(id == SEX_ORGAN_FILTER_BODY)
			continue

		var/t2 = node_organ_type(id)
		if(A.required_target && A.required_target != t2)
			continue

		return id

	return null

/datum/sex_session_tgui/proc/start_broadcast_loop()
	if(broadcast_timer_id)
		return
	broadcast_timer_id = addtimer(CALLBACK(src, PROC_REF(broadcast_tick)), 1 SECONDS, TIMER_STOPPABLE)

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
	if(choice && choice.action)
		choice.action.on_perform(choice.actor, choice.partner)

	var/total_mult = 0.0
	var/count = 0

	for(var/datum/sex_action_session/S in candidates)
		total_mult += get_speed_multiplier(S.speed)
		count++

	var/avg_mult = (count > 0) ? (total_mult / count) : 1.0

	var/base_delay = 5 SECONDS
	var/next_delay = base_delay

	if(avg_mult > 0)
		next_delay = round(base_delay / avg_mult)

	if(next_delay < 1 SECONDS)
		next_delay = 1 SECONDS

	broadcast_timer_id = addtimer(CALLBACK(src, PROC_REF(broadcast_tick)), next_delay, TIMER_STOPPABLE)

/datum/sex_session_tgui/proc/can_continue_action_session(datum/sex_action_session/I)
	if(!I || !I.action)
		return FALSE

	var/mob/living/carbon/human/U = I.actor
	var/mob/living/carbon/human/T = I.partner

	if(!U || !T)
		return FALSE

	if(!inherent_perform_check(I.action, U, T))
		return FALSE

	if(!I.action.can_perform(U, T))
		return FALSE

	var/datum/sex_organ/src_org = null
	var/datum/sex_organ/tgt_org = null

	if(I.actor_node_id)
		src_org = resolve_organ_datum(U, I.actor_node_id)
	if(I.partner_node_id)
		tgt_org = resolve_organ_datum(T, I.partner_node_id)

	if(I.action.required_init && !src_org)
		return FALSE

	if(I.action.required_target && !tgt_org)
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
	if(!M)
		return list()

	var/list/nodes = build_org_nodes(M, "actor")
	var/list/out = list()

	for(var/i in 1 to nodes.len)
		var/list/N = nodes[i]
		var/id = N["id"]

		// "Все" — чистый фильтр для меню, в статусе не нужен
		if(id == SEX_ORGAN_FILTER_ALL)
			continue

		var/datum/sex_organ/O = resolve_organ_datum(M, id)
		var/sens = O ? O.sensivity : 0
		var/pain = O ? O.pain : 0

		var/fullness = 0
		if(O && O.stored_liquid && O.stored_liquid_max > 0)
			var/cur = O.stored_liquid.total_volume
			if(cur > 0)
				fullness = clamp(round((cur / O.stored_liquid_max) * 100), 0, 100)

		if(id == SEX_ORGAN_FILTER_PENIS)
			var/obj/item/organ/penis/P = M.getorganslot(ORGAN_SLOT_PENIS)
			if(P)
				N["erect"] = P.erect_state
				N["manual"] = P.manual_erection_override

		N["sensitivity"] = sens
		N["pain"] = pain
		N["fullness"] = fullness

		out += list(N)

	return out

/datum/sex_session_tgui/proc/can_see_partner_arousal()
	if(!user)
		return FALSE

	var/mob/living/carbon/human/P = get_current_partner()
	if(!P)
		return FALSE
	if(user == P)
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

	if(!ishuman(mover))
		return

	var/mob/living/carbon/human/H = mover
	var/list/to_stop = list()
	var/moved_breaks_any = FALSE

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I || QDELETED(I) || !I.action)
			continue

		if(H != I.actor && H != I.partner)
			continue

		var/stop = FALSE
		if(!can_continue_action_session(I))
			stop = TRUE
		else
			var/datum/sex_panel_action/A = I.action
			if(A.break_on_move)
				stop = TRUE
				moved_breaks_any = TRUE

		if(stop)
			to_stop += id

	for(var/id in to_stop)
		stop_instance(id)

	if(moved_breaks_any)
		to_chat(H, span_notice("Движение прерывает часть интимных действий."))

/proc/get_or_create_sex_session_tgui(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return get_or_create_sex_session_tgui_with_bodypart(user, target, null)

/proc/get_or_create_sex_session_tgui_with_bodypart(mob/living/carbon/human/user, mob/living/carbon/human/target, obj/item/bodypart/body_override)
	if(!user)
		return null

	var/list/sessions = return_sessions_with_user_tgui(user)
	var/datum/sex_session_tgui/session

	if(length(sessions))
		session = sessions[1]
	else
		session = new /datum/sex_session_tgui(user, target)

	if(target && target != user)
		session.add_partner(target)
		if(!session.current_partner_ref || !locate(session.current_partner_ref))
			session.current_partner_ref = REF(target)
			session.target = target

	if(body_override)
		session.set_partner_bodypart_override(body_override)

	session.update_knotted_penis_flag()
	return session

/datum/sex_session_tgui/proc/actions_matching_nodes()
	var/list/res = list()

	if(!selected_actor_organ_id || !selected_partner_organ_id)
		return res

	var/a_sel = selected_actor_organ_id
	var/p_sel = selected_partner_organ_id

	var/a_type = node_organ_type(a_sel)
	var/p_type = node_organ_type(p_sel)

	for(var/key in GLOB.sex_panel_actions)
		var/datum/sex_panel_action/A = GLOB.sex_panel_actions[key]
		if(!A)
			continue

		if(a_sel == SEX_ORGAN_FILTER_BODY)
			if(A.required_init)
				continue
		else if(a_sel != SEX_ORGAN_FILTER_ALL)
			if(!A.required_init || !a_type || A.required_init != a_type)
				continue

		var/list/targets = A.get_filter_target_organ_types()
		if(p_sel == SEX_ORGAN_FILTER_BODY)
			if(targets && targets.len)
				continue
		else if(p_sel != SEX_ORGAN_FILTER_ALL)
			if(!targets || !p_type || !(p_type in targets))
				continue

		res += key

	return res

/datum/sex_session_tgui/proc/get_best_action_session_for(mob/living/carbon/human/U)
	if(!U || !length(current_actions))
		return null

	var/datum/sex_action_session/best = null
	var/best_score = -1

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I || QDELETED(I) || !I.action)
			continue

		var/score = I.get_priority_for(U)
		if(score > best_score)
			best_score = score
			best = I

	return best

/datum/sex_session_tgui/proc/can_start_action_now(action_type)
	if(!action_type)
		return FALSE

	var/datum/sex_panel_action/A = SEX_PANEL_ACTION(action_type)
	if(!A)
		return FALSE

	var/a_id = pick_actor_node_for_action(A)
	var/p_id = pick_partner_node_for_action(A)

	return can_execute_action(A, a_id, p_id, TRUE)

/datum/sex_session_tgui/proc/is_partner_node_reserved(node_id, mob/living/carbon/human/P)
	if(!node_id || !P)
		return FALSE
	if(!length(current_actions))
		return FALSE

	var/candidate_type = node_organ_type(node_id)
	if(!candidate_type)
		return FALSE

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I || QDELETED(I) || !I.action)
			continue

		if(I.partner != P)
			continue

		if(!I.action.reserve_target_for_session)
			continue

		var/list/reserved_types = I.action.get_reserved_target_organ_types()
		if(!islist(reserved_types) || !reserved_types.len)
			continue

		if(candidate_type in reserved_types)
			return TRUE

	return FALSE

/datum/sex_session_tgui/proc/can_execute_action(datum/sex_panel_action/A, actor_node_id, partner_node_id, perform_checks = FALSE)
	if(!A)
		return FALSE

	var/mob/living/carbon/human/U = user
	var/mob/living/carbon/human/T = get_current_partner()

	var/a_id = actor_node_id
	var/p_id = partner_node_id

	var/a_type = a_id ? node_organ_type(a_id) : null
	var/p_type = p_id ? node_organ_type(p_id) : null

	if(a_type == SEX_ORGAN_PENIS && U)
		var/datum/component/knotting/K = U.GetComponent(/datum/component/knotting)
		if(K && K.knotted_status == KNOTTED_AS_TOP && K.knotted_recipient)
			return FALSE

	if(A.required_init && a_type && A.required_init != a_type)
		return FALSE
	if(A.required_target && p_type && A.required_target != p_type)
		return FALSE

	if(!A.can_perform(U, T))
		return FALSE

	var/a_cat = a_id ? category_of_actor_node(a_id) : null
	if(a_cat && is_locked(a_cat))
		return FALSE

	if(perform_checks)
		if(A.required_init && !a_type)
			return FALSE
		if(A.required_target && !p_type)
			return FALSE

		if(p_id && T)
			var/mob/living/carbon/human/P = T
			if(P && is_partner_node_reserved(p_id, P))
				return FALSE

		if(!inherent_perform_check(A, U, T))
			return FALSE

	return TRUE

/datum/sex_session_tgui/proc/find_existing_action_session(datum/sex_panel_action/A, actor_node_id, partner_node_id)
	if(!A || !actor_node_id || !partner_node_id)
		return null
	if(!length(current_actions))
		return null

	for(var/id in current_actions)
		var/datum/sex_action_session/I = current_actions[id]
		if(!I || QDELETED(I) || !I.action)
			continue

		if(I.action_type != A.type)
			continue
		if(I.actor_node_id != actor_node_id)
			continue
		if(I.partner_node_id != partner_node_id)
			continue

		return I

	return null

/datum/sex_session_tgui/proc/is_node_busy_for_side(node_id, mob/living/carbon/human/M, side)
	if(!node_id || !M)
		return FALSE

	if(side == "actor")
		return !slot_available_for(node_id)

	if(side == "partner")
		return is_partner_node_reserved(node_id, M)

	return FALSE
