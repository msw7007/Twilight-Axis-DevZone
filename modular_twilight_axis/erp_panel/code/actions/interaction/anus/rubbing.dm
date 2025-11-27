/datum/sex_panel_action/other/anus/rubbing
	abstract_type = FALSE
	name = "Тереться попой"
	required_target = null
	stamina_cost = 0.06
	affects_self_arousal = 0.03
	affects_arousal      = 0.06
	affects_self_pain    = 0.01
	affects_pain         = 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/anus/rubbing/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прижимается ягодицами к [target]."

/datum/sex_panel_action/other/anus/rubbing/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трёться ягодицами об [get_target_zone(user)] [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/anus/rubbing/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] уводит круп от  [target]."

/datum/sex_panel_action/other/anus/rubbing/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
