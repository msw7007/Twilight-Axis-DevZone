/datum/sex_panel_action/other/penis/sword_fight
	abstract_type = FALSE

	name = "Фехтование"
	required_target = SEX_ORGAN_PENIS
	armor_slot_target = null
	can_knot = FALSE
	check_same_tile = FALSE

	affects_self_arousal	= 0.12
	affects_arousal			= 0.04
	affects_self_pain		= 0.01
	affects_pain			= 0.03

/datum/sex_panel_action/other/penis/sword_fight/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свой член к члену [target]."

/datum/sex_panel_action/other/penis/sword_fight/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трётся членом об член [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/sword_fight/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает член от члена [target]."

/datum/sex_panel_action/other/penis/sword_fight/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает на [target]" : "[target] кончает на [user]"
	user.visible_message(span_love(message))
	return "onto"
