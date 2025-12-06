/datum/sex_panel_action/other/tail/penis
	abstract_type = FALSE
	name = "Мастурбация хвостом"
	required_target = SEX_ORGAN_PENIS
	stamina_cost = 0.06
	affects_self_arousal	= 0.06
	affects_arousal			= 0.12
	affects_self_pain		= 0
	affects_pain			= 0.03

/datum/sex_panel_action/other/tail/penis/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] обвивает хвостом член [target]."

/datum/sex_panel_action/other/tail/penis/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит хвостом по члену [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	do_sound_effect(target)
	return spanify_force(message)

/datum/sex_panel_action/other/tail/penis/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отводит хвост от члена [target]."

/datum/sex_panel_action/other/tail/penis/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает на хвост [user]!"
	user.visible_message(span_love(message))
	return "onto"
