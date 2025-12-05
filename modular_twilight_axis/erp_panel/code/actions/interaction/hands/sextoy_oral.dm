/datum/sex_panel_action/other/hands/toy_oral
	abstract_type = FALSE

	name = "Секс-игрушка оральная"
	required_target = SEX_ORGAN_MOUTH
	check_same_tile = FALSE

	affects_self_arousal = 0
	affects_arousal      = 0.12
	affects_self_pain    = 0
	affects_pain         = 0.01

/datum/sex_panel_action/other/hands/toy_oral/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/item_object = user.get_active_held_item()
	if(!is_sex_toy(item_object))
		return FALSE

	return TRUE

/datum/sex_panel_action/other/hands/toy_oral/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] подносит игрушку к губам [target]."

/datum/sex_panel_action/other/hands/toy_oral/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит игрушкой во рту [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	target.make_sucking_noise()
	return spanify_force(message)

/datum/sex_panel_action/other/hands/toy_oral/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает игрушку от [target]."
