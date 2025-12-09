/datum/sex_action_editor_tgui
	var/mob/living/carbon/human/user

/datum/sex_action_editor_tgui/New(mob/living/carbon/human/U)
	. = ..()
	user = U

/datum/sex_action_editor_tgui/ui_key()
	return "SexCustomActionEditor"

/datum/sex_action_editor_tgui/ui_state(mob/user)
	return GLOB.conscious_state

/datum/sex_action_editor_tgui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, ui_key(), "Редактор действий")
		ui.open()

/datum/sex_action_editor_tgui/ui_static_data(mob/user)
	var/list/D = list()

	D["climax_modes"] = list(
		"none" = "Без перелива",
		"into" = "Внутрь",
		"onto" = "Снаружи",
	)

	return D

/datum/sex_action_editor_tgui/proc/build_templates()
	var/list/out = list()
	for(var/key in GLOB.sex_panel_actions)
		var/datum/sex_panel_action/A = GLOB.sex_panel_actions[key]
		if(!A)
			continue
		if(A.abstract_type)
			continue
		if(!A.can_be_custom)
			continue

		out += list(list(
			"type" = key,         // этот key потом прилетит как template_type
			"name" = A.name,
			"stamina_cost" = A.stamina_cost,
			"affects_self_arousal" = A.affects_self_arousal,
			"affects_arousal" = A.affects_arousal,
			"affects_self_pain" = A.affects_self_pain,
			"affects_pain" = A.affects_pain,
			"can_knot" = A.can_knot,
			"climax_liquid_mode" = A.climax_liquid_mode,
			"message_on_start" = A.message_on_start,
			"message_on_perform" = A.message_on_perform,
			"message_on_finish" = A.message_on_finish,
			"message_on_climax_actor" = A.message_on_climax_actor,
			"message_on_climax_target" = A.message_on_climax_target,
		))
	return out

/datum/sex_action_editor_tgui/proc/build_custom()
	var/list/out = list()
	var/ck = user?.client?.ckey
	if(!ck)
		return out

	for(var/datum/sex_panel_action/A in get_custom_actions_for_ckey(ck))
		out += list(list(
			"type" = A.custom_key, // ключ, по которому она лежит в GLOB
			"name" = A.name,
			"stamina_cost" = A.stamina_cost,
			"affects_self_arousal" = A.affects_self_arousal,
			"affects_arousal" = A.affects_arousal,
			"affects_self_pain" = A.affects_self_pain,
			"affects_pain" = A.affects_pain,
			"can_knot" = A.can_knot,
			"climax_liquid_mode" = A.climax_liquid_mode,
			"message_on_start" = A.message_on_start,
			"message_on_perform" = A.message_on_perform,
			"message_on_finish" = A.message_on_finish,
			"message_on_climax_actor" = A.message_on_climax_actor,
			"message_on_climax_target" = A.message_on_climax_target,
		))
	return out

/datum/sex_action_editor_tgui/ui_data(mob/user)
	var/list/D = list()
	D["templates"] = build_templates()
	D["custom_actions"] = build_custom()
	return D

/datum/sex_action_editor_tgui/proc/get_action_by_key(key)
	if(!key || !islist(GLOB.sex_panel_actions))
		return null
	return GLOB.sex_panel_actions[key]

/datum/sex_action_editor_tgui/proc/handle_create(list/params)
	if(!user || !user.client)
		return

	var/template_type = params["template_type"]
	if(!template_type)
		return

	var/datum/sex_panel_action/base = get_action_by_key(template_type)
	if(!base || base.abstract_type || !base.can_be_custom)
		return

	var/datum/sex_panel_action/custom = new /datum/sex_panel_action
	custom.is_custom = TRUE
	custom.ckey = user.client.ckey

	custom.required_init = base.required_init
	custom.required_target = base.required_target
	custom.armor_slot_init = base.armor_slot_init
	custom.armor_slot_target = base.armor_slot_target
	custom.can_knot = base.can_knot
	custom.reserve_target_for_session = base.reserve_target_for_session

	custom.stamina_cost = text2num(params["stamina_cost"] || "[base.stamina_cost]")
	custom.affects_self_arousal = text2num(params["affects_self_arousal"] || "[base.affects_self_arousal]")
	custom.affects_arousal = text2num(params["affects_arousal"] || "[base.affects_arousal]")
	custom.affects_self_pain = text2num(params["affects_self_pain"] || "[base.affects_self_pain]")
	custom.affects_pain = text2num(params["affects_pain"] || "[base.affects_pain]")

	custom.name = params["name"] || base.name

	custom.message_on_start   = params["message_on_start"]   || base.message_on_start
	custom.message_on_perform = params["message_on_perform"] || base.message_on_perform
	custom.message_on_finish  = params["message_on_finish"]  || base.message_on_finish
	custom.message_on_climax_actor  = params["message_on_climax_actor"]  || base.message_on_climax_actor
	custom.message_on_climax_target = params["message_on_climax_target"] || base.message_on_climax_target

	custom.climax_liquid_mode = params["climax_liquid_mode"] || base.climax_liquid_mode

	register_custom_sex_action(custom)

/datum/sex_action_editor_tgui/proc/handle_update(list/params)
	if(!user || !user.client)
		return

	var/key = params["type"] // custom_key
	if(!key)
		return

	var/datum/sex_panel_action/A = get_action_by_key(key)
	if(!A || !A.is_custom)
		return
	if(A.ckey != user.client.ckey)
		return

	if(params["name"])
		A.name = params["name"]

	if(params["stamina_cost"])
		A.stamina_cost = text2num(params["stamina_cost"])

	if(params["affects_self_arousal"])
		A.affects_self_arousal = text2num(params["affects_self_arousal"])

	if(params["affects_arousal"])
		A.affects_arousal = text2num(params["affects_arousal"])

	if(params["affects_self_pain"])
		A.affects_self_pain = text2num(params["affects_self_pain"])

	if(params["affects_pain"])
		A.affects_pain = text2num(params["affects_pain"])

	if(params["climax_liquid_mode"])
		A.climax_liquid_mode = params["climax_liquid_mode"]

	if(params["message_on_start"])
		A.message_on_start = params["message_on_start"]

	if(params["message_on_perform"])
		A.message_on_perform = params["message_on_perform"]

	if(params["message_on_finish"])
		A.message_on_finish = params["message_on_finish"]

	if(params["message_on_climax_actor"])
		A.message_on_climax_actor = params["message_on_climax_actor"]

	if(params["message_on_climax_target"])
		A.message_on_climax_target = params["message_on_climax_target"]

/datum/sex_action_editor_tgui/proc/handle_delete(list/params)
	if(!user || !user.client)
		return

	var/key = params["type"]
	if(!key)
		return

	var/datum/sex_panel_action/A = get_action_by_key(key)
	if(!A || !A.is_custom)
		return
	if(A.ckey != user.client.ckey)
		return

	unregister_custom_sex_action(A)
	qdel(A)

/datum/sex_action_editor_tgui/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("custom_create")
			handle_create(params)
			SStgui.update_uis(src)
			return TRUE

		if("custom_update")
			handle_update(params)
			SStgui.update_uis(src)
			return TRUE

		if("custom_delete")
			handle_delete(params)
			SStgui.update_uis(src)
			return TRUE

	return FALSE

/mob/living/carbon/human/proc/open_sex_custom_editor()
	var/datum/sex_action_editor_tgui/E = new(src)
	E.ui_interact(src, null)
