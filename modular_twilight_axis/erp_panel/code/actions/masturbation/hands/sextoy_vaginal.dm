/datum/sex_panel_action/self/hands/toy_v
	abstract_type = FALSE

	name = "Секс-игрушка вагинальная"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.2
	affects_arousal      = 0
	affects_self_pain    = 0.02
	affects_pain         = 0

/datum/sex_panel_action/self/hands/toy_v/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/I = user.get_active_held_item()
	if(!is_sex_toy(I))
		return FALSE

	return TRUE

/datum/sex_panel_action/self/hands/toy_v/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] берет игрушку в руку и подносит к своему лону."

/datum/sex_panel_action/self/hands/toy_v/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит игрушкой внутри себя."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/toy_v/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отстраняет игрушку."

/datum/sex_panel_action/self/hands/toy_v/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
