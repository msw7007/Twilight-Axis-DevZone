/datum/sex_panel_action/other/penis/butt_job
	abstract_type = FALSE

	name = "Использовать ягодицы"
	required_target = SEX_ORGAN_ANUS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	can_knot = FALSE
	
	affects_self_arousal	= 0.03
	affects_arousal			= 0.12
	affects_self_pain		= 0.01
	affects_pain			= 0.03

/datum/sex_panel_action/other/penis/butt_job/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член между ягодиц [target]."

/datum/sex_panel_action/other/penis/butt_job/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит членом между ягодиц [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_sound_effect(user)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/butt_job/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает член от попки [target]."

/datum/sex_panel_action/other/penis/butt_job/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает на ягодицы [target]" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "onto"
