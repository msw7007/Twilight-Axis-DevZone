/datum/sex_panel_action/other/anus/butt
	abstract_type = FALSE
	name = "Работать попкой"

	required_target = SEX_ORGAN_PENIS
	stamina_cost = 0.1

	affects_self_arousal = 0.06
	affects_arousal = 0.12
	affects_self_pain = 0
	affects_pain = 0.04

	actor_sex_hearts = TRUE
	actor_make_fingering_sound = TRUE

	message_on_start   = "{actor} {pose} прижимается попкой к члену {partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} водит {aggr?задницей:ягодицами} {dullahan?отделенной головы :}{partner}."
	message_on_finish  = "{actor} отводит круп от члена {partner}."
	message_on_climax_actor  = "{actor} кончает под себя."
	message_on_climax_target = "{partner} кончает на ягодицы {actor}."
	climax_liquid_mode = "onto"
