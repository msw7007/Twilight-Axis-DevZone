/datum/sex_panel_action/other/penis/hemi/dp_vag_anal
	abstract_type = FALSE

	name = "Двойное проникновение"
	required_target = SEX_ORGAN_VAGINA
	var/required_target_second = SEX_ORGAN_ANUS
	armor_slot_target = BODY_ZONE_PRECISE_GROIN
	reserve_target_for_session = TRUE

	affects_self_arousal = 0.20
	affects_arousal      = 0.12
	affects_self_pain    = 0.05
	affects_pain         = 0.03
	can_knot = TRUE

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/get_filter_target_organ_types()
	return list(required_target, required_target_second)

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/proc/get_action_organs_dp(mob/living/carbon/human/user, mob/living/carbon/human/target, only_free_init = TRUE,	only_free_target = FALSE, only_free_second = FALSE)
	var/datum/sex_organ/init_organ = user.get_sex_organ_by_type(SEX_ORGAN_PENIS, only_free_init)
	if(!init_organ)
		return null

	var/datum/sex_organ/vag = target.get_sex_organ_by_type(SEX_ORGAN_VAGINA, only_free_target)
	if(!vag)
		return null

	var/datum/sex_organ/anus = target.get_sex_organ_by_type(SEX_ORGAN_ANUS, only_free_second)
	if(!anus)
		return null

	return list(
		"init"   = init_organ,
		"vag"    = vag,
		"anus"   = anus,
	)

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/shows_on_menu(user, target)
	if(!..())
		return FALSE

	if(!ishuman(target))
		return FALSE

	var/mob/living/carbon/human/T = target
	if(!T.get_sex_organ_by_type(SEX_ORGAN_VAGINA, FALSE))
		return FALSE
	if(!T.get_sex_organ_by_type(SEX_ORGAN_ANUS, FALSE))
		return FALSE

	return TRUE

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/can_perform(user, target)
	. = ..()
	if(!user || !target)
		return FALSE

	var/list/orgs = get_action_organs_dp(user, target, FALSE, FALSE, FALSE)
	if(!orgs)
		return FALSE

	var/datum/sex_organ/init_organ = orgs["init"]
	var/datum/sex_organ/vag        = orgs["vag"]
	var/datum/sex_organ/anus       = orgs["anus"]

	var/list/to_check = list()
	if(init_organ)
		to_check += init_organ
	if(vag)
		to_check += vag
	if(anus)
		to_check += anus

	for(var/datum/sex_organ/O in to_check)
		if(!O)
			continue

		var/node_id = O.organ_type
		if(!node_id)
			continue

		var/mob/living/carbon/human/owner

		if(istype(O.organ_link, /obj/item/bodypart))
			var/obj/item/bodypart/BP = O.organ_link
			owner = BP.owner
		else if(istype(O.organ_link, /obj/item/organ))
			var/obj/item/organ/ORG = O.organ_link
			owner = ORG.owner

		if(!owner)
			continue

		if(owner.is_sex_node_restrained(node_id))
			return FALSE

	if(!passes_armor_check(user, target))
		return FALSE

	return TRUE

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/connect_organs(user, target)
	var/list/orgs = get_action_organs_dp(user, target)
	if(!orgs)
		return FALSE

	var/datum/sex_organ/init_organ = orgs["init"]
	var/datum/sex_organ/vag        = orgs["vag"]
	var/datum/sex_organ/anus       = orgs["anus"]

	if(!init_organ)
		return FALSE

	if(vag)
		if(!init_organ.can_start_active())
			return FALSE
		if(!init_organ.start_active(vag))
			return FALSE

	if(anus)
		if(!init_organ.can_start_active())
			return FALSE
		if(!init_organ.start_active(anus))
			return FALSE

	return orgs

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/get_start_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	return "[user] [get_pose_text(pose_state)] приставляет свои члены сразу к обоим дырочкам [target]."

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/get_perform_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/pose_state = get_pose_key(user, target)
	var/msg = "[user] [get_pose_text(pose_state)], [get_force_text()] и [get_speed_text()] трахает [target] сразу в киску и зад [get_knot_action()]."
	do_onomatopoeia(user)
	show_sex_effects(user)
	do_thrust_animate(user, target)
	do_sound_effect(user)
	return spanify_force(msg)

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/get_finish_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return "[user] вытаскивает члены из дырок [target]."

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/handle_climax_message(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/result = ..()
	if(!islist(result))
		result = list(result)

	result += "одновременно заполняя и киску, и зад [target]."
	var/message = span_love(result.Join(" "))
	user.visible_message(message)
	return "into"

/datum/sex_panel_action/other/penis/hemi/dp_vag_anal/get_reserved_target_organ_types()
	if(!reserve_target_for_session)
		return null

	return list(SEX_ORGAN_VAGINA, SEX_ORGAN_ANUS)
