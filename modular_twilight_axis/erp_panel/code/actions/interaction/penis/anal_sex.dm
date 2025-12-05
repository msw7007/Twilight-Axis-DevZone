/datum/sex_panel_action/other/penis/anal_sex
	abstract_type = FALSE

	name = "Анальный секс"
	required_target = SEX_ORGAN_ANUS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.08
	affects_arousal      = 0.12
	affects_self_pain    = 0.03
	affects_pain         = 0.03

/datum/sex_panel_action/other/penis/anal_sex/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член к анальному кольцу [target]."

/datum/sex_panel_action/other/penis/anal_sex/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трахает [target] в задницу[get_knot_action(user, target)]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	do_sound_effect(user)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/anal_sex/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает член из попки [target]."

/datum/sex_panel_action/other/penis/anal_sex/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает в попку [target]" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "into"

/datum/sex_panel_action/other/penis/anal_sex/get_knot_count()
	return 1
