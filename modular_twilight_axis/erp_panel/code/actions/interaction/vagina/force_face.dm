/datum/sex_panel_action/other/vagina/force_face
	abstract_type = FALSE
	name = "Заставить отлизать"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.06
	affects_self_arousal = 0.15
	affects_arousal      = 0.02
	affects_self_pain    = 0.02
	affects_pain         = 0.01

/datum/sex_panel_action/other/vagina/force_face/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает голову [target], прижимая к своей промежности."

/datum/sex_panel_action/other/vagina/force_face/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] впечатывает лицу [target] в свою промежность."
	show_sex_effects(user)
	do_thrust_animate(user, target)
	target.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/vagina/force_face/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от головы [target]."

/datum/sex_panel_action/other/mouth/rimming/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает на лицо [target]" : "[target] кончает под себя"
	user.visible_message(span_love(message))
	return "onto"
