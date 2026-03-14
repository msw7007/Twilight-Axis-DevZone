/datum/group_ai_group
	var/id = "group_ai_group"
	var/list/datum/group_ai_host/members = list()
	var/datum/group_ai_host/leader
	var/atom/current_target
	var/current_mode = GROUP_MODE_IDLE
	var/list/pending_signals = list()
	var/list/datum/group_ai_slot/engagement_slots = list()
	var/atom/engagement_anchor

/datum/group_ai_group/New()
	..()
	SSgroup_ai.register_group(src)

/datum/group_ai_group/Destroy(force, ...)
	for(var/datum/group_ai_host/host as anything in members)
		if(!QDELETED(host))
			host.group = null
			host.release_slot()
	members.Cut()
	for(var/datum/group_ai_slot/slot as anything in engagement_slots)
		qdel(slot)
	engagement_slots.Cut()
	leader = null
	current_target = null
	engagement_anchor = null
	SSgroup_ai.unregister_group(src)
	return ..()

/datum/group_ai_group/proc/add_host(datum/group_ai_host/host)
	if(QDELETED(host))
		return
	members |= host
	host.group = src
	if(!leader || host.is_leader_candidate)
		leader = host

/datum/group_ai_group/proc/remove_host(datum/group_ai_host/host)
	members -= host
	if(host?.group == src)
		host.group = null
	host?.release_slot()
	if(leader == host)
		leader = length(members) ? members[1] : null
	if(!length(members))
		qdel(src)

/datum/group_ai_group/process(delta_time)
	if(!length(members))
		return

	collect_signals()
	refresh_target()
	recalculate_mode()
	rebuild_engagement_slots()
	assign_roles()
	assign_orders()
	process_orders(delta_time)

/datum/group_ai_group/proc/collect_signals()
	pending_signals.Cut()

	for(var/datum/group_ai_host/host as anything in members)
		if(QDELETED(host))
			continue
		pending_signals += host.drain_signals()

/datum/group_ai_group/proc/refresh_target()
	if(isliving(current_target))
		var/mob/living/L = current_target
		if(L.stat < DEAD)
			return

	current_target = null

	for(var/datum/group_ai_signal/signal as anything in pending_signals)
		if(signal.target && isliving(signal.target))
			var/mob/living/L = signal.target
			if(L.stat < DEAD)
				current_target = L
				return

	for(var/datum/group_ai_host/host as anything in members)
		var/mob/living/owner = host.get_owner()
		if(QDELETED(owner))
			continue

		for(var/mob/living/L in view(host.vision_range, owner))
			if(L == owner)
				continue
			if(L.stat >= DEAD)
				continue
			if(owner.faction_check_mob(L, TRUE))
				continue

			current_target = L
			return

/datum/group_ai_group/proc/recalculate_mode()
	if(QDELETED(current_target))
		current_mode = GROUP_MODE_IDLE
		return

	if(get_group_health_ratio() <= 0.75)
		current_mode = GROUP_MODE_LIQUIDATE
		return

	current_mode = GROUP_MODE_PRESSURE

/datum/group_ai_group/proc/rebuild_engagement_slots()
	if(QDELETED(current_target))
		clear_engagement_slots()
		return

	if(engagement_anchor == current_target && length(engagement_slots))
		for(var/datum/group_ai_slot/slot as anything in engagement_slots)
			if(QDELETED(slot) || !slot.is_valid_for_target(current_target))
				clear_engagement_slots()
				break
			else
				slot.clear_if_invalid()
		if(length(engagement_slots))
			return

	clear_engagement_slots(FALSE)
	engagement_anchor = current_target

	var/list/turfs = list()
	for(var/turf/T in view(1, get_turf(current_target)))
		if(T == get_turf(current_target))
			continue
		if(T.density)
			continue
		turfs += T

	var/index = 1
	for(var/turf/T as anything in turfs)
		var/datum/group_ai_slot/slot = new /datum/group_ai_slot(T, index++)
		engagement_slots += slot

	for(var/datum/group_ai_host/host as anything in members)
		if(QDELETED(host?.claimed_slot))
			host.claimed_slot = null
		else if(!(host.claimed_slot in engagement_slots))
			host.release_slot()

/datum/group_ai_group/proc/clear_engagement_slots(release_hosts = TRUE)
	if(release_hosts)
		for(var/datum/group_ai_host/host as anything in members)
			host?.release_slot()
	for(var/datum/group_ai_slot/slot as anything in engagement_slots)
		qdel(slot)
	engagement_slots.Cut()
	engagement_anchor = null

/datum/group_ai_group/proc/get_slot_for_host(datum/group_ai_host/host)
	if(QDELETED(host))
		return null
	if(host.claimed_slot && (host.claimed_slot in engagement_slots) && host.claimed_slot.occupant == host)
		return host.claimed_slot
	return null

/datum/group_ai_group/proc/get_best_slot_for_host(datum/group_ai_host/host)
	var/mob/living/owner = host?.get_owner()
	if(QDELETED(owner) || !length(engagement_slots))
		return null

	var/datum/group_ai_slot/best = null
	var/best_score = 1.0e31
	for(var/datum/group_ai_slot/slot as anything in engagement_slots)
		if(QDELETED(slot?.position))
			continue
		slot.clear_if_invalid()
		if(!slot.is_free() && slot.occupant != host)
			continue
		var/score = get_dist(owner, slot.position)
		if(score < best_score)
			best_score = score
			best = slot
	return best

/datum/group_ai_group/proc/get_yield_candidate_for_host(datum/group_ai_host/requester)
	if(!length(engagement_slots))
		return null

	var/datum/group_ai_host/best = null
	var/best_score = -1
	for(var/datum/group_ai_slot/slot as anything in engagement_slots)
		var/datum/group_ai_host/occupant = slot.occupant
		if(QDELETED(occupant) || occupant == requester)
			continue
		var/mob/living/owner = occupant.get_owner()
		if(QDELETED(owner))
			continue
		var/score = 0
		if((owner.health / max(owner.maxHealth, 1)) <= 0.5)
			score += 50
		if(world.time < occupant.next_melee_at)
			score += 25
		if(occupant.current_role_id != requester.current_role_id)
			score += 5
		if(score > best_score)
			best_score = score
			best = occupant
	if(best_score <= 0)
		return null
	return best

/datum/group_ai_group/proc/claim_slot(datum/group_ai_host/host, datum/group_ai_slot/slot)
	if(QDELETED(host) || QDELETED(slot))
		return FALSE
	if(slot.occupant && slot.occupant != host)
		return FALSE
	return host.claim_slot(slot)

/datum/group_ai_group/proc/request_slot_yield(datum/group_ai_host/requester)
	var/datum/group_ai_host/yielder = get_yield_candidate_for_host(requester)
	if(QDELETED(yielder))
		return FALSE
	if(yielder.yield_requested)
		return TRUE
	yielder.yield_requested = TRUE
	return TRUE

/datum/group_ai_group/proc/assign_roles()
	if(!leader && length(members))
		leader = members[1]

/datum/group_ai_group/proc/get_role_datum(datum/group_ai_host/host)
	return null

/datum/group_ai_group/proc/assign_orders()
	if(!length(members))
		return

	if(current_mode == GROUP_MODE_IDLE || QDELETED(current_target))
		for(var/datum/group_ai_host/host as anything in members)
			if(QDELETED(host) || host == leader)
				continue
			host.release_slot()
			host.start_order(new /datum/group_ai_order/follow_leader(host, leader?.get_owner()))
		return

	for(var/datum/group_ai_host/host as anything in members)
		if(QDELETED(host) || !host.can_act())
			continue

		if(host.yield_requested)
		{
			host.start_order(new /datum/group_ai_order/yield_melee_slot(host, current_target))
			continue
		}

		var/datum/group_ai_role/role = get_role_datum(host)
		if(!role)
			continue

		var/datum/group_ai_order/order = role.pick_order(src, host, current_target)
		if(!order)
			qdel(role)
			continue

		host.start_order(order)
		qdel(role)

/datum/group_ai_group/proc/process_orders(delta_time)
	for(var/datum/group_ai_host/host as anything in members)
		if(QDELETED(host))
			continue
		host.process_order(delta_time)

/datum/group_ai_group/proc/is_target_prone(atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/L = target
	return !(L.mobility_flags & MOBILITY_STAND) || L.stat >= UNCONSCIOUS

/datum/group_ai_group/proc/get_group_health_ratio()
	var/health_sum = 0
	var/max_sum = 0

	for(var/datum/group_ai_host/host as anything in members)
		var/mob/living/owner = host.get_owner()
		if(QDELETED(owner))
			continue
		health_sum += max(owner.health, 0)
		max_sum += max(owner.maxHealth, 1)

	if(!max_sum)
		return 0
	return health_sum / max_sum
