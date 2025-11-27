/datum/sex_panel_action/other/mouth/finger_lick
	abstract_type = FALSE
	name = "Облизать пальцы"
	required_target = SEX_ORGAN_HANDS
	stamina_cost = 0.01
	affects_self_arousal = 0.01
	affects_arousal      = 0.02
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/mouth/finger_lick/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] помещает в рот палец [target]."

/datum/sex_panel_action/other/mouth/finger_lick/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] облизывает палец [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/mouth/finger_lick/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает из рта палец [target]."

/datum/sex_panel_action/other/mouth/finger_lick/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
