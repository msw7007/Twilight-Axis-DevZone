/datum/ai_planning_subtree/basic_ranged_attack_subtree
	var/datum/ai_behavior/basic_kite/kite_behavior = null

/datum/ai_planning_subtree/basic_ranged_attack_subtree/proc/get_current_target(datum/ai_controller/controller)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return null
	return target

/datum/ai_planning_subtree/basic_ranged_attack_subtree/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()

	var/atom/target = get_current_target(controller)
	if(!target)
		return

	var/dist = get_dist(controller.pawn, target)

	// ВПЛОТНУЮ → КАЙТ
	if(kite_behavior && dist <= 1)
		controller.queue_behavior(
			kite_behavior,
			BB_BASIC_MOB_CURRENT_TARGET,
			BB_TARGETTING_DATUM,
			BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION
		)
		return SUBTREE_RETURN_FINISH_PLANNING

	// ИНАЧЕ → СТРЕЛЯЕМ
	controller.queue_behavior(
		ranged_attack_behavior,
		BB_BASIC_MOB_CURRENT_TARGET,
		BB_TARGETTING_DATUM,
		BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION
	)

	return SUBTREE_RETURN_FINISH_PLANNING
