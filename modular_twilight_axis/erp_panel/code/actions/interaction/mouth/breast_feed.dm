/datum/sex_panel_action/other/mouth/breast_feed
	abstract_type = FALSE
	name = "Облизать грудь"
	required_target = SEX_ORGAN_BREASTS
	stamina_cost = 0.02
	affects_self_arousal = 0.12
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/mouth/breast_feed/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается губами груди [target] и облизывает их языком."

/datum/sex_panel_action/other/mouth/breast_feed/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] облизывает соски [target]."
	do_onomatopoeia(user)
	return spanify_force(message)

/datum/sex_panel_action/other/mouth/breast_feed/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает губы от груди [target]."

/datum/sex_panel_action/other/mouth/breast_feed/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(prob(MILKING_BREAST_PROBABILITY))
		do_liquid_injection(user, target)

/datum/sex_panel_action/other/mouth/breast_feed/handle_injection_feedback(mob/living/carbon/human/user, mob/living/carbon/human/target, moved)
	user.visible_message("[user] чувствует, как молоко стекает из груди.")
	target.visible_message("[target] ощущает вкус теплого молока во рту.")
