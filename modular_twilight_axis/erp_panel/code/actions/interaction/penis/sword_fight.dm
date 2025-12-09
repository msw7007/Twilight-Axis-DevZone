
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

	actor_sex_hearts = TRUE
	actor_make_sound = TRUE
	actor_make_fingering_sound = TRUE

	message_on_start   = "{actor} {pose} приставляет свой член к члену {partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} трётся членом об член {partner}."
	message_on_finish  = "{actor} убирает член от члена {partner}."
	message_on_climax_actor  = "{actor} кончает на {partner}."
	message_on_climax_target = "{partner} кончает на {actor}."

/datum/sex_panel_action/other/penis/sword_fight/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()][target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/sword_fight/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	return "onto"
