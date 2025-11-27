/datum/sex_panel_action/other/penis/tea_bag
	abstract_type = FALSE

	name = "Чайный пакетик"
	required_target = SEX_ORGAN_MOUTH
	armor_slot_lock = BODY_ZONE_PRECISE_GROIN
	can_knot = FALSE

	affects_self_arousal = 0.12
	affects_arousal      = 0
	affects_self_pain    = 0.03
	affects_pain         = 0

/datum/sex_panel_action/other/penis/tea_bag/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет тестикулами к лицу [target]."

/datum/sex_panel_action/other/penis/tea_bag/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/message = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] водит тестикулам по лицу [target]."
	return spanify_force(message)

/datum/sex_panel_action/other/penis/tea_bag/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] убирает тестикулы с лица [target]."

/datum/sex_panel_action/other/penis/tea_bag/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	. = ..()

	do_onomatopoeia(user)
	show_sex_effects(user)

/datum/sex_panel_action/other/penis/tea_bag/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "на лицо [target]"
	var/message = span_love(result.Join("\n"))
	return message

/datum/sex_panel_action/other/penis/tea_bag/get_pose_text(pose_state)
	switch(pose_state)
		if(SEX_POSE_BOTH_STANDING)
			return "нависая"
		if(SEX_POSE_USER_LYING)
			return "снизу"
		if(SEX_POSE_TARGET_LYING)
			return "нависая"
		if(SEX_POSE_BOTH_LYING)
			return "лежа"
