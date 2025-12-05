/datum/sex_panel_action/self/hands/penis_milking
	abstract_type = FALSE

	name = "Доение члена"
	required_target = SEX_ORGAN_PENIS
	armor_slot_init = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.22
	affects_arousal = 0
	affects_self_pain = 0.01
	affects_pain = 0

/datum/sex_panel_action/self/hands/penis_milking/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/datum/sex_session_tgui/SS = get_or_create_sex_session_tgui(user, target)
	if(SS)
		var/datum/sex_organ/O = SS.resolve_organ_datum(user, SEX_ORGAN_FILTER_PENIS)
		if(O)
			var/obj/item/container = O.find_liquid_container()
			if(container)
				return TRUE

	return FALSE

/datum/sex_panel_action/self/hands/penis_milking/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] берёт свой член в руку."

/datum/sex_panel_action/self/hands/penis_milking/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] мастурбирует рукой свой член."
	do_onomatopoeia(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/self/hands/penis_milking/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] ослабляет хватку и останавливается."

/datum/sex_panel_action/self/hands/penis_milking/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	var/datum/sex_session_tgui/SS = get_or_create_sex_session_tgui(user, target)
	if(SS)
		var/datum/sex_organ/O = SS.resolve_organ_datum(user, SEX_ORGAN_FILTER_PENIS)
		if(O)
			var/obj/item/container = find_best_container(user, target, O)
			O.inject_liquid(container, user)
			to_chat(user, "Я чувствую, как семя выплескивается наружу!")
	return "self"
