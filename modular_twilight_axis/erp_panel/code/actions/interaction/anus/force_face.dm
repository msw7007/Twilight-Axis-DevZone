/datum/sex_panel_action/other/anus/force_face
	abstract_type = FALSE
	name = "Сесть на лицо"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.1
	affects_self_arousal = 0.15
	affects_arousal      = 0.04
	affects_self_pain    = 0.01
	affects_pain         = 0.04

/datum/sex_panel_action/other/anus/force_face/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимается голову [target] к своей заднице."

/datum/sex_panel_action/other/anus/force_face/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] [is_agressive_tier() ? "впечатывает лицо [target] в свою задницу" : "водит лицом [target] по своей заднице"]."
	show_sex_effects(user)
	do_thrust_animate(user, target)
	target.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/anus/force_face/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отводит попку от лица [target]."
