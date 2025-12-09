/datum/sex_panel_action/other/hands/force_armpits
	abstract_type = FALSE
	name = "Прижать к подмышкам"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_target = BODY_ZONE_HEAD
	stamina_cost = 0.05
	affects_self_arousal	= 0.08
	affects_arousal			= 0
	affects_self_pain		= 0.02
	affects_pain			= 0.01
	require_grab = TRUE

/datum/sex_panel_action/other/hands/force_armpits/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] хватает [target?.is_dullahan_head_partner() ? "отделенную голову" : "голову"] [target], прижимая к своей подмышке."

/datum/sex_panel_action/other/hands/force_armpits/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит лицом [target?.is_dullahan_head_partner() ? "отделенной головы " : ""][target] по своим подмышкам."
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/force_armpits/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руку от [target?.is_dullahan_head_partner() ? "отделенной головы" : "головы"] [target]."
