/datum/sex_panel_action/other/body/grinding
	abstract_type = FALSE
	name = "Уткнуться лицом"
	required_target = null
	stamina_cost = 0.06
	affects_self_arousal = 0.09
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/body/grinding/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимается лицом к [target]."

/datum/sex_panel_action/other/body/grinding/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трется лицом об [get_target_zone(user)] [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/body/grinding/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отстраняется лицом от [target]."

/datum/sex_panel_action/other/body/grinding/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
