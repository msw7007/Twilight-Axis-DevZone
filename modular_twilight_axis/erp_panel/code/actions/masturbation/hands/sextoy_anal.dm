/datum/sex_panel_action/self/hands/toy_anal
	abstract_type = FALSE

	name = "Секс-игрушка анальная"
	required_target = SEX_ORGAN_ANUS
	armor_slot_init = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal	= 0.18
	affects_arousal			= 0
	affects_self_pain		= 0.03
	affects_pain			= 0

/datum/sex_panel_action/self/hands/toy_anal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/item_object = user.get_active_held_item()
	if(!is_sex_toy(item_object))
		return FALSE

	return TRUE

/datum/sex_panel_action/self/hands/toy_anal/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] бережно примеряет игрушку у своего анального кольца."

/datum/sex_panel_action/self/hands/toy_anal/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сношает себя игрушкой."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/self/hands/toy_anal/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] медленно прекращает движение игрушки."
