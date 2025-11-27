/datum/component/arousal
	var/chain_orgasm_lock = FALSE

/datum/component/arousal/proc/spread_climax_to_partners(mob/living/carbon/human/source)
	if(!source)
		return

	var/list/sessions = return_sessions_with_user_tgui(source)
	if(!length(sessions))
		return

	var/list/affected = list()

	for(var/datum/sex_session_tgui/S in sessions)
		if(QDELETED(S))
			continue

		if(istype(S.user, /mob/living/carbon/human) && S.user != source)
			affected |= S.user

		if(istype(S.target, /mob/living/carbon/human) && S.target != source)
			affected |= S.target

		for(var/mob/living/carbon/human/M in S.partners)
			if(M != source)
				affected |= M

	for(var/mob/living/carbon/human/M in affected)
		if(QDELETED(M) || M.stat == DEAD)
			continue

		var/is_nympho = M.has_flaw(/datum/charflaw/addiction/lovefiend)
		var/bonus = is_nympho ? 20 : 10

		var/datum/component/arousal/A = M.GetComponent(/datum/component/arousal)
		if(!A)
			continue

		A.chain_orgasm_lock = TRUE
		SEND_SIGNAL(M, COMSIG_SEX_ADJUST_AROUSAL, bonus)

/datum/component/arousal/after_ejaculation(intimate = FALSE, mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_spread = !chain_orgasm_lock
	chain_orgasm_lock = FALSE

	if(do_spread)
		spread_climax_to_partners(user)

	SEND_SIGNAL(user, COMSIG_SEX_SET_AROUSAL, 20)
	SEND_SIGNAL(user, COMSIG_SEX_CLIMAX)

	charge = max(0, charge - CHARGE_FOR_CLIMAX)

	user.add_stress(/datum/stressevent/cumok)
	if(user.has_flaw(/datum/charflaw/addiction/lovefiend))
		user.sate_addiction()
		if(user == target)
			var/datum/charflaw/addiction/lovefiend/link_flaw = user.get_flaw()
			if(link_flaw)
				link_flaw.time = rand(6 MINUTES, 30 MINUTES)
	user.emote("moan", forced = TRUE)
	user.playsound_local(user, 'sound/misc/mat/end.ogg', 100)
	last_ejaculation_time = world.time

	if(intimate)
		after_intimate_climax(user, target)

/datum/component/arousal/ejaculate()
	var/mob/living/carbon/human/mob = parent

	var/list/parent_sessions = return_sessions_with_user_tgui(mob)

	var/datum/sex_action_session/highest_priority = null
	var/best_score = -1

	for(var/datum/sex_session_tgui/S in parent_sessions)
		if(QDELETED(S))
			continue

		var/datum/sex_action_session/I = S.get_best_action_session_for(mob)
		if(!I)
			continue

		var/score = I.get_priority_for(mob)
		if(score > best_score)
			best_score = score
			highest_priority = I

	playsound(mob, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)

	if(!mob.getorganslot(ORGAN_SLOT_TESTICLES) && mob.getorganslot(ORGAN_SLOT_PENIS))
		mob.visible_message(span_love("[mob] climaxes, yet nothing is released!"))
		after_ejaculation(FALSE, mob, null)
		return

	if(!highest_priority)
		var/turf/turf = get_turf(mob)
		new /obj/effect/decal/cleanable/coom(turf)
		after_ejaculation(FALSE, mob, null)
		return

	var/datum/sex_action_session/S = highest_priority
	var/datum/sex_session_tgui/SS = S.session
	var/mob/living/carbon/human/U = SS.user
	var/mob/living/carbon/human/T = SS.target
	var/datum/sex_panel_action/A = S.action

	var/return_type = A.handle_climax_message(U, T)
	if(!return_type)
		var/turf/turf2 = get_turf(mob)
		new /obj/effect/decal/cleanable/coom(turf2)
		after_ejaculation(FALSE, U, T)
	else
		handle_climax(return_type, U, T)
		after_ejaculation(return_type == "into" || return_type == "oral", U, T)

	if(SS.do_knot_action && A.can_knot && U)
		var/obj/item/organ/penis/P = U.getorganslot(ORGAN_SLOT_PENIS)
		var/datum/sex_organ/penis/PO = P ? P.sex_organ : null
		if(PO && PO.have_knot)
			A.try_knot_on_climax(U, T)

/datum/component/arousal/receive_sex_action(datum/source, arousal_amt, pain_amt, giving, applied_force, applied_speed, organ_id)
	var/mob/user = parent
	arousal_amt *= get_force_pleasure_multiplier(applied_force, giving)
	pain_amt *= get_force_pain_multiplier(applied_force)
	pain_amt *= get_speed_pain_multiplier(applied_speed)
	pain_amt *= PAIN_BASE_SCALE

	var/final_pain = pain_amt
	switch(applied_force)
		if(SEX_FORCE_HIGH)
			if(prob(FORCE_HIGH_PAIN_CRIT_CHANCE))
				final_pain *= FORCE_PAIN_CRIT_MULT
		if(SEX_FORCE_EXTREME)
			if(prob(FORCE_EXTREME_PAIN_CRIT_CHANCE))
				final_pain *= FORCE_PAIN_CRIT_MULT

	if(user.stat == DEAD)
		arousal_amt = 0
		final_pain = 0

	if(!arousal_frozen)
		adjust_arousal(source, arousal_amt)

	if(final_pain > 0)
		damage_from_pain(final_pain, organ_id)
		try_do_pain_effect(final_pain, giving)

	try_do_moan(arousal_amt, final_pain, applied_force, giving)


/datum/component/arousal/damage_from_pain(pain_amt, organ_id)
	var/mob/living/carbon/user = parent
	if(pain_amt <= 1)
		return

	var/excess = pain_amt - 1
	var/damage = excess
	var/zone = BODY_ZONE_CHEST
	switch(organ_id)
		if("mouth")
			zone = BODY_ZONE_HEAD
		if("left_hand")
			zone = BODY_ZONE_L_ARM
		if("right_hand")
			zone = BODY_ZONE_R_ARM
		if("legs")
			zone = BODY_ZONE_R_LEG
		if("tail")
			zone = BODY_ZONE_CHEST
		if("breasts")
			zone = BODY_ZONE_CHEST
		if("genital_v", "genital_p", "genital_a")
			zone = BODY_ZONE_CHEST

	var/obj/item/bodypart/part = user.get_bodypart(zone)
	if(!part)
		return

	user.apply_damage(damage, BRUTE, zone)

/datum/component/arousal/get_arousal(datum/source, list/arousal_data)
	arousal_data += list(
		"arousal" = arousal,
		"frozen" = arousal_frozen,
		"last_increase" = last_arousal_increase_time,
		"arousal_multiplier" = arousal_multiplier,
		"is_spent" = is_spent()
	)
