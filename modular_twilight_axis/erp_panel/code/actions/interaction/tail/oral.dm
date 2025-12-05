/datum/sex_panel_action/other/tail/oral
	abstract_type = FALSE
	name = "Трахнуть рот хвостом"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.06
	affects_self_arousal = 0.03
	affects_arousal      = 0.12
	affects_self_pain    = 0
	affects_pain         = 0.01

/datum/sex_panel_action/other/tail/oral/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] проникает хвостом в рот [target]."

/datum/sex_panel_action/other/tail/oral/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сношает хвостом рот [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	target.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/tail/oral/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] выводит хвост из рта [target]."
