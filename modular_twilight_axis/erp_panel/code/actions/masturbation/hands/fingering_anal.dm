/datum/sex_panel_action/self/hands/fingering_a
	abstract_type = FALSE

	name = "Фингеринг анальный"
	required_target = SEX_ORGAN_ANUS
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/self/hands/fingering_a/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] подводит палец к анальному кольцу и вводит его."

/datum/sex_panel_action/self/hands/fingering_a/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит пальцем в своей заднице."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/fingering_a/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает палец из своей попки."

/datum/sex_panel_action/self/hands/fingering_a/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
