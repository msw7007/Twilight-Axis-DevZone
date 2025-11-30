/datum/sex_panel_action/other/penis/vaginal_sex
	abstract_type = FALSE

	name = "Вагинальный секс"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_init = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/penis/vaginal_sex/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член к лону [target]."

/datum/sex_panel_action/other/penis/vaginal_sex/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трахает [target] в киску [get_knot_action(user, target)]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/vaginal_sex/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает член из влагалища [target]."

/datum/sex_panel_action/other/penis/vaginal_sex/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "в лоно [target]"
	var/message = span_love(result.Join("\n"))
	user.visible_message(message)
	return "into"
