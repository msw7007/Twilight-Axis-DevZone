/datum/sex_panel_action/other/vagina/tail
	abstract_type = FALSE
	name = "Использовать хвост"
	required_target = SEX_ORGAN_TAIL
	stamina_cost = 0.06
	affects_self_arousal = 0.08
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/vagina/tail/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает хвост [target], прижимая его к своему лону."

/datum/sex_panel_action/other/vagina/tail/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит хвостом [target] в своей киске."
	return spanify_force(message)

/datum/sex_panel_action/other/vagina/tail/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает хвост [target] из своего влагалища."

/datum/sex_panel_action/other/vagina/tail/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
