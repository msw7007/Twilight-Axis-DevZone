/datum/sex_panel_action/self/hands/breasts_play
	abstract_type = FALSE

	name = "Лапать грудь"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_init = BODY_ZONE_CHEST

	affects_self_arousal = 0.1
	affects_arousal      = 0
	affects_self_pain    = 0.01
	affects_pain         = 0

/datum/sex_panel_action/self/hands/breasts_play/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] располагает руки на своей груди."

/datum/sex_panel_action/self/hands/breasts_play/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] лапает свою грудь."
	show_sex_effects(user)
	return spanify_force(message)

/datum/sex_panel_action/self/hands/breasts_play/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки со своей груди."
