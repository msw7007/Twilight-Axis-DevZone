/datum/sex_panel_action/self/hands/milking_breasts
	abstract_type = FALSE

	name = "Доение груди"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_init = BODY_ZONE_CHEST

	affects_self_arousal = 0.2
	affects_arousal      = 0
	affects_self_pain    = 0.01
	affects_pain         = 0

/datum/sex_panel_action/self/hands/milking_breasts/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/datum/sex_session_tgui/SS = get_or_create_sex_session_tgui(user, target)
	if(SS)
		var/datum/sex_organ/O = SS.resolve_organ_datum(user, SEX_ORGAN_FILTER_BREASTS)
		if(O)
			var/obj/item/container = O.find_liquid_container()
			if(container)
				return TRUE

	return FALSE

/datum/sex_panel_action/self/hands/milking_breasts/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает свою грудь и начинает вести к соскам."

/datum/sex_panel_action/self/hands/milking_breasts/get_perform_message(mob/living/carbon/human/user,mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] выжимает свою грудь."
	do_onomatopoeia(user)
	return spanify_force(message)

/datum/sex_panel_action/self/hands/milking_breasts/get_finish_message(mob/living/carbon/human/user,mob/living/carbon/human/target)
	return "[user] прекращает касаться груди."

/datum/sex_panel_action/self/hands/milking_breasts/handle_injection_feedback(mob/living/carbon/human/user, mob/living/carbon/human/target, moved)
	user.visible_message("[user] чувствует, как молоко стекает из груди.")

/datum/sex_panel_action/self/hands/milking_breasts/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(prob(MILKING_BREAST_PROBABILITY))
		do_liquid_injection(user, target)
