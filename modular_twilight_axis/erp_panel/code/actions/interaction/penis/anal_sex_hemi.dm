/datum/sex_panel_action/other/penis/hemi/anal_double
	abstract_type = FALSE

	name = "Геми-анальный секс"
	required_target = SEX_ORGAN_ANUS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.18
	affects_arousal      = 0.06
	affects_self_pain    = 0.04
	affects_pain         = 0.01

/datum/sex_panel_action/other/penis/hemi/anal_double/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимает оба ствола к анусу [target]."

/datum/sex_panel_action/other/penis/hemi/anal_double/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сношает в попку [target] двумя стволами[get_knot_action()]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	do_sound_effect(user)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/hemi/anal_double/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает члены из влагалища [target]."

/datum/sex_panel_action/other/penis/hemi/anal_double/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает в попку [target]" : "[target] кончает сжимая анус вокруг членов [user]"
	user.visible_message(span_love(message))
	return "into"

/datum/sex_panel_action/other/penis/hemi/anal_double/get_knot_count()
	return 1
