/datum/sex_panel_action/other/legs/footfetish
	abstract_type = FALSE
	name = "Дать вылизать ножки"
	required_target = SEX_ORGAN_MOUTH
	stamina_cost = 0.05
	affects_self_arousal = 0.06
	affects_arousal      = 0.04
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/legs/footfetish/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] пихает ноги в рот [target]."

/datum/sex_panel_action/other/legs/footfetish/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит пальцами ног во рту [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/legs/footfetish/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает ножки от лица [target]."

/datum/sex_panel_action/other/legs/footfetish/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
