/datum/sex_panel_action/other/hands/spanking
	abstract_type = FALSE
	name = "Шлепать ягодицы"
	required_target = SEX_ORGAN_ANUS
	stamina_cost = 0.05
	affects_self_arousal = 0
	affects_arousal      = 0.15
	affects_self_pain    = 0
	affects_pain         = 0.05

/datum/sex_panel_action/other/hands/spanking/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] размещает руки на ягодицах [target]."

/datum/sex_panel_action/other/hands/spanking/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] шлепает [is_agressive_tier() ? "зад" : "ягодицы"] [target]."
	show_sex_effects(user)
	var/sound = pick('sound/foley/slap.ogg', 'sound/foley/smackspecial.ogg')
	playsound(user, sound, 50, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/spanking/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от ягодиц [target]."

