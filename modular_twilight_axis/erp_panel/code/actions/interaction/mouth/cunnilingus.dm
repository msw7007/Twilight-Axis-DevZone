/datum/sex_panel_action/other/mouth/cunnilingus
	abstract_type = FALSE
	name = "Куннилингус"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.01
	affects_self_arousal = 0.04
	affects_arousal = 0.12
	affects_self_pain = 0.01
	affects_pain = 0.02

	actor_sex_hearts = TRUE
	actor_suck_sound = TRUE

	message_on_start   = "{actor} припадет к лону {partner}."
	message_on_perform = "{actor} {pose}, {force} и {speed} вылизывает киску {partner}."
	message_on_finish  = "{actor} убирает лицо от паха {partner}."
	message_on_climax_actor  = "{partner} кончает на лицо {actor}."
	message_on_climax_target = "{actor} кончает под себя."
	climax_liquid_mode = "onto"
