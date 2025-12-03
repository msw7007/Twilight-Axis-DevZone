/datum/sex_panel_action/other/hands/toy_anal
	abstract_type = FALSE

	name = "Секс-игрушка анальная"
	required_target = SEX_ORGAN_ANUS
	armor_slot_init = BODY_ZONE_PRECISE_GROIN
	check_same_tile = FALSE

	affects_self_arousal = 0.18
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/hands/toy_anal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/I = user.get_active_held_item()
	if(!is_sex_toy(I))
		return FALSE

	return TRUE

/datum/sex_panel_action/other/hands/toy_anal/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] бережно примеряет игрушку у анального кольца [target]."

/datum/sex_panel_action/other/hands/toy_anal/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сношает [target] игрушкой."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/toy_anal/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] медленно прекращает движение игрушки в попке [target]."
