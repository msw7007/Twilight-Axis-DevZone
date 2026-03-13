/datum/group_ai_group
	var/id = "group_ai_group"
	var/list/datum/group_ai_host/members = list()
	var/datum/group_ai_host/leader
	var/atom/current_target
	var/current_mode = GROUP_MODE_IDLE
	var/list/pending_signals = list()

/datum/group_ai_group/New()
	..()
	SSgroup_ai.register_group(src)

/datum/group_ai_group/Destroy(force, ...)
	for(var/datum/group_ai_host/host as anything in members)
		if(!QDELETED(host))
			host.group = null
	members.Cut()
	leader = null
	current_target = null
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
			host.start_order(new /datum/group_ai_order/follow_leader(host, leader?.get_owner()))
		return

	for(var/datum/group_ai_host/host as anything in members)
		if(QDELETED(host) || !host.can_act())
			continue

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
