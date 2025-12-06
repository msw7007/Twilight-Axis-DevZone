/datum/sex_panel_action/other/mouth/finger_lick
	abstract_type = FALSE
	name = "Облизать пальцы"
	required_target = SEX_ORGAN_HANDS
	stamina_cost = 0.01
	affects_self_arousal	= 0.01
	affects_arousal			= 0.01
	affects_self_pain		= 0.01
	affects_pain			= 0.01
	check_same_tile = FALSE

/datum/sex_panel_action/other/mouth/finger_lick/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] помещает в рот палец [target]."

/datum/sex_panel_action/other/mouth/finger_lick/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] облизывает палец [target]."
	show_sex_effects(user)
	user.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/mouth/finger_lick/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает из рта палец [target]."

/datum/sex_panel_action/other/mouth/finger_lick/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя"
	user.visible_message(span_love(message))
	return "self"
