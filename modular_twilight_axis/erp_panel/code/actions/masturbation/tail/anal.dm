/datum/sex_panel_action/self/tail/anal_tail
	abstract_type = FALSE

	name = "Анальные игры хвостом"
	required_init = SEX_ORGAN_TAIL
	required_target = SEX_ORGAN_ANUS
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.15
	affects_self_pain    = 0.03

/datum/sex_panel_action/self/tail/anal_tail/get_start_message(user, target)
	return "[user] изгибает свой хвост, кончик поводя к своей попке."

/datum/sex_panel_action/self/tail/anal_tail/get_perform_message(user, target)
	var/message = "[user] [get_force_text()] и [get_speed_text()] двигает хвостом в своей заднице."
	return spanify_force(message)

/datum/sex_panel_action/self/tail/anal_tail/get_finish_message(user, target)
	return "[user] прекращает движение хвостом."

/datum/sex_panel_action/self/tail/anal_tail/on_perform(user, target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
