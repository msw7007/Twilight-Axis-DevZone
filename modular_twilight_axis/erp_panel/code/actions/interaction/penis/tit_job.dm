/datum/sex_panel_action/other/penis/tit_job
	abstract_type = FALSE

	name = "Использовать грудь"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_target = BODY_ZONE_CHEST
	can_knot = FALSE
	
	affects_self_arousal	= 0.03
	affects_arousal			= 0.12
	affects_self_pain		= 0.01
	affects_pain			= 0.03

/datum/sex_panel_action/other/penis/tit_job/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член между грудей [target]."

/datum/sex_panel_action/other/penis/tit_job/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит членом между грудей [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/tit_job/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает член от груди [target]."

/datum/sex_panel_action/other/penis/tit_job/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает на грудь [target]" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "onto"
