/datum/sex_panel_action/other/legs
	abstract_type = TRUE
	name = "Корневое действие ногами"
	required_init = SEX_ORGAN_LEGS
	stamina_cost = 0.3
	check_same_tile = TRUE

/datum/sex_panel_action/other/legs/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "self"
