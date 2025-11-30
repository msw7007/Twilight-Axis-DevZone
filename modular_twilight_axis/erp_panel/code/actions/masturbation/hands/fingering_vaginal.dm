/datum/sex_panel_action/self/hands/fingering_vaginal
	abstract_type = FALSE

	name = "Фингеринг вагинальный"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_init = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.15
	affects_arousal      = 0
	affects_self_pain    = 0.02
	affects_pain         = 0

/datum/sex_panel_action/self/hands/fingering_vaginal/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] кладет руку себе на вагину, проникая пальцем."

/datum/sex_panel_action/self/hands/fingering_vaginal/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] двигает пальцем в вагине."
	do_onomatopoeia(user)
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/self/hands/fingering_vaginal/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руку от своей промежности."
