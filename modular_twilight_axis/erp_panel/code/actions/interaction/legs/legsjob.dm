/datum/sex_panel_action/other/legs/legsjob
	abstract_type = FALSE
	name = "Работа бедрами"
	required_target = SEX_ORGAN_PENIS
	stamina_cost = 0.06
	affects_self_arousal = 0.03
	affects_arousal      = 0.15
	affects_self_pain    = 0
	affects_pain         = 0.02
	require_grab = TRUE

/datum/sex_panel_action/other/legs/legsjob/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] зажимает член [target] ступнями."

/datum/sex_panel_action/other/legs/legsjob/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит ножками по члену [target]."
	show_sex_effects(user)
	do_thrust_animate(user, target)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/legs/legsjob/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает ножки от члена [target]."
