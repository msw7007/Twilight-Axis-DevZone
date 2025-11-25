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
	return "[user] [get_pose_text(pose_state)] располагает руки на своей груди."

/datum/sex_panel_action/self/hands/breasts/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] лапает свою грудь."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/breasts/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки со своей груди."

/datum/sex_panel_action/self/hands/breasts/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
