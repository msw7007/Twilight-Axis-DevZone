/datum/ai_planning_subtree/basic_melee_attack_subtree/human_npc/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/carbon/human/pawn = controller.pawn
	if(istype(pawn))
		if(pawn.pulledby?.grab_state > GRAB_PASSIVE && isliving(pawn.pulledby))
			controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, pawn.pulledby)
			controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, pawn.pulledby)
			controller.queue_behavior(/datum/ai_behavior/human_npc_anti_grab, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
			return SUBTREE_RETURN_FINISH_PLANNING

	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return

	if(isliving(target))
		var/mob/living/L = target
		if(human_npc_target_already_bound(L))
			return

	return ..()
