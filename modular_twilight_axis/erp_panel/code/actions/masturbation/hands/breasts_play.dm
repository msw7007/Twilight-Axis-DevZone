/datum/sex_panel_action/self/hands/breasts
	abstract_type = FALSE

	name = "Лапать грудь"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_lock = BODY_ZONE_PRECISE_STOMACH

	affects_self_arousal = 0.1
	affects_arousal      = 0
	affects_self_pain    = 0.01
	affects_pain         = 0

/datum/sex_panel_action/self/hands/breasts/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] располагает руки на своей груди."

/datum/sex_panel_action/self/hands/breasts/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] лапает свою грудь."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/breasts/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] убирает руки со своей груди."

/datum/sex_panel_action/self/hands/breasts/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	var/list/orgs = connect_organs(user, target)
	if(orgs == FALSE)
		return FALSE

	var/message = get_start_message(user, target)
	if(message)
		user.visible_message(span_warning(message))

	return TRUE

/datum/sex_panel_action/self/hands/breasts/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	SEND_SIGNAL(user, COMSIG_SEX_RECEIVE_ACTION, 1, 0, TRUE,  0)
	SEND_SIGNAL(target, COMSIG_SEX_RECEIVE_ACTION, 1, 0, FALSE, 0)

	do_onomatopoeia(user)
	show_sex_effects(user)

/datum/sex_panel_action/self/hands/breasts/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	var/message = get_finish_message(user, target)
	if(message)
		user.visible_message(span_warning(message))

	return TRUE
