/datum/sex_panel_action/self/tail/suck_tail
	abstract_type = FALSE

	name = "Обсосать хвост"
	required_init = SEX_ORGAN_TAIL
	required_target = SEX_ORGAN_MOUTH

	affects_self_arousal = 0.1
	affects_arousal      = 0
	affects_self_pain    = 0
	affects_pain         = 0

/datum/sex_panel_action/self/tail/suck_tail/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] подводит хвост ближе к лицу."

/datum/sex_panel_action/self/tail/suck_tail/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/message = "[user] [get_force_text()] и [get_speed_text()] обсасывает хвост в своем рту."
	return spanify_force(message)

/datum/sex_panel_action/self/tail/suck_tail/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] уводит хвост от лица."

/datum/sex_panel_action/self/tail/suck_tail/on_perform(user, target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
