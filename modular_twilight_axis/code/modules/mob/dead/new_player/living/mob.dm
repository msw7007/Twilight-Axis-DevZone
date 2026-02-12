/mob/living/proc/can_be_carried()
	var/datum/species/S = null

	if(iscarbon(src))
		var/mob/living/carbon/C = src
		if(C.dna && C.dna.species)
			S = C.dna.species

	return S ? !!S.small_spieces : FALSE

/mob/living/offer_item(mob/living/offered_to, obj/offered_item)
	if(isnull(offered_to) || isnull(offered_item))
		stack_trace("no offered_to or offered_item in offer_item()")
		return

	if(istype(offered_item, /obj/item/grabbing) && isliving(offered_to))
		var/obj/item/grabbing/G = offered_item
		var/mob/living/target = offered_to
		if(G.grabbed == target)
			if(try_carry_small(target, G))
				return TRUE

		return FALSE

	var/time_left = COOLDOWN_TIMELEFT(src, offer_cooldown)

	if(time_left)
		to_chat(src, span_danger("I must wait [time_left / 10] seconds before offering again."))
		return FALSE

	offered_item_ref = WEAKREF(offered_item)

	var/stealthy = (m_intent == MOVE_INTENT_SNEAK)

	if(stealthy)
		to_chat(src, span_notice("I secretly offer [offered_item] to [offered_to]."))
		to_chat(offered_to, span_notice("[src] secretly offers [offered_item] to me..."))
	else
		visible_message(
			span_notice("[src] offers [offered_item] to [offered_to] with an outstretched hand."), \
			span_notice("I offer [offered_item] to [offered_to] with an outstretched hand."), \
			vision_distance = COMBAT_MESSAGE_RANGE, \
			ignored_mobs = list(offered_to)
		)
		to_chat(offered_to, span_notice("[src] offers [offered_item] to me..."))

	new /obj/effect/temp_visual/offered_item_effect(get_turf(src), offered_item, src, offered_to, stealthy)

/mob/living/proc/try_carry_small(mob/living/target, obj/item/grabbing/G)
	if(!target || !G)
		return FALSE

	if(!target.can_be_carried())
		to_chat(src, span_warning("I can't carry [target] like that."))
		return FALSE

	if(cmode || target.cmode)
		to_chat(src, span_warning("Not while one of us is in combat."))
		return FALSE

	if(pulling != target)
		to_chat(src, span_warning("I need a passive grip first."))
		return FALSE

	if(target.buckled)
		return FALSE

	if(!GetComponent(/datum/component/carry_small))
		AddComponent(/datum/component/carry_small, target, active_hand_index)

	return TRUE
