/datum/sex_panel_action/other/hands/milking_breasts
	abstract_type = FALSE
	name = "Доить грудь"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_target = BODY_ZONE_CHEST
	stamina_cost = 0.05
	affects_self_arousal = 0.06
	affects_arousal      = 0.04
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/hands/milking_breasts/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
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

/datum/sex_panel_action/other/hands/milking_breasts/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] кладет руки на грудь [target]."

/datum/sex_panel_action/other/hands/milking_breasts/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит руками по сиськам [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/milking_breasts/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от доек [target]."

/datum/sex_panel_action/other/hands/milking_breasts/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(prob(MILKING_BREAST_PROBABILITY))
		do_liquid_injection(user, target)

/datum/sex_panel_action/other/hands/milking_breasts/handle_injection_feedback(mob/living/carbon/human/user, mob/living/carbon/human/target, moved)
	target.visible_message("Я чувствую, как молоко покидает мою грудь.")
	user.visible_message("Я чувствую, как соски [target] выплескивают молоко.")
