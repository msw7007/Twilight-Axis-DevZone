/datum/sex_panel_action/self/hands/toy_a
	abstract_type = FALSE

	name = "Секс-игрушка анальная"
	required_target = SEX_ORGAN_ANUS
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.18
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/self/hands/toy_a/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/I = user.get_active_held_item()
	if(!is_sex_toy(I))
		return FALSE

	return TRUE

/datum/sex_panel_action/self/hands/toy_a/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] бережно примеряет игрушку у своего анального кольца."

/datum/sex_panel_action/self/hands/toy_a/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сношает себя игрушкой."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/toy_a/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] медленно прекращает движение игрушки."

/datum/sex_panel_action/self/hands/toy_a/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
