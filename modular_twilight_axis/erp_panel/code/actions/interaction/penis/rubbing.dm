/datum/sex_panel_action/other/penis/rubbing
	abstract_type = FALSE

	name = "Тереться членом"
	required_target = SEX_ORGAN_ANUS
	armor_slot_init = BODY_ZONE_PRECISE_GROIN
	can_knot = FALSE
	check_same_tile = FALSE

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/penis/rubbing/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член к коже [target]."

/datum/sex_panel_action/other/penis/rubbing/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трётся об [get_target_zone(user)] [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/rubbing/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает член от кожи [target]."

/datum/sex_panel_action/other/penis/rubbing/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "на [target]"
	var/message = span_love(result.Join("\n"))
	user.visible_message(message)
	return "onto"
