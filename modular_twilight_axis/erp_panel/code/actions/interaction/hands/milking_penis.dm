/datum/sex_panel_action/other/hands/milking_penis
	abstract_type = FALSE
	name = "Доить член"
	required_target = SEX_ORGAN_PENIS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.05
	affects_self_arousal = 0.06
	affects_arousal      = 0.04
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/hands/milking_penis/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] кладет руки на член [target]."

/datum/sex_panel_action/other/hands/milking_penis/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит руками по члену [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/milking_penis/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от члена [target]."

/datum/sex_panel_action/other/hands/milking_penis/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	var/datum/sex_session_tgui/SS = get_or_create_sex_session_tgui(user, target)
	if(SS)
		var/datum/sex_organ/O = SS.resolve_organ_datum(user, SEX_ORGAN_FILTER_PENIS)
		if(O)
			O.inject_liquid()
			to_chat(user, "Я чувствую, как семя [target] выплескивается наружу!")
			to_chat(target, "Я чувствую, как семя выплескивается наружу!")

	return "onto"
