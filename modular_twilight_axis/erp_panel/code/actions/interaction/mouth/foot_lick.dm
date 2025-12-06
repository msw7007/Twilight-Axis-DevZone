/datum/sex_panel_action/other/mouth/foot_lick
	abstract_type = FALSE
	name = "Облизать ножки"
	required_target = SEX_ORGAN_LEGS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.01
	affects_self_arousal	= 0.04
	affects_arousal			= 0.12
	affects_self_pain		= 0.01
	affects_pain			= 0.03
	check_same_tile = FALSE

/datum/sex_panel_action/other/mouth/foot_lick/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] припадает губами к ногам [target]."

/datum/sex_panel_action/other/mouth/foot_lick/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] лижет ножки [target]."
	show_sex_effects(user)
	user.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/mouth/foot_lick/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает лицо с ножек [target]."

/datum/sex_panel_action/other/mouth/foot_lick/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя"
	user.visible_message(span_love(message))
	return "self"
