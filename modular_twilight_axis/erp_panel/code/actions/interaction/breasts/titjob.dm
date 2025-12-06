/datum/sex_panel_action/other/breasts/titjob
	abstract_type = FALSE
	name = "Работа грудью"
	required_target = SEX_ORGAN_PENIS
	stamina_cost = 0.05
	affects_self_arousal	= 0.06
	affects_arousal			= 0.12
	affects_self_pain		= 0
	affects_pain			= 0.01
	require_grab = TRUE
	check_same_tile = FALSE

/datum/sex_panel_action/other/breasts/titjob/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] [is_big_boobs() ? "обхватывает" : "зажимает"] член [target] грудью."

/datum/sex_panel_action/other/breasts/titjob/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] [is_big_boobs() ? "утопает в своей груди член" : "водит грудью по члену"] [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/breasts/titjob/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает грудь от члена [target]."

/datum/sex_panel_action/other/breasts/titjob/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target, is_active = TRUE)
	var/message = is_active ? "[user] кончает под себя" : "[target] кончает на грудь [user]"
	user.visible_message(span_love(message))
	return "self"
