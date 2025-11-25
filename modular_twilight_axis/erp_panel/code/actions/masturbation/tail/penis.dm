/datum/sex_panel_action/self/tail/penis_tail
	abstract_type = FALSE

	name = "Мастурбация пениса хвостом"
	required_init = SEX_ORGAN_TAIL
	required_target = SEX_ORGAN_PENIS
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.2
	affects_self_pain    = 0.01

/datum/sex_panel_action/self/tail/penis_tail/get_start_message(user, target)
	return "[user] оборачивает хвост вокруг своего члена."

/datum/sex_panel_action/self/tail/penis_tail/get_perform_message(user, target)
	var/message = "[user] [get_force_text()] и [get_speed_text()] двигает хвостом по своему члену."
	return spanify_force(message)

/datum/sex_panel_action/self/tail/penis_tail/get_finish_message(user, target)
	return "[user] ослабляет хватку хвостом."

/datum/sex_panel_action/self/tail/penis_tail/on_perform(user, target)
	. = ..()
	
	do_onomatopoeia(user)
	show_sex_effects(user)

