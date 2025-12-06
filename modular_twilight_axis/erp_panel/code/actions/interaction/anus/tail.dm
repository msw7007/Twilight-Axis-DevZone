/datum/sex_panel_action/other/anus/tail
	abstract_type = FALSE
	name = "Использовать хвост попкой"
	required_target = SEX_ORGAN_TAIL
	stamina_cost = 0.06
	affects_self_arousal	= 0.04
	affects_arousal			= 0.12
	affects_self_pain		= 0.01
	affects_pain			= 0.01

/datum/sex_panel_action/other/anus/tail/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает хвост [target] и направляет к своей попке."

/datum/sex_panel_action/other/anus/tail/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] удерживая хвост [target] в своем анусе скачет на нём."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/anus/tail/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскитвает хвост [target] из своей задницы."

/datum/sex_panel_action/other/anus/rubbing/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает, сжимая попкой хвост [target]" : "[target] кончает под себя"
	user.visible_message(span_love(message))
	return "self"
