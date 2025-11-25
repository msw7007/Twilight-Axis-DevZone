/datum/sex_panel_action/self/hands/fingering_v
	abstract_type = FALSE

	name = "Фингеринг вагинальный"
	required_target = SEX_ORGAN_VAGINA
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN

	affects_self_arousal = 0.15
	affects_arousal      = 0
	affects_self_pain    = 0.02
	affects_pain         = 0

/datum/sex_panel_action/self/hands/fingering_v/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] кладет руку себе на вагину, проникая пальцем."

/datum/sex_panel_action/self/hands/fingering_v/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] двигает пальцем в вагине."
	return spanify_force(message)

/datum/sex_panel_action/self/hands/fingering_v/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руку от своей промежности."

/datum/sex_panel_action/self/hands/fingering_v/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)
