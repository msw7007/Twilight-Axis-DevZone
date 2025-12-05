/datum/sex_panel_action/other/hands
	abstract_type = TRUE
	name = "Корневое действие руками"
	required_init = SEX_ORGAN_HANDS
	stamina_cost = 0.3
	check_same_tile = FALSE

/datum/sex_panel_action/other/hands/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "self"
