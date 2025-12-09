/datum/sex_panel_action/other/tail/vaginal
	abstract_type = FALSE
	name = "Трахнуть вагину хвостом"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.06
	affects_self_arousal	= 0.08
	affects_arousal			= 0.12
	affects_self_pain		= 0
	affects_pain			= 0.01

	actor_sex_hearts = TRUE
	actor_make_sound = TRUE
	actor_do_thrust = TRUE

	message_on_start   = "{actor} {pose} вводит хвостом в вагину {partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} {aggr?сношает хвостом киску:играется хвостом в киске} {dullahan?отделенной головы :}{partner}."
	message_on_finish  = "{actor} выводит хвост из вагины {partner}."
	message_on_climax_actor  = "{actor} кончает под себя."
	message_on_climax_target = "{partner} кончает, сжимая киской хвост {actor}."


/datum/sex_panel_action/other/tail/penis/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	return "onto"
