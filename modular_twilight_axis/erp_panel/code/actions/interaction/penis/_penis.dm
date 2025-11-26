/datum/sex_panel_action/other/penis
	abstract_type = TRUE

	name = "Корневое действие членом"
	can_knot = TRUE
	required_init = SEX_ORGAN_PENIS
	stamina_cost = 0.3
	check_same_tile = TRUE

/datum/sex_panel_action/other/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message = span_love("[user] кончает в ")
	return message
