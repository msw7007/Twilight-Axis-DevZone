/datum/sex_panel_action/other/hands/milking_breasts
	abstract_type = FALSE
	name = "Доить грудь"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_target = BODY_ZONE_CHEST
	stamina_cost = 0.05
	affects_self_arousal = 0
	affects_arousal      = 0.06
	affects_self_pain    = 0
	affects_pain         = 0.02

/datum/sex_panel_action/other/hands/milking_breasts/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/datum/sex_session_tgui/session_object = get_or_create_sex_session_tgui(user, target)
	if(!session_object)
		return FALSE

	var/datum/sex_organ/organ_object = session_object.resolve_organ_datum(target, SEX_ORGAN_FILTER_BREASTS)
	if(!organ_object)
		return FALSE

	var/obj/item/container = find_best_container(user, target, organ_object)
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
	return "[user] убирает руки от груди [target]."

/datum/sex_panel_action/other/hands/milking_breasts/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(prob(MILKING_BREAST_PROBABILITY))
		var/list/orgs = get_action_organs(user, target, FALSE, FALSE)
		if(orgs)
			var/datum/sex_organ/boobs = orgs["target"]
			if(boobs)
				var/obj/item/container = find_best_container(user, target, boobs)
				var/moved = boobs.inject_liquid(container, user)
				if(moved > 0)
					handle_injection_feedback(user, target, moved)

/datum/sex_panel_action/other/hands/milking_breasts/handle_injection_feedback(mob/living/carbon/human/user, mob/living/carbon/human/target, moved)
	to_chat(user, "Я чувствую, как соски [target] выплескивают молоко.")
	to_chat(target, "Я чувствую, как молоко покидает мою грудь.")
