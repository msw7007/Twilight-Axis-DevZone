/datum/sex_panel_action/self/tail/vag_tail
	abstract_type = FALSE

	name = "Вагинальные игры хвостом"
	required_init = SEX_ORGAN_TAIL
	required_target = SEX_ORGAN_VAGINA
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.18
	affects_self_pain    = 0.02

/datum/sex_panel_action/self/tail/vag_tail/get_start_message(user, target)
	return "[user] подводит кончик хвоста к своему лону."

/datum/sex_panel_action/self/tail/vag_tail/get_perform_message(user, target)
	var/message = "[user] [get_force_text()] и [get_speed_text()] двигает хвостом внутри себя."
	return spanify_force(message)

/datum/sex_panel_action/self/tail/vag_tail/get_finish_message(user, target)
	return "[user] отводит хвост."

/datum/sex_panel_action/self/tail/vag_tail/on_perform(user, target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
