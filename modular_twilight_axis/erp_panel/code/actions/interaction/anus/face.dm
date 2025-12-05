/datum/sex_panel_action/other/anus/face
	abstract_type = FALSE
	name = "Сесть на лицо"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.1
	affects_self_arousal = 0.09
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.03

/datum/sex_panel_action/other/anus/face/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимается анусом к лицу [target], раздвигая ягодицы."

/datum/sex_panel_action/other/anus/face/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] елозит [is_agressive_tier() ? "задницей" : "ягодицами"] по лицу [target]."
	show_sex_effects(user)
	do_thrust_animate(user, target)
	target.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/anus/face/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] соскальзывает попкой с лица [target]."
