/datum/sex_panel_action/other/penis/masturbation
	abstract_type = FALSE

	name = "Мастурбировать на партнера"
	required_target = null
	can_knot = FALSE
	check_same_tile = FALSE

	affects_self_arousal	= 0.12
	affects_arousal			= 0
	affects_self_pain		= 0.03
	affects_pain			= 0

/datum/sex_panel_action/other/penis/masturbation/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает свой член, смотря на [target]."

/datum/sex_panel_action/other/penis/masturbation/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит рукой по своему члена, направляя его на [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/masturbation/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от своего члена."


/datum/sex_panel_action/other/penis/masturbation/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает на [target]" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "onto"

