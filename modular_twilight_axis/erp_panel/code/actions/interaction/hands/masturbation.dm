/datum/sex_panel_action/other/hands/masturbation
	abstract_type = FALSE
	name = "Мастурбировать"
	required_target = SEX_ORGAN_PENIS
	stamina_cost = 0.05
	affects_self_arousal = 0.06
	affects_arousal      = 0.04
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/hands/masturbation/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается руками члена и обхватывает его [target]."

/datum/sex_panel_action/other/hands/masturbation/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] дрочит член [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/masturbation/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от члена [target]."
