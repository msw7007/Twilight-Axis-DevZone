/datum/sex_panel_action/other/vagina/face
	abstract_type = FALSE
	name = "Присесть вагиной"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH
	stamina_cost = 0.06
	affects_self_arousal	= 0.08
	affects_arousal			= 0.12
	affects_self_pain		= 0.01
	affects_pain			= 0.01

	actor_sex_hearts = TRUE
	actor_do_thrust = TRUE
	target_suck_sound = TRUE

	message_on_start   = "{actor} {pose}, {force} и {speed} прижимается вагиной к лицу {dullahan?отделенной головы :}{partner}, раздвигая ноги."
	message_on_perform = "{actor} {pose}, {force} и {speed} {aggr?задницей:ягодицами} {dullahan?отделенной головы :}{partner}."
	message_on_finish  = "{actor}  убирает лоно с лица {dullahan?отделенной головы :}{partner}."
	message_on_climax_actor  = "{actor} кончает на лицо {dullahan?отделенной головы :}{partner}."
	message_on_climax_target = "{partner} кончает под себя."

/datum/sex_panel_action/other/mouth/rimming/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	return "onto"
