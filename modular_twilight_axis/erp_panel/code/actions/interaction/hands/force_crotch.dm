/datum/sex_panel_action/other/hands/force_crotch
	abstract_type = FALSE
	name = "Прижать к подмышкам"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_HEAD
	stamina_cost = 0.05
	affects_self_arousal = 0.1
	affects_arousal      = 0
	affects_self_pain    = 0.02
	affects_pain         = 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/hands/force_crotch/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает голову[target], прижимая к своей промежности."

/datum/sex_panel_action/other/hands/force_crotch/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит лицом [target] по своей промежности."
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/force_crotch/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отпускает голову [target]."
