/datum/sex_panel_action/other/tail/squeeze_breasts
	abstract_type = FALSE
	name = "Сжать хвостом грудь"
	required_target = SEX_ORGAN_BREASTS
	armor_slot_target = BODY_ZONE_CHEST
	stamina_cost = 0.06
	affects_self_arousal = 0.08
	affects_arousal      = 0.12
	affects_self_pain    = 0.01
	affects_pain         = 0.01

/datum/sex_panel_action/other/tail/squeeze_breasts/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] обвивает хвостом грудь [target]."

/datum/sex_panel_action/other/tail/squeeze_breasts/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] сжимает тиская грудь [target]."
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/tail/squeeze_breasts/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] уводит хвост от [target]."

