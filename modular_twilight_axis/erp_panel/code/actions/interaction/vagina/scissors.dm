/datum/sex_panel_action/other/vagina/scissors
	abstract_type = FALSE
	name = "Ножницы"
	required_target = SEX_ORGAN_VAGINA
	stamina_cost = 0.06
	affects_self_arousal = 0.08
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/vagina/scissors/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимается вагиной к киске [target]."

/datum/sex_panel_action/other/vagina/scissors/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трётся своей вагиной об вагину [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/vagina/scissors/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] расцепляет вагины с [target]."

/datum/sex_panel_action/other/vagina/scissors/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
