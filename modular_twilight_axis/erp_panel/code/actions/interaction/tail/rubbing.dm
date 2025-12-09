/datum/sex_panel_action/other/tail/rubbing
	abstract_type = FALSE
	name = "Тереться хвостом"
	required_target = null
	stamina_cost = 0.06
	affects_self_arousal	= 0.02
	affects_arousal			= 0.04
	affects_self_pain		= 0
	affects_pain			= 0.01

	actor_sex_hearts = TRUE
	actor_make_fingering_sound = TRUE

	message_on_start   = "{actor} {pose} прижимается хвостом к {partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} трется хвостом об {zone} {partner}."
	message_on_finish  = "{actor} отводит хвост от {partner}."
	message_on_climax_actor  = "{actor} кончает под себя {partner}."
	message_on_climax_target = "{partner} кончает под себя {actor}."
	climax_liquid_mode = "self"

