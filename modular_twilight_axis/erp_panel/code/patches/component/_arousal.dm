/datum/component/arousal
	var/chain_orgasm_lock = FALSE
	var/last_ejaculation_world_time = -1
	var/tmp/last_nympho_boost_time = 0
	charge = CHARGE_FOR_CLIMAX

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
		if(!length(S.current_actions))
			continue

		for(var/id in S.current_actions)
			var/datum/sex_action_session/I = S.current_actions[id]
			if(!I || QDELETED(I) || !I.action)
				continue

			var/mob/living/carbon/human/A = I.actor
			var/mob/living/carbon/human/P = I.partner

			if(A == source && P && P != source)
				affected |= P
			else if(P == source && A && A != source)
				affected |= A

	for(var/mob/living/carbon/human/M in affected)
		if(QDELETED(M) || M.stat == DEAD)
			continue

		var/is_nympho = M.has_flaw(/datum/charflaw/addiction/lovefiend)
		var/bonus = is_nympho ? 20 : 40

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
		if(parent == user)
			arousal_multiplier = clamp(arousal_multiplier + NYMPHO_ORGASM_MULT_GAIN, 1, NYMPHO_ORGASM_MULT_MAX)
			last_nympho_boost_time = world.time

		if(user == target)
			var/datum/charflaw/addiction/lovefiend/link_flaw = user.get_flaw()
			if(link_flaw)
				link_flaw.time = rand(6 MINUTES, 30 MINUTES)

	if(last_moan + MOAN_COOLDOWN < world.time)
		user.emote("moan", forced = TRUE)
		last_moan = world.time

	user.playsound_local(user, 'sound/misc/mat/end.ogg', 100)
	last_ejaculation_time = world.time

	if(intimate)
		after_intimate_climax(user, target)

/datum/component/arousal/ejaculate()
	if(world.time <= (last_ejaculation_world_time + 2 SECONDS))
		return
	last_ejaculation_world_time = world.time

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
		do_ejac_inject_from_session(mob, null)
		var/turf/turf = get_turf(mob)
		new /obj/effect/decal/cleanable/coom(turf)
		after_ejaculation(FALSE, mob, null)
		return

	var/datum/sex_action_session/S = highest_priority
	var/datum/sex_session_tgui/SS = S.session

	var/mob/living/carbon/human/source = mob
	var/mob/living/carbon/human/partner = null
	var/is_active = TRUE

	if(S.actor == source)
		is_active = TRUE
		if(istype(S.partner, /mob/living/carbon/human))
			partner = S.partner
	else if(S.partner == source)
		is_active = FALSE
		if(istype(S.actor, /mob/living/carbon/human))
			partner = S.actor
	else
		is_active = TRUE
		partner = null

	if(istype(S.partner, /mob/living/carbon/human))
		partner = S.partner

	if(partner == source)
		partner = null

	if(partner == source)
		partner = null

	do_ejac_inject_from_session(source, S)
	var/datum/sex_panel_action/A = S.action
	var/return_type = A.handle_climax_message(source, partner, is_active)
	if(!return_type)
		var/turf/turf2 = get_turf(mob)
		new /obj/effect/decal/cleanable/coom(turf2)
		after_ejaculation(FALSE, source, partner)
	else
		handle_climax(return_type, source, partner)
		after_ejaculation(return_type == "into" || return_type == "onto", source, partner)

	if(SS.do_knot_action && A.can_knot && source)
		var/obj/item/organ/penis/P = source.getorganslot(ORGAN_SLOT_PENIS)
		var/datum/sex_organ/penis/PO = P ? P.sex_organ : null
		if(PO && PO.have_knot)
			A.try_knot_on_climax(source, partner)

/datum/component/arousal/receive_sex_action(datum/source, arousal_amt, pain_amt, giving, applied_force, applied_speed, organ_id)
	var/mob/user = parent

	arousal_amt *= get_force_pleasure_multiplier(applied_force, giving)
	pain_amt *= get_force_pain_multiplier(applied_force)
	pain_amt *= get_speed_pain_multiplier(applied_speed)
	pain_amt *= PAIN_BASE_SCALE

	var/list/effect = list(
		"arousal" = arousal_amt,
		"pain" = pain_amt,
		"giving" = giving,
		"force" = applied_force,
		"speed" = applied_speed,
		"organ_id" = organ_id,
	)

	SEND_SIGNAL(user, COMSIG_SEX_MODIFY_EFFECT, effect)

	arousal_amt = effect["arousal"]
	pain_amt    = effect["pain"]

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

	if(giving && user.has_flaw(/datum/charflaw/addiction/lovefiend))
		if(!arousal_amt)
			arousal_amt = 0.02

	if(!arousal_frozen)
		adjust_arousal(source, arousal_amt)

	var/do_damage = (applied_force == SEX_FORCE_HIGH || applied_force == SEX_FORCE_EXTREME)

	if(do_damage && final_pain > 0)
		damage_from_pain(final_pain, organ_id)

	try_do_pain_effect(final_pain, giving)
	try_do_moan(arousal_amt, final_pain, applied_force, giving)

/datum/component/arousal/damage_from_pain(pain_amt, organ_id)
    var/mob/living/carbon/user = parent
    if(pain_amt <= 1)
        return

    var/excess = pain_amt - 1
    var/damage = excess

    var/zone = erp_filter_to_body_zone(organ_id)

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

/datum/component/arousal/handle_climax(climax_type, mob/living/carbon/human/user, mob/living/carbon/human/target)
	switch(climax_type)
		if("onto")
			log_combat(user, target, "Came onto the target")
			playsound(target, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)
			var/turf/turf = get_turf(target)
			new /obj/effect/decal/cleanable/coom(turf)
			if(target)
				var/datum/status_effect/facial/facial = target.has_status_effect(/datum/status_effect/facial)
				if(!facial)
					target.apply_status_effect(/datum/status_effect/facial)
				else
					facial.refresh_cum()
		if("into")
			log_combat(user, target, "Came inside the target")
			playsound(target, 'sound/misc/mat/endin.ogg', 50, TRUE, ignore_walls = FALSE)
			if(target)
				var/status_type = /datum/status_effect/facial/internal
				var/datum/status_effect/facial/internal_effect = target.has_status_effect(status_type)
				if(!internal_effect)
					target.apply_status_effect(status_type)
				else
					internal_effect.refresh_cum()
		if("self")
			log_combat(user, user, "Ejaculated")
			playsound(user, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)

	after_ejaculation(climax_type == "into" || climax_type == "oral", user, target)

/datum/component/arousal/proc/on_sex_organ_produced(datum/sex_organ/org, amount)
	if(amount <= 0)
		return

	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	switch(org.organ_type)
		if(SEX_ORGAN_PENIS)
			adjust_charge(amount * PENIS_CHARGE_PER_UNIT)
		if(SEX_ORGAN_VAGINA)
			adjust_charge(amount * VAGINA_CHARGE_PER_UNIT)

#define PENIS_VOLUME_CHARGE_RATE 0.5

/datum/component/arousal/handle_charge(dt)
	var/mob/living/carbon/human/H = parent
	var/has_testicles = FALSE

	if(istype(H))
		var/obj/item/organ/testicles/T = H.getorganslot(ORGAN_SLOT_TESTICLES)
		if(T)
			has_testicles = TRUE

	if(!has_testicles)
		adjust_charge(dt * CHARGE_RECHARGE_RATE)

	if(istype(H))
		var/obj/item/organ/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
		if(P && P.sex_organ)
			var/datum/sex_organ/penis/PO = P.sex_organ
			if(PO.has_storage())
				var/min_needed = max(PO.stored_liquid_max * PENIS_MIN_EJAC_FRACTION, PENIS_MIN_EJAC_ABSOLUTE)
				var/vol = PO.total_volume()
				if(vol >= min_needed && charge < CHARGE_FOR_CLIMAX)
					var/fullness = vol / max(1, PO.stored_liquid_max) // 0..1
					var/gain = dt * PENIS_VOLUME_CHARGE_RATE * fullness
					adjust_charge(gain)

	if(is_spent())
		if(arousal > 60)
			to_chat(parent, span_warning("I'm too spent!"))
			adjust_arousal(parent, -20)
			return
		adjust_arousal(parent, -dt * SPENT_AROUSAL_RATE)

#undef PENIS_VOLUME_CHARGE_RATE

/datum/component/arousal/is_spent()
	var/mob/living/carbon/human/H = parent

	if(istype(H))
		var/obj/item/organ/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
		var/obj/item/organ/testicles/T = H.getorganslot(ORGAN_SLOT_TESTICLES)

		if(P && T && P.sex_organ)
			var/datum/sex_organ/penis/PO = P.sex_organ
			if(PO.has_storage())
				var/min_needed = max(PO.stored_liquid_max * PENIS_MIN_EJAC_FRACTION, PENIS_MIN_EJAC_ABSOLUTE)
				var/current = PO.total_volume()
				if(current >= min_needed)
					return FALSE

				if(charge < CHARGE_FOR_CLIMAX)
					return TRUE

				return FALSE

	if(charge < CHARGE_FOR_CLIMAX)
		return TRUE

	return FALSE

/datum/component/arousal/process(dt)
	handle_charge(dt * 1)

	var/mob/living/carbon/human/H = parent
	if(istype(H))
		if(H.has_flaw(/datum/charflaw/addiction/lovefiend))
			if(charge >= SEX_MAX_CHARGE && arousal < NYMPHO_AROUSAL_SOFT_CAP)
				if(is_in_sex_scene())
					adjust_arousal(parent, dt * NYMPHO_PASSIVE_AROUSAL_GAIN)

	if(!can_lose_arousal())
		return

	adjust_arousal(parent, dt * -1)

/datum/component/arousal/update_arousal_effects()
	update_pink_screen()
	update_blueballs()
	update_erect_state()
	if(last_nympho_boost_time && world.time > last_nympho_boost_time + NYMPHO_BOOST_DURATION)
		arousal_multiplier = 1
		last_nympho_boost_time = 0

/datum/component/arousal/proc/do_ejac_inject_from_session(mob/living/carbon/human/source, datum/sex_action_session/S)
	if(!source)
		return

	var/list/blocked = get_blocked_containers_for_mob(source)
	if(!S || !S.session)
		var/obj/item/organ/penis/P0 = source.getorganslot(ORGAN_SLOT_PENIS)
		if(!P0 || !P0.sex_organ)
			return

		var/datum/sex_organ/penis/PO0 = P0.sex_organ
		PO0.inject_liquid(null, source, blocked)
		return

	var/datum/sex_session_tgui/SS = S.session
	var/actor_type = SS.node_organ_type(S.actor_node_id)
	var/partner_type = SS.node_organ_type(S.partner_node_id)
	var/mob/living/carbon/human/owner = source
	var/organ_node_id = null

	if(actor_type == SEX_ORGAN_PENIS)
		organ_node_id = S.actor_node_id
	else if(partner_type == SEX_ORGAN_PENIS)
		organ_node_id = S.partner_node_id

	if(!organ_node_id)
		var/obj/item/organ/penis/P = source.getorganslot(ORGAN_SLOT_PENIS)
		if(!P || !P.sex_organ)
			return

		var/datum/sex_organ/penis/PO = P.sex_organ
		PO.inject_liquid(null, source, blocked)
		return

	var/datum/sex_organ/src_org = SS.resolve_organ_datum(owner, organ_node_id)
	if(!src_org)
		return

	src_org.inject_liquid(null, source, blocked)

/datum/component/arousal/proc/get_blocked_containers_for_mob(mob/living/carbon/human/M)
	if(!M)
		return list()

	var/list/blocked = list()
	var/list/sessions = return_sessions_with_user_tgui(M)
	if(!length(sessions))
		return blocked

	for(var/datum/sex_session_tgui/S in sessions)
		if(QDELETED(S))
			continue
		if(!length(S.current_actions))
			continue

		for(var/id in S.current_actions)
			var/datum/sex_action_session/I = S.current_actions[id]
			if(!I || QDELETED(I) || !I.action)
				continue

			// нас интересуют только действия, в которых этот моб участвует
			if(I.actor != M && I.partner != M)
				continue

			var/datum/sex_panel_action/A = I.action
			if(!A)
				continue

			var/obj/item/C = A.active_container
			if(C && !(C in blocked))
				blocked += C

	return blocked

/datum/component/arousal/adjust_arousal(datum/source, amount)
	if(arousal_frozen)
		return arousal

	var/final_amount = amount

	if(final_amount > 0)
		final_amount *= arousal_multiplier

	return set_arousal(source, arousal + final_amount)

/datum/component/arousal/proc/is_in_sex_scene()
	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return FALSE

	var/list/sessions = return_sessions_with_user_tgui(H)
	if(!length(sessions))
		return FALSE

	for(var/datum/sex_session_tgui/S in sessions)
		if(QDELETED(S))
			continue
		if(!length(S.current_actions))
			continue

		for(var/id in S.current_actions)
			var/datum/sex_action_session/I = S.current_actions[id]
			if(!I || QDELETED(I))
				continue

			if(I.actor == H || I.partner == H)
				return TRUE

	return FALSE
