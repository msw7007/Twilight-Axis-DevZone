/datum/sex_panel_action/other/hands/finger_vaginal
	abstract_type = FALSE
	name = "Фингеринг вагины"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.05
	affects_self_arousal = 0.0
	affects_arousal      = 0.08
	affects_self_pain    = 0.01
	affects_pain         = 0.03

/datum/sex_panel_action/other/hands/finger_vaginal/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается пальцем лона [target]."

/datum/sex_panel_action/other/hands/finger_vaginal/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] проникает пальчиком в киску [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/finger_vaginal/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает палец от промежности [target]."
