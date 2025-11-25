/datum/sex_panel_action/self/hands/tail_pet
	abstract_type = FALSE

	name = "Ласкать хвост"
	required_target = SEX_ORGAN_TAIL

	affects_self_arousal = 0.01
	affects_arousal      = 0
	affects_self_pain    = 0
	affects_pain         = 0

/datum/sex_panel_action/self/hands/tail_pet/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] проводит рукой по хвосту."

/datum/sex_panel_action/self/hands/tail_pet/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] ласкает свой хвост."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/tail_pet/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отпускает хвост."

/datum/sex_panel_action/self/hands/tail_pet/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	
	do_onomatopoeia(user)
	show_sex_effects(user)
