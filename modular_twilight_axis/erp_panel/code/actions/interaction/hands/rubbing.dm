/datum/sex_panel_action/other/hands/rubbing
	abstract_type = FALSE
	name = "Лапать тело"
	required_target = null
	stamina_cost = 0.05
	affects_self_arousal = 0.09
	affects_arousal      = 0.18
	affects_self_pain    = 0
	affects_pain         = 0.03
	break_on_move = FALSE

/datum/sex_panel_action/other/hands/rubbing/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается руками [target]."

/datum/sex_panel_action/other/hands/rubbing/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] лапает [target]."
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/rubbing/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от [target]."

