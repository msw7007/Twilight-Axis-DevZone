/datum/sex_panel_action/other/hands/tease_vagina
	abstract_type = FALSE
	name = "Ласкать клитор"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.05
	affects_self_arousal = 0.06
	affects_arousal      = 0.04
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/hands/tease_vagina/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается руками киски [target]."

/datum/sex_panel_action/other/hands/tease_vagina/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит руками по клитору [target]."
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/tease_vagina/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от лона [target]."
