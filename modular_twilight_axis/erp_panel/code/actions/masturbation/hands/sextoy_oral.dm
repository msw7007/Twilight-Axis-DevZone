/datum/sex_panel_action/self/hands/toy_oral
	abstract_type = FALSE

	name = "Секс-игрушка оральная"
	required_target = SEX_ORGAN_MOUTH

	affects_self_arousal	= 0.15

	actor_suck_sound = TRUE
	actor_sex_hearts = TRUE
	actor_make_fingering_sound = TRUE
	actor_do_onomatopoeia = TRUE

	message_on_start   = "{actor} {pose}, {force} и {speed} подносит игрушку ближе к лицу {dullahan?своей отделенной головы:}."
	message_on_perform = "{actor} {pose}, {force} и {speed} играет с игрушкой во рту {dullahan?своей отделенной головы:}."
	message_on_finish  = "{actor} {pose}, {force} и {speed} убирает игрушку {dullahan?от своей отделенной головы:}."

/datum/sex_panel_action/self/hands/toy_oral/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()
	if(!.)
		return FALSE

	var/obj/item/item_object = user.get_active_held_item()
	if(!is_sex_toy(item_object))
		return FALSE

	return TRUE
