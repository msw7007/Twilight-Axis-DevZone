/datum/sex_panel_action/other/mouth/kiss
	abstract_type = FALSE
	name = "Поцеловать"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.01
	affects_self_arousal = 0.03
	affects_arousal      = 0.03
	affects_self_pain    = 0.01
	affects_pain         = 0.01
	check_same_tile = FALSE

/datum/sex_panel_action/other/mouth/kiss/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] сплетается в поцелуе с [target]."

/datum/sex_panel_action/other/mouth/kiss/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] целуется с [target]."
	show_sex_effects(user)
	user.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/mouth/kiss/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] разрывает поцелуй с [target]."

/datum/sex_panel_action/other/mouth/kiss/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя"
	user.visible_message(span_love(message))
	return "self"
