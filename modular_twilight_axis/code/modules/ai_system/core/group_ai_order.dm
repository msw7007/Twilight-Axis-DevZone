/datum/group_ai_order
	var/id = AIORDER_NONE
	var/datum/group_ai_host/host
	var/atom/target
	var/state = AI_ORDER_PENDING
	var/started_at = 0
	var/timeout = 20

/datum/group_ai_order/New(datum/group_ai_host/_host, atom/_target)
	..()
	host = _host
	target = _target

/datum/group_ai_order/proc/start()
	if(QDELETED(host))
		state = AI_ORDER_FAILED
		return FALSE
	state = AI_ORDER_RUNNING
	started_at = world.time
	return TRUE

/datum/group_ai_order/proc/tick(delta_time)
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(timeout > 0 && world.time - started_at > timeout)
		fail()
		return FALSE

	return TRUE

/datum/group_ai_order/proc/finish()
	state = AI_ORDER_DONE
	return TRUE

/datum/group_ai_order/proc/fail()
	state = AI_ORDER_FAILED
	return FALSE

/datum/group_ai_order/proc/cancel()
	if(state == AI_ORDER_DONE || state == AI_ORDER_FAILED)
		return
	state = AI_ORDER_CANCELLED

/datum/group_ai_order/follow_leader
	id = AIORDER_FOLLOW_LEADER
	timeout = 8

/datum/group_ai_order/follow_leader/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	if(host.driver.get_dist_to(target) <= 2)
		return finish()

	host.step_towards_target(target)
	return TRUE

/datum/group_ai_order/approach_target
	id = AIORDER_APPROACH_TARGET
	timeout = 10

/datum/group_ai_order/approach_target/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	if(host.driver.get_dist_to(target) <= 1)
		return finish()

	host.step_towards_target(target)
	return TRUE

/datum/group_ai_order/retreat_target
	id = AIORDER_RETREAT_TARGET
	timeout = 8

/datum/group_ai_order/retreat_target/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	if(host.driver.get_dist_to(target) >= 5)
		return finish()

	host.step_away_from_target(target)
	return TRUE

/datum/group_ai_order/melee_target
	id = AIORDER_MELEE_TARGET
	timeout = 8

/datum/group_ai_order/melee_target/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	if(host.driver.get_dist_to(target) > 1)
		host.step_towards_target(target)
		return TRUE

	if(host.do_melee(target))
		return finish()

	return TRUE

/datum/group_ai_order/ranged_target
	id = AIORDER_RANGED_TARGET
	timeout = 8

/datum/group_ai_order/ranged_target/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	var/dist = host.driver.get_dist_to(target)

	if(dist < 2)
		host.step_away_from_target(target)
		return TRUE

	if(dist > 6)
		host.step_towards_target(target)
		return TRUE

	if(host.do_ranged(target))
		return finish()

	return TRUE

/datum/group_ai_order/finish_target
	id = AIORDER_FINISH_TARGET
	timeout = 10

/datum/group_ai_order/finish_target/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	if(host.driver.get_dist_to(target) > 1)
		host.step_towards_target(target)
		return TRUE

	if(host.do_melee(target))
		return finish()

	return TRUE

/datum/group_ai_order/melee_then_retreat
	id = "melee_then_retreat"
	timeout = 12
	var/attacked = FALSE

/datum/group_ai_order/melee_then_retreat/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	var/dist = host.driver.get_dist_to(target)

	if(!attacked)
		if(dist > 1)
			host.step_towards_target(target)
			return TRUE

		if(host.do_melee(target))
			attacked = TRUE
			return TRUE

		return TRUE

	if(dist >= 3)
		return finish()

	host.step_away_from_target(target)
	return TRUE

/datum/group_ai_order/fill_melee_slot
	id = AIORDER_FILL_MELEE_SLOT
	timeout = 20

/datum/group_ai_order/fill_melee_slot/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	if(QDELETED(target))
		return fail()

	var/datum/group_ai_slot/slot = host.group?.get_slot_for_host(host)
	if(!slot)
		slot = host.group?.get_best_slot_for_host(host)
		if(!slot)
			host.group?.request_slot_yield(host)
			return TRUE
		host.group?.claim_slot(host, slot)

	if(QDELETED(slot?.position))
		return fail()

	var/mob/living/owner = host.get_owner()
	if(QDELETED(owner))
		return fail()

	if(get_turf(owner) != slot.position)
		host.step_towards_target(slot.position)
		return TRUE

	if(host.driver.get_dist_to(target) <= 1)
		host.do_melee(target)
		return TRUE

	return TRUE

/datum/group_ai_order/yield_melee_slot
	id = AIORDER_YIELD_MELEE_SLOT
	timeout = 10

/datum/group_ai_order/yield_melee_slot/tick(delta_time)
	..()
	if(state != AI_ORDER_RUNNING)
		return FALSE

	var/datum/group_ai_slot/my_slot = host.group?.get_slot_for_host(host)
	if(!my_slot)
		host.yield_requested = FALSE
		return finish()

	var/mob/living/owner = host.get_owner()
	if(QDELETED(owner))
		return fail()

	var/turf/current = get_turf(owner)
	var/turf/best = null
	var/best_score = 1.0e31
	for(var/turf/T in view(1, current))
		if(T == current || T == my_slot.position)
			continue
		if(T.density)
			continue
		if(target && get_dist(T, target) <= 1)
			continue
		var/blocked = FALSE
		for(var/datum/group_ai_slot/slot as anything in host.group?.engagement_slots)
			if(!slot.occupant)
				continue
			if(slot.position == T && slot.occupant && slot.occupant != host)
				blocked = TRUE
				break
		if(blocked)
			continue
		var/score = get_dist(T, target)
		if(score < best_score)
			best_score = score
			best = T

	if(!best)
		host.yield_requested = FALSE
		return finish()

	if(current == best)
		host.release_slot()
		host.yield_requested = FALSE
		return finish()

	host.step_towards_target(best)
	if(get_turf(owner) == best)
		host.release_slot()
		host.yield_requested = FALSE
		return finish()

	return TRUE
