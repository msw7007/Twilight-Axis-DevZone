/datum/sex_panel_action/other/vagina/masturbation
	abstract_type = FALSE

	name = "Мастурбировать на партнера"
	required_target = null
	armor_slot_init = BODY_ZONE_PRECISE_GROIN
	check_same_tile = FALSE

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/vagina/masturbation/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] трёт свою промежность, смотря на [target]."

/datum/sex_panel_action/other/vagina/masturbation/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит рукой по своему клитору, направляя пах на [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/vagina/masturbation/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от своего лона."
