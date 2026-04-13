/datum/ai_planning_subtree/kick_attack/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return

	if(isliving(target))
		var/mob/living/L = target
		if(human_npc_should_preserve_capture_target(L))
			return

	return ..()
