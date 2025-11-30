/datum/sex_panel_action/other/penis/oral_sex
	abstract_type = FALSE

	name = "Оральный секс"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/penis/oral_sex/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член к лицу [target]."

/datum/sex_panel_action/other/penis/oral_sex/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трахает [target] в рот [get_knot_action(user, target)]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/oral_sex/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает член из рта [target]."


/datum/sex_panel_action/other/penis/oral_sex/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "в рот [target]"
	var/message = span_love(result.Join("\n"))
	user.visible_message(message)
	return "into"
