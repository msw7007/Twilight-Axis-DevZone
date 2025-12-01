/datum/sex_panel_action/other/penis/tea_bag
	abstract_type = FALSE

	name = "Чайный пакетик"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_init = BODY_ZONE_PRECISE_GROIN
	can_knot = FALSE

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/penis/tea_bag/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	if(!user)
		return

	var/obj/item/organ/testicles/testicles = user.getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testicles)
		return

/datum/sex_panel_action/other/penis/tea_bag/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет тестикулами к лицу [target]."

/datum/sex_panel_action/other/penis/tea_bag/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит тестикулам по лицу [target]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	return spanify_force(message)

/datum/sex_panel_action/other/penis/tea_bag/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает тестикулы с лица [target]."

/datum/sex_panel_action/other/penis/tea_bag/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "на лицо [target]"
	var/message = span_love(result.Join(" "))
	user.visible_message(message)
	return "onto"
