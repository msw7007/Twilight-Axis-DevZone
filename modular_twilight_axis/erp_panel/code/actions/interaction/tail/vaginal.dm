/datum/sex_panel_action/other/tail/vaginal
	abstract_type = FALSE
	name = "Трахнуть вагину хвостом"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.06
	affects_self_arousal = 0.08
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/tail/vaginal/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] вводит хвостом в вагину [target]."

/datum/sex_panel_action/other/tail/vaginal/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] играется хвостом в киске [target]."
	show_sex_effects(user)
	do_thrust_animate(user, target)
	return spanify_force(message)

/datum/sex_panel_action/other/tail/vaginal/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] выводит хвост из вагины [target]."
