/datum/sex_panel_action/other/breasts/breast_feed
	abstract_type = FALSE
	name = "Насильное кормпление"
	required_target = SEX_ORGAN_MOUTH
	stamina_cost = 0.05
	affects_self_arousal	= 0.12
	affects_arousal			= 0.08
	affects_self_pain		= 0.01
	affects_pain			= 0.00
	require_grab = TRUE
	check_same_tile = FALSE

/datum/sex_panel_action/other/breasts/breast_feed/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/datum/sex_session_tgui/SS = get_or_create_sex_session_tgui(user, target)
	if(SS)
		var/datum/sex_organ/O = SS.resolve_organ_datum(user, SEX_ORGAN_FILTER_BREASTS)
		if(O)
			return TRUE

	return FALSE

/datum/sex_panel_action/other/breasts/breast_feed/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимает лицо [target] к своей груди."

/datum/sex_panel_action/other/breasts/breast_feed/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] насильно водит лицом [target] по своей груди."
	show_sex_effects(user)
	target.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/breasts/breast_feed/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает голову [target] от своей груди."

/datum/sex_panel_action/other/breasts/breast_feed/handle_injection_feedback(mob/living/carbon/human/user, mob/living/carbon/human/target, moved)
	to_chat(user, "Я чувствую, как мои соски выплескивают молоко.")
	to_chat(target, "Я чувствую, как грудь [user] попадает мне в рот!")

/datum/sex_panel_action/other/breasts/breast_feed/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(prob(MILKING_BREAST_PROBABILITY))
		do_liquid_injection(user, target)
