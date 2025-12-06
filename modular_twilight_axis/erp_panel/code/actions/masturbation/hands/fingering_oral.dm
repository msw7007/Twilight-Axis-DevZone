/datum/sex_panel_action/self/hands/fingering_oral
	abstract_type = FALSE

	name = "Фингеринг оральный"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_init = BODY_ZONE_PRECISE_MOUTH

	affects_self_arousal	= 0.01
	affects_arousal			= 0
	affects_self_pain		= 0.00
	affects_pain			= 0

/datum/sex_panel_action/self/hands/fingering_oral/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается своих губ пальцем."

/datum/sex_panel_action/self/hands/fingering_oral/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] посасывает свой палец."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/self/hands/fingering_oral/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает палец из рта."

