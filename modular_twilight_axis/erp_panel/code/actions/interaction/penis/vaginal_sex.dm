/datum/sex_panel_action/other/penis/vaginal_sex
	abstract_type = FALSE

	name = "Вагинальный секс"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_target = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.12
	affects_arousal      = 0.12
	affects_self_pain    = 0.02
	affects_pain         = 0.02

/datum/sex_panel_action/other/penis/vaginal_sex/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член к лону [target]."

/datum/sex_panel_action/other/penis/vaginal_sex/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трахает [target] в киску[get_knot_action(user, target)]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	do_sound_effect(user)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/vaginal_sex/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает член из влагалища [target]."

/datum/sex_panel_action/other/penis/vaginal_sex/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает в лоно [target]" : "[target] кончает сжимая киску вокруг члена [user]!"
	user.visible_message(span_love(message))
	return "into"

/datum/sex_panel_action/other/penis/anal_sex/get_knot_count()
	return 1
