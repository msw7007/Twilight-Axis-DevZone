/datum/sex_panel_action/other/legs/footjob/teasing
	abstract_type = FALSE
	name = "Тереться ногой"
	required_target = null
	stamina_cost = 0.05
	affects_self_arousal = 0.12
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/legs/footjob/teasing/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] укладывает свою ногу на [target]."

/datum/sex_panel_action/other/legs/footjob/teasing/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трется ногой об [get_target_zone(user)] [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/legs/footjob/teasing/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает ногу от [target]."

/datum/sex_panel_action/other/legs/footjob/teasing/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
