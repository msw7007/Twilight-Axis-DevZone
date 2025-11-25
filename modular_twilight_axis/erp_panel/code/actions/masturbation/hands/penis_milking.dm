/datum/sex_panel_action/self/hands/milking_penis
	abstract_type = FALSE

	name = "Мастурбация пенисом"
	required_target = SEX_ORGAN_PENIS
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.22
	affects_arousal      = 0
	affects_self_pain    = 0.01
	affects_pain         = 0

/datum/sex_panel_action/self/hands/milking_penis/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] берёт свой член в руку."

/datum/sex_panel_action/self/hands/milking_penis/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] мастурбирует рукой свой член."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/milking_penis/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] ослабляет хватку и останавливается."

/datum/sex_panel_action/self/hands/milking_penis/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
