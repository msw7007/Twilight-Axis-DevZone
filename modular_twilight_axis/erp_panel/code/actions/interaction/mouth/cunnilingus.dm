/datum/sex_panel_action/other/mouth/cunnilingus
	abstract_type = FALSE
	name = "Куннилингус"
	required_target = SEX_ORGAN_VAGINA
	stamina_cost = 0.01
	affects_self_arousal = 0.12
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/mouth/cunnilingus/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] припадет к лону [target]."

/datum/sex_panel_action/other/mouth/cunnilingus/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] вылизывает киску [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/mouth/cunnilingus/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает лицо от паха [target]."

/datum/sex_panel_action/other/mouth/cunnilingus/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
