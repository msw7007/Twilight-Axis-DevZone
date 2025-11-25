/datum/sex_panel_action/self/tail/squeeze_breasts
	abstract_type = FALSE

	name = "Сжать грудь хвостом"
	required_init = SEX_ORGAN_TAIL
	required_target = SEX_ORGAN_BREASTS

	affects_self_arousal = 0.1
	affects_self_pain    = 0.0

/datum/sex_panel_action/self/tail/squeeze_breasts/get_start_message(user, target)
	return "[user] обвивает хвост вокруг груди."

/datum/sex_panel_action/self/tail/squeeze_breasts/get_perform_message(user, target)
	var/message = "[user] [get_force_text()] и [get_speed_text()] сжимает хвостом грудь."
	return spanify_force(message)

/datum/sex_panel_action/self/tail/squeeze_breasts/get_finish_message(user, target)
	return "[user] отпускает грудь."

/datum/sex_panel_action/self/tail/squeeze_breasts/on_perform(user, target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)

