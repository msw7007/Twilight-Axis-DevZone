/datum/sex_panel_action
	/// Action name
	var/name = "Generic Action"
	/// Can be action present in panel
	abstract_type = TRUE
	/// Can action use penis knot
	var/can_knot = FALSE
	/// Sex organ requred to init action
	var/required_init
	/// Sex organ required to target
	var/required_target
	/// Armor slot that prevent action
	var/armor_slot_init
	var/armor_slot_target
	/// How long each iteration takes
	var/interaction_timer = 3 SECONDS
	/// How much stamina each iteration takes
	var/stamina_cost = 0.5
	/// Whether to check if user is incapacitated
	var/check_incapacitated = TRUE
	/// need to be on same tile
	var/check_same_tile = FALSE
	/// Whether this requires a grab
	var/require_grab = FALSE
	/// Minimum grab state required
	var/required_grab_state = GRAB_PASSIVE
	/// Can action affects self arousal?
	var/affects_self_arousal = 0
	/// Can action affects self pain?
	var/affects_self_pain = 0
	/// Can action affects target arousal?
	var/affects_arousal = 0
	/// Can action affects target pain?
	var/affects_pain = 0
	/// Get pose of partners
	var/pose_key = SEX_POSE_BOTH_STANDING
	/// Link to session data
	var/datum/sex_action_session/session
	/// Is taregt organ reserverd for action
	var/reserve_target_for_session = FALSE
	var/obj/item/active_container = null
	var/break_on_move = TRUE

/datum/sex_panel_action/proc/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(abstract_type)
		return FALSE
	return TRUE

/datum/sex_panel_action/proc/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SHOULD_CALL_PARENT(TRUE)

	if(!user || !target)
		return FALSE

	var/list/orgs = get_action_organs(user, target, FALSE, FALSE)
	if(!orgs || !orgs.len)
		return FALSE

	var/datum/sex_organ/init_organ   = orgs["init"]
	var/datum/sex_organ/target_organ = orgs["target"]

	var/list/to_check = list()
	if(init_organ)
		to_check += init_organ
	if(target_organ)
		to_check += target_organ

	for(var/datum/sex_organ/O in to_check)
		if(!O)
			continue

		var/node_id = O.organ_type
		if(!node_id)
			continue

		var/mob/living/carbon/human/owner = null

		if(istype(O.organ_link, /obj/item/bodypart))
			var/obj/item/bodypart/BP = O.organ_link
			owner = BP.owner
		else if(istype(O.organ_link, /obj/item/organ))
			var/obj/item/organ/ORG = O.organ_link
			owner = ORG.owner

		if(!owner)
			continue

		if(owner.is_sex_node_restrained(node_id))
			return FALSE

	if(!passes_armor_check(user, target))
		return FALSE

	return TRUE

/datum/sex_panel_action/proc/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/sex_action_session/new_session)
	SHOULD_CALL_PARENT(TRUE)
	session = new_session
	var/message = span_warning(get_start_message(user, target))
	if(message)
		user.visible_message(message)
	
	var/list/orgs = connect_organs(user, target)
	if(!orgs)
		return FALSE	

	return TRUE

/datum/sex_panel_action/proc/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message = get_perform_message(user, target)
	if(message)
		user.visible_message(message)
	return

/datum/sex_panel_action/proc/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SHOULD_CALL_PARENT(TRUE)
	session = null
	var/message = span_warning(get_finish_message(user, target))
	if(message)
		user.visible_message(message)
	return TRUE

/datum/sex_panel_action/proc/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_panel_action/proc/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_panel_action/proc/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_panel_action/proc/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return null

/datum/sex_panel_action/proc/get_knot_count()
	return 0

/datum/sex_panel_action/proc/try_knot_on_climax(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!can_knot || !user || !target)
		return FALSE

	var/datum/sex_session_tgui/session = get_or_create_sex_session_tgui(user, target)
	if(!session)
		return FALSE

	var/force_level = session.global_force
	return SEND_SIGNAL(user, COMSIG_SEX_TRY_KNOT, target, force_level, get_knot_count())

/datum/sex_panel_action/proc/do_onomatopoeia(mob/living/carbon/human/user)
	user.balloon_alert_to_viewers("Plap!", x_offset = rand(-15, 15), y_offset = rand(0, 25))

/datum/sex_panel_action/proc/show_sex_effects(mob/living/carbon/human/user)
	for(var/i in 1 to rand(1, 3))
		if(!user.cmode)
			new /obj/effect/temp_visual/heart/sex_effects(get_turf(user))
		else
			new /obj/effect/temp_visual/heart/sex_effects/red_heart(get_turf(user))

/datum/sex_panel_action/proc/do_sound_effect(mob/living/carbon/human/user)
	var/sound
	switch(session.force)
		if(SEX_FORCE_LOW, SEX_FORCE_MID)
			sound = pick(SEX_SOUNDS_SLOW)
		if(SEX_FORCE_HIGH, SEX_FORCE_EXTREME)
			sound = pick(SEX_SOUNDS_HARD)
	playsound(user, sound, 30, TRUE, -2, ignore_walls = FALSE)

/datum/sex_panel_action/proc/get_action_organs(mob/living/carbon/human/user, mob/living/carbon/human/target, only_free_init = TRUE, only_free_target = FALSE)

	var/datum/sex_organ/init_organ
	var/datum/sex_organ/target_organ

	if(required_init)
		init_organ = user.get_sex_organ_by_type(required_init, only_free_init)
		if(!init_organ)
			return null

	if(required_target)
		target_organ = target.get_sex_organ_by_type(required_target, only_free_target)
		if(!target_organ)
			return null

	return list(
		"init" = init_organ,
		"target" = target_organ,
	)

/datum/sex_panel_action/proc/connect_organs(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!required_init && !required_target)
		return null

	var/list/orgs = get_action_organs(user, target)
	if(!orgs)
		return FALSE

	var/datum/sex_organ/init_organ = orgs["init"]
	var/datum/sex_organ/target_organ = orgs["target"]

	if(init_organ && target_organ)
		if(!init_organ.can_start_active())
			return FALSE
		if(!init_organ.start_active(target_organ))
			return FALSE

	return orgs

/datum/sex_panel_action/proc/get_pose_key(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target)
		return SEX_POSE_BOTH_STANDING

	if(user.lying && target.lying)
		return SEX_POSE_BOTH_LYING
	if(user.lying)
		return SEX_POSE_USER_LYING
	if(target.lying)
		return SEX_POSE_TARGET_LYING

	return SEX_POSE_BOTH_STANDING

/datum/sex_panel_action/proc/get_pose_text(pose_state)
	switch(pose_state)
		if(SEX_POSE_BOTH_STANDING)
			return "стоя"
		if(SEX_POSE_USER_LYING)
			return "снизу"
		if(SEX_POSE_TARGET_LYING)
			return "сверху"
		if(SEX_POSE_BOTH_LYING)
			return "лежа"

/datum/sex_panel_action/proc/get_force_text()
	var/action_force = session.force
	switch(action_force)
		if(SEX_FORCE_LOW)
			return pick(list("нежно", "заботливо", "ласково", "мягко", "осторожно", "неторопливо"))
		if(SEX_FORCE_MID)
			return pick(list("решительно", "энергично", "страстно", "уверенно", "увлеченно"))
		if(SEX_FORCE_HIGH)
			return pick(list("грубо", "небрежно", "жестко", "пылко", "свирепо"))
		if(SEX_FORCE_EXTREME)
			return pick(list("жестоко", "неистово", "неумолимо", "свирепо", "безжалостно"))

/datum/sex_panel_action/proc/get_speed_text()
	var/action_speed = session.speed
	switch(action_speed)
		if(SEX_SPEED_LOW)
			return pick(list("медленно", "неторопливо", "бережно", "тягуче", "размеренно"))
		if(SEX_SPEED_MID)
			return pick(list("ритмично", "уверенно", "плавно", "напористо", "спокойно"))
		if(SEX_SPEED_HIGH)
			return pick(list("быстро", "часто", "торопливо", "резко", "интенсивно"))
		if(SEX_SPEED_EXTREME)
			return pick(list("агрессивно", "стремительно", "бурно", "яростно", "взахлеб"))

/datum/sex_panel_action/proc/spanify_force(string)
	var/action_force = session.force
	switch(action_force)
		if(SEX_FORCE_LOW)
			return "<span class='love_low'>[string]</span>"
		if(SEX_FORCE_MID)
			return "<span class='love_mid'>[string]</span>"
		if(SEX_FORCE_HIGH)
			return "<span class='love_high'>[string]</span>"
		if(SEX_FORCE_EXTREME)
			return "<span class='love_extreme'>[string]</span>"

/datum/sex_panel_action/proc/get_target_zone(mob/living/user, mob/living/target)
	var/list/zone_translations = list(
		BODY_ZONE_HEAD              = "голову",
		BODY_ZONE_CHEST             = "туловище",
		BODY_ZONE_R_ARM             = "правую руку",
		BODY_ZONE_L_ARM             = "левую руку",
		BODY_ZONE_R_LEG             = "правую ногу",
		BODY_ZONE_L_LEG             = "левую ногу",
		BODY_ZONE_PRECISE_R_INHAND  = "правую ладонь",
		BODY_ZONE_PRECISE_L_INHAND  = "левую ладонь",
		BODY_ZONE_PRECISE_R_FOOT    = "правую ступню",
		BODY_ZONE_PRECISE_L_FOOT    = "левую ступню",
		BODY_ZONE_PRECISE_SKULL     = "лоб",
		BODY_ZONE_PRECISE_EARS      = "уши",
		BODY_ZONE_PRECISE_R_EYE     = "правый глаз",
		BODY_ZONE_PRECISE_L_EYE     = "левый глаз",
		BODY_ZONE_PRECISE_NOSE      = "нос",
		BODY_ZONE_PRECISE_MOUTH     = "рот",
		BODY_ZONE_PRECISE_NECK      = "шею",
		BODY_ZONE_PRECISE_STOMACH   = "живот",
		BODY_ZONE_PRECISE_GROIN     = "пах",
	)

	var/zone = user?.zone_selected
	var/ru_zone_selected = zone_translations[zone]

	if(!ru_zone_selected)
		return "тело"

	if(target && ishuman(target))
		var/mob/living/carbon/human/H = target

		if(zone in list(BODY_ZONE_R_LEG, BODY_ZONE_L_LEG, BODY_ZONE_PRECISE_R_FOOT, BODY_ZONE_PRECISE_L_FOOT))
			var/has_legs = H.get_bodypart(BODY_ZONE_R_LEG) || H.get_bodypart(BODY_ZONE_L_LEG)
			if(!has_legs)
				return "туловище"

		if(zone in list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_PRECISE_R_INHAND, BODY_ZONE_PRECISE_L_INHAND))
			var/has_arms = H.get_bodypart(BODY_ZONE_R_ARM) || H.get_bodypart(BODY_ZONE_L_ARM)
			if(!has_arms)
				return "туловище"

		if(zone in list(
			BODY_ZONE_HEAD,
			BODY_ZONE_PRECISE_SKULL,
			BODY_ZONE_PRECISE_EARS,
			BODY_ZONE_PRECISE_R_EYE,
			BODY_ZONE_PRECISE_L_EYE,
			BODY_ZONE_PRECISE_NOSE,
			BODY_ZONE_PRECISE_MOUTH,
			BODY_ZONE_PRECISE_NECK,
		))
			var/has_head = H.get_bodypart(BODY_ZONE_HEAD)
			if(!has_head)
				return "туловище"

	return ru_zone_selected

/datum/sex_panel_action/proc/do_liquid_injection(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/orgs = get_action_organs(user, target, FALSE, FALSE)
	if(!orgs) return 0

	var/datum/sex_organ/target_organ = orgs["target"]
	if(!target_organ) return 0

	var/moved = target_organ.inject_liquid()
	if(moved > 0)
		handle_injection_feedback(user, target, moved)
	return moved

/datum/sex_panel_action/proc/handle_injection_feedback(mob/living/carbon/human/user, mob/living/carbon/human/target, moved)
	return

/datum/sex_panel_action/proc/passes_armor_check(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/init_zone = armor_slot_init
	var/target_zone = armor_slot_target

	if(!init_zone && required_init)
		init_zone = sex_organ_to_zone(required_init)
	if(!target_zone && required_target)
		target_zone = sex_organ_to_zone(required_target)

	if(init_zone && user)
		if(!can_access_erp_zone(user, user, init_zone, FALSE, GRAB_PASSIVE))
			return FALSE

	if(target_zone && target)
		if(!can_access_erp_zone(user, target, target_zone, FALSE, GRAB_PASSIVE))
			return FALSE

	return TRUE

/datum/sex_panel_action/proc/get_reserved_target_organ_types()
	if(!reserve_target_for_session)
		return null

	if(required_target)
		return list(required_target)

	return null

/datum/sex_panel_action/proc/find_best_container(mob/living/carbon/human/user, mob/living/carbon/human/target, datum/sex_organ/organ)
	if(user)
		var/obj/item/I_left = user.get_item_for_held_index(LEFT_HANDS)
		if(istype(I_left, /obj/item/reagent_containers))
			return I_left

		var/obj/item/I_right = user.get_item_for_held_index(RIGHT_HANDS)
		if(istype(I_right, /obj/item/reagent_containers))
			return I_right

	if(organ)
		var/obj/item/C = organ.find_liquid_container()
		if(C)
			return C

	return null

/datum/sex_panel_action/proc/get_filter_target_organ_types()
	if(required_target)
		return list(required_target)
	return null

/datum/sex_panel_action/proc/is_agressive_tier()
	if(!session)
		return FALSE

	switch(session.force)
		if(SEX_FORCE_LOW, SEX_FORCE_MID)
			return FALSE
		if(SEX_FORCE_HIGH, SEX_FORCE_EXTREME)
			return TRUE

	return FALSE
