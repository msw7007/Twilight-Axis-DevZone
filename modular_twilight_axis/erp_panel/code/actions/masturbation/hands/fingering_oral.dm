/datum/sex_panel_action/self/hands/fingering_o
	abstract_type = FALSE

	name = "Фингеринг анальный"
	required_target = SEX_ORGAN_ANUS
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.01
	affects_arousal      = 0
	affects_self_pain    = 0.00
	affects_pain         = 0

/datum/sex_panel_action/self/hands/fingering_o/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается своих губ пальцем."

/datum/sex_panel_action/self/hands/fingering_o/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] посасывает свой палец."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/fingering_o/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает палец из рта."

/datum/sex_panel_action/self/hands/fingering_o/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
