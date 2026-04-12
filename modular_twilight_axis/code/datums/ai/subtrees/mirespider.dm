/datum/ai_planning_subtree/basic_ranged_attack_subtree/mirespider_lurker/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return

	if(isliving(target))
		var/mob/living/carbon/L = target
		if(L)
			if(L.stat || L.getBruteLoss() > 500)
				controller.set_blackboard_key(BB_BASIC_MOB_COCOON_TARGET, L)
				controller.queue_behavior(/datum/ai_behavior/cocoon_target, BB_BASIC_MOB_COCOON_TARGET)
				return SUBTREE_RETURN_FINISH_PLANNING

	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/lurker = controller.pawn
	if(lurker)
		lurker.clear_followers_if_any()

	controller.queue_behavior(ranged_attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING
