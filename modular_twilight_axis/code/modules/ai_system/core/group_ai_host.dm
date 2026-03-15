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
	var/next_move_at = 0
	var/next_slot_request_at = 0
	var/next_slot_swap_at = 0

	var/melee_cd = 1 SECONDS
	var/ranged_cd = 10 SECONDS
	var/special_cd = 30 SECONDS

	var/atom/last_target
	var/atom/last_melee_target
	var/last_melee_time = 0
	var/datum/group_ai_slot/claimed_slot
	var/yield_requested = FALSE
	var/yield_until = 0

	/// Frontline policy. Keep these on the host so species/role bootstrap can override them cheaply.
	var/can_claim_melee_slot = TRUE
	var/allow_hot_swap = TRUE
	var/hot_swap_health_threshold = 0.35
	var/hot_swap_recent_damage_threshold = 0
	var/recent_damage_window = 20
	var/recent_damage_accum = 0
	var/last_damage_time = 0

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

/datum/group_ai_host/proc/consume_signal(datum/group_ai_signal/signal)
	if(QDELETED(signal))
		return

	if(signal.id == AISIG_TAKE_DAMAGE)
		var/damage = signal.context?["amount"]
		if(isnum(damage) && damage > 0)
			recent_damage_accum += damage
			last_damage_time = world.time

/datum/group_ai_host/proc/update_temporal_state()
	if(recent_damage_accum && world.time - last_damage_time > recent_damage_window)
		recent_damage_accum = 0

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
	update_temporal_state()
	if(!current_order)
		return
	current_order.tick(delta_time)
	if(current_order.state == AI_ORDER_DONE || current_order.state == AI_ORDER_FAILED || current_order.state == AI_ORDER_CANCELLED)
		QDEL_NULL(current_order)

/datum/group_ai_host/proc/release_slot()
	if(claimed_slot && claimed_slot.occupant == src)
		claimed_slot.occupant = null
	claimed_slot = null
	yield_requested = FALSE

/datum/group_ai_host/proc/get_slot_hold_cd()
	return max(4, round(melee_cd * 0.5))

/datum/group_ai_host/proc/get_slot_request_cd()
	return 5

/datum/group_ai_host/proc/get_slot_swap_cd()
	return 8

/datum/group_ai_host/proc/claim_slot(datum/group_ai_slot/slot)
	if(QDELETED(slot))
		return FALSE
	if(claimed_slot == slot && slot.occupant == src)
		return TRUE
	if(!can_claim_melee_slot)
		return FALSE

	release_slot()
	claimed_slot = slot
	slot.occupant = src
	yield_until = world.time + get_slot_hold_cd()
	return TRUE

/datum/group_ai_host/proc/get_health_ratio()
	var/mob/living/owner = get_owner()
	if(QDELETED(owner))
		return 0
	return owner.health / max(owner.maxHealth, 1)

/datum/group_ai_host/proc/should_yield_frontline()
	if(!allow_hot_swap || !claimed_slot)
		return FALSE
	if(world.time < next_slot_swap_at)
		return FALSE
	if(get_health_ratio() <= hot_swap_health_threshold)
		return TRUE
	if(hot_swap_recent_damage_threshold > 0 && recent_damage_accum >= hot_swap_recent_damage_threshold)
		return TRUE
	return FALSE

/datum/group_ai_host/proc/can_act()
	return driver?.can_act()

/datum/group_ai_host/proc/can_step_now()
	return world.time >= next_move_at

/datum/group_ai_host/proc/mark_step_used()
	next_move_at = world.time + max(1, driver?.get_move_step_delay() || 1)

/datum/group_ai_host/proc/step_towards_target(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	if(!can_step_now())
		return FALSE
	if(!driver?.step_forward(target))
		return FALSE
	mark_step_used()
	return TRUE

/datum/group_ai_host/proc/step_away_from_target(atom/target)
	if(!can_act() || QDELETED(target))
		return FALSE
	if(!can_step_now())
		return FALSE
	if(!driver?.step_backward(target))
		return FALSE
	mark_step_used()
	return TRUE

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
	if(claimed_slot)
		yield_until = max(yield_until, world.time + get_slot_hold_cd())
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
