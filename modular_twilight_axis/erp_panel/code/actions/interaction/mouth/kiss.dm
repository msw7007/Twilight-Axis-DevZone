/datum/sex_panel_action/other/mouth/kiss
	abstract_type = FALSE
	name = "Поцеловать"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.01
	affects_self_arousal = 0.03
	affects_arousal = 0.03
	affects_self_pain = 0.01
	affects_pain = 0.01
	check_same_tile = FALSE

	actor_sex_hearts = TRUE
	actor_suck_sound = TRUE
	target_suck_sound = TRUE
	can_be_custom = FALSE

	message_on_start   = "{actor} {pose} сплетается в поцелуе с {dullahan?отделенной головой :}{partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} целуется с {dullahan?отделенной головой :}{partner}."
	message_on_finish  = "{actor} разрывает поцелуй с {partner}."
	message_on_climax_actor  = "{actor} кончает под себя."
	message_on_climax_target = "{partner} кончает под себя."

/datum/sex_panel_action/other/mouth/kiss/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя"
	user.visible_message(span_love(message))
	return "self"
