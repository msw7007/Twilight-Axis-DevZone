/datum/sex_panel_action/other/penis/hemi/oral_double
	abstract_type = FALSE

	name = "Геми-оральный секс"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_PRECISE_MOUTH

	affects_self_arousal	= 0.18
	affects_arousal			= 0.06
	affects_self_pain		= 0.04
	affects_pain			= 0.01

	target_suck_sound = TRUE
	actor_sex_hearts = TRUE
	actor_do_onomatopoeia = TRUE
	actor_do_thrust = TRUE
	can_be_custom = FALSE

	message_on_start   = "{actor} {pose}прижимает оба ствола ко рту {dullahan?отделенной головы :}{partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} сношает в рот {dullahan?отделенной головы :}{partner} двумя стволами{knot}."
	message_on_finish  = "{actor} вытаскивает члены из рта {dullahan?отделенной головы :}{partner}."
	message_on_climax_actor  = "{actor}  кончает в рот {aggr?задницей:ягодицами} {dullahan?отделенной головы :}{partner}."
	message_on_climax_target = "{partner} кончает под себя!"

/datum/sex_panel_action/other/penis/hemi/oral_double/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	. = ..()
	return "into"

/datum/sex_panel_action/other/penis/hemi/oral_double/get_knot_count()
	return 1
