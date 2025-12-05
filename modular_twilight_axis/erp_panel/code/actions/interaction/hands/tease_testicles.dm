/datum/sex_panel_action/other/hands/tease_testicles
	abstract_type = FALSE
	name = "Ласкать тестикулы рукой"
	required_target = SEX_ORGAN_PENIS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	stamina_cost = 0.05
	affects_self_arousal = 0
	affects_arousal      = 0.06
	affects_self_pain    = 0
	affects_pain         = 0.05
	check_same_tile = FALSE

/datum/sex_panel_action/other/penis/tea_bag/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(!target)
		return

	var/obj/item/organ/testicles/testicles = target.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testicles)
		return

/datum/sex_panel_action/other/hands/tease_testicles/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] касается руками тестикул [target]."

/datum/sex_panel_action/other/hands/tease_testicles/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] перебирает пальчиками тестикулы [target]."
	show_sex_effects(user)
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	return spanify_force(message)

/datum/sex_panel_action/other/hands/tease_testicles/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает руки от яиц [target]."
