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
