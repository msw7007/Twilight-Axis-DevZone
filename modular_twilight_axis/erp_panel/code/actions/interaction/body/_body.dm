/datum/sex_panel_action/other/body
	abstract_type = TRUE
	name = "Корневое действие телом"
	required_init = null
	stamina_cost = 0.3
	check_same_tile = FALSE

/datum/sex_panel_action/other/body/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает под себя!"
	user.visible_message(span_love(message))
	return "self"
