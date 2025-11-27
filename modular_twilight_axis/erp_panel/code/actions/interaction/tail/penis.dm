/datum/sex_panel_action/other/tail/penis
	abstract_type = FALSE
	name = "Мастурбация хвостом"
	required_target = SEX_ORGAN_PENIS
	stamina_cost = 0.06
	affects_self_arousal = 0.08
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/tail/penis/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] обвивает хвостом член [target]."

/datum/sex_panel_action/other/tail/penis/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит хвостом по члену [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/tail/penis/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] отводим хвост от члена [target]."

/datum/sex_panel_action/other/tail/penis/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
