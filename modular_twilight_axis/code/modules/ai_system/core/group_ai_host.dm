/datum/group_ai_host
	var/datum/group_ai_driver/driver
	var/datum/group_ai_group/group
	var/list/available_role_ids = list()
	var/current_role_id = AIROLE_NONE
	var/datum/group_ai_order/current_order
	var/list/local_signals = list()
	var/is_leader_candidate = FALSE
	var/vision_range = 7

	var/next_melee_at = 0
	var/next_ranged_at = 0
	var/next_special_at = 0

	var/melee_cd = 1 SECONDS
	var/ranged_cd = 10 SECONDS
	var/special_cd = 30 SECONDS

	var/atom/last_target
	var/atom/last_melee_target
	var/last_melee_time = 0
	var/datum/group_ai_slot/claimed_slot
	var/yield_requested = FALSE


/datum/group_ai_host/New(datum/group_ai_driver/_driver)
	..()
	driver = _driver
	SSgroup_ai.register_host(src)

/datum/group_ai_host/Destroy(force, ...)
	cancel_order()
	if(group)
		group.remove_host(src)
	SSgroup_ai.unregister_host(src)
	if(claimed_slot && claimed_slot.occupant == src)
		claimed_slot.occupant = null
	driver = null
	group = null
	claimed_slot = null
	available_role_ids = null
	return ..()

/datum/group_ai_host/proc/get_owner()
	return driver?.owner

/datum/group_ai_host/proc/add_role(role_id)
	if(!(role_id in available_role_ids))
		available_role_ids += role_id

/datum/group_ai_host/proc/has_role(role_id)
	return role_id in available_role_ids

/datum/group_ai_host/proc/push_signal(signal_id, atom/target = null, list/context = null)
	local_signals += new /datum/group_ai_signal(signal_id, src, target, context)

/datum/group_ai_host/proc/drain_signals()
	var/list/out = local_signals.Copy()
	local_signals.Cut()
	return out

/datum/group_ai_host/proc/cancel_order()
	if(current_order)
		current_order.cancel()
		QDEL_NULL(current_order)

/datum/group_ai_host/proc/is_same_order(datum/group_ai_order/new_order)
	if(!current_order || !new_order)
		return FALSE
	if(current_order.id != new_order.id)
		return FALSE
	if(current_order.target != new_order.target)
		return FALSE
	if(current_order.state != AI_ORDER_RUNNING && current_order.state != AI_ORDER_PENDING)
		return FALSE
	return TRUE

/datum/group_ai_host/proc/start_order(datum/group_ai_order/new_order)
	if(QDELETED(new_order))
		return FALSE

	if(is_same_order(new_order))
		qdel(new_order)
		return TRUE

	if(new_order.id != AIORDER_FILL_MELEE_SLOT && new_order.id != AIORDER_YIELD_MELEE_SLOT)
		release_slot()

	cancel_order()
	current_order = new_order
	return current_order.start()

/datum/group_ai_host/proc/process_order(delta_time)
	if(!current_order)
		return
	current_order.tick(delta_time)
	if(current_order.state == AI_ORDER_DONE || current_order.state == AI_ORDER_FAILED || current_order.state == AI_ORDER_CANCELLED)
		QDEL_NULL(current_order)

/datum/group_ai_host/proc/release_slot()
	if(claimed_slot && claimed_slot.occupant == src)
		claimed_slot.occupant = null
	claimed_slot = null

/datum/group_ai_host/proc/claim_slot(datum/group_ai_slot/slot)
	if(QDELETED(slot))
		return FALSE
	if(claimed_slot == slot && slot.occupant == src)
		return TRUE
	release_slot()
	claimed_slot = slot
	slot.occupant = src
	return TRUE

/datum/group_ai_host/proc/can_act()
	return driver?.can_act()

/datum/group_ai_host/proc/step_towards_target(atom/target)
	return driver?.step_forward(target)

/datum/group_ai_host/proc/step_away_from_target(atom/target)
	return driver?.step_backward(target)

/datum/group_ai_host/proc/do_melee(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	if(world.time < next_melee_at)
		return FALSE

	if(!driver.do_melee(target))
		return FALSE

	last_target = target
	last_melee_target = target
	last_melee_time = world.time
	next_melee_at = world.time + melee_cd + rand(0, 3)
	return TRUE

/datum/group_ai_host/proc/do_ranged(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	if(world.time < next_ranged_at)
		return FALSE

	if(!driver.do_ranged(target))
		return FALSE

	last_target = target
	next_ranged_at = world.time + ranged_cd + rand(0, 3)
	return TRUE

/datum/group_ai_host/proc/do_special(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	if(world.time < next_special_at)
		return FALSE

	if(!driver.do_special(target))
		return FALSE

	last_target = target
	next_special_at = world.time + special_cd + rand(0, 3)
	return TRUE
