/datum/sex_panel_action/test_simple
	abstract_type = FALSE

	name = "Тестовое действие"

	can_knot = FALSE
	continous = TRUE
	interaction_timer = 2 SECONDS
	stamina_cost = 0.25

	check_incapacitated = FALSE
	check_same_tile = FALSE
	require_grab = FALSE
	required_grab_state = GRAB_PASSIVE

	required_init   = SEX_ORGAN_HANDS
	required_target = SEX_ORGAN_HANDS
	armor_slot_lock = null

	affects_self_arousal = 0.5
	affects_arousal      = 0.5
	affects_self_pain    = 0
	affects_pain         = 0

/datum/sex_panel_action/test_simple/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	if(!user || !target)
		return FALSE

	return TRUE

/datum/sex_panel_action/test_simple/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/list/orgs = get_action_organs(user, target, TRUE, FALSE)
	if(!orgs)
		return FALSE

	return TRUE

/datum/sex_panel_action/test_simple/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "<span class='love_low'>[user] [get_pose_text(pose_state)] начинает тестовое действие с [target].</span>"

/datum/sex_panel_action/test_simple/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "<span class='love_low'>[user] [get_pose_text(pose_state)] делает тестовое действие с [target].</span>"

/datum/sex_panel_action/test_simple/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "<span class='love_low'>[user] [get_pose_text(pose_state)] заканчивает тестовое действие с [target].</span>"

/datum/sex_panel_action/test_simple/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/orgs = connect_organs(user, target)
	if(orgs == FALSE)
		return FALSE

	var/message = get_start_message(user, target)
	if(message)
		user.visible_message(message)

	return TRUE

/datum/sex_panel_action/test_simple/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SEND_SIGNAL(user,   COMSIG_SEX_RECEIVE_ACTION, 1, 0, TRUE,  0)
	SEND_SIGNAL(target, COMSIG_SEX_RECEIVE_ACTION, 1, 0, FALSE, 0)

	var/message = get_perform_message(user, target)
	if(message)
		user.visible_message(message)

	do_onomatopoeia(user)
	show_sex_effects(user)

/datum/sex_panel_action/test_simple/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message = get_finish_message(user, target)
	if(message)
		user.visible_message(message)

	return TRUE
