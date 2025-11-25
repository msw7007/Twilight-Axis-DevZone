/datum/sex_panel_action/self/hands/toy_o
	abstract_type = FALSE

	name = "Секс-игрушка оральная"
	required_target = SEX_ORGAN_MOUTH

	affects_self_arousal = 0.15
	affects_arousal      = 0
	affects_self_pain    = 0
	affects_pain         = 0

/datum/sex_panel_action/self/hands/toy_o/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/I = user.get_active_held_item()
	if(!is_sex_toy(I))
		return FALSE

	return TRUE

/datum/sex_panel_action/self/hands/toy_o/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] подносит игрушку ближе к лицу."

/datum/sex_panel_action/self/hands/toy_o/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] играет с игрушкой во рту."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/toy_o/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает игрушку."

/datum/sex_panel_action/self/hands/toy_o/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
