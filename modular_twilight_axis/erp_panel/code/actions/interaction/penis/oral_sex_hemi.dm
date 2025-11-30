/datum/sex_panel_action/other/penis/hemi/oral_double
	abstract_type = FALSE

	name = "Геми-оральный секс"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH

	affects_self_arousal = 0.18  // чуть сильнее
	affects_arousal      = 0.06
	affects_self_pain    = 0.04
	affects_pain         = 0.01

/datum/sex_panel_action/other/penis/hemi/oral_double/get_start_message(user, target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимает оба ствола ко рту [target]."

/datum/sex_panel_action/other/penis/hemi/oral_double/get_perform_message(user, target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сношает в рот [target] двумя стволами[get_knot_action()]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/hemi/oral_double/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает члены из влагалища [target]."

/datum/sex_panel_action/other/penis/hemi/oral_double/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "в лоно [target]"
	var/message = span_love(result.Join("\n"))
	user.visible_message(message)
	return "into"
