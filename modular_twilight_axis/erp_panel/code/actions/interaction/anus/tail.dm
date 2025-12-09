/datum/sex_panel_action/other/anus/tail
	abstract_type = FALSE
	name = "Использовать хвост попкой"
	required_target = SEX_ORGAN_TAIL
	stamina_cost = 0.06
	affects_self_arousal = 0.04
	affects_arousal = 0.12
	affects_self_pain = 0.01
	affects_pain = 0.01

	actor_sex_hearts = TRUE
	target_sex_hearts = TRUE
	actor_make_sound = TRUE
	target_make_sound = TRUE
	actor_suck_sound = TRUE
	target_suck_sound = TRUE
	actor_make_fingering_sound = TRUE
	target_make_fingering_sound = TRUE
	actor_do_onomatopoeia = TRUE
	target_do_onomatopoeia = TRUE
	actor_do_thrust = TRUE
	target_do_thrust = TRUE
	can_be_custom = FALSE

	message_on_start   = "{actor} {pose}  хватает хвост {partner} и направляет к своей попке."
	message_on_perform = "{actor} {pose}, {force} и {speed} удерживая хвост {partner} в своем анусе скачет на нём.."
	message_on_finish  = "{actor} вытаскитвает хвост {partner} из своей задницы."
	message_on_climax_actor  = "{actor} кончает, сжимая попкой хвост {partner}."
	message_on_climax_target = "{partner} кончает под себя."
	climax_liquid_mode = "self"
