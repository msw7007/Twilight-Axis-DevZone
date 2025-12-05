/datum/sex_panel_action/other/tail/spanking
	abstract_type = FALSE
	name = "Шлепать хвостом"
	required_target = null
	stamina_cost = 0.06
	affects_self_arousal = 0
	affects_arousal      = 0.12
	affects_self_pain    = 0
	affects_pain         = 0.04

/datum/sex_panel_action/other/tail/spanking/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] прикладывает хвост к попе [target]."

/datum/sex_panel_action/other/tail/spanking/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] шлепает хвостом по заднице [target]."
	show_sex_effects(user)
	var/sound = pick('sound/foley/slap.ogg', 'sound/foley/smackspecial.ogg')
	playsound(user, sound, 50, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/tail/spanking/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает хвост от попки [target]."
