/datum/ai_planning_subtree/find_captive_loot

/datum/ai_planning_subtree/find_captive_loot/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return

	var/mob/living/carbon/human/captive = controller.blackboard[BB_HUMAN_NPC_CAPTURE_TARGET]
	var/capture_phase = controller.blackboard[BB_HUMAN_NPC_CAPTURE_PHASE]

	if(istype(captive) && captive.loc != pawn && human_npc_is_in_captive_delivery_zone(captive, pawn))
		human_npc_clear_capture_blackboard(controller)
		return

	if(capture_phase == HUMAN_NPC_CAPTURE_PHASE_CARRYING)
		if(istype(captive))
			controller.queue_behavior(/datum/ai_behavior/human_npc_deliver_captive, BB_HUMAN_NPC_CAPTURE_TARGET, BB_HUMAN_NPC_CAPTURE_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
		return

	if(capture_phase == HUMAN_NPC_CAPTURE_PHASE_DELIVER)
		if(istype(captive))
			controller.queue_behavior(/datum/ai_behavior/human_npc_deliver_captive, BB_HUMAN_NPC_CAPTURE_TARGET, BB_HUMAN_NPC_CAPTURE_DESTINATION)
			return SUBTREE_RETURN_FINISH_PLANNING
		return

	var/list/captive_loot = controller.blackboard[BB_HUMAN_NPC_CAPTURE_LOOT]
	if(islist(captive_loot) && length(captive_loot))
		if(human_npc_has_nearby_active_hostiles(pawn))
			return

		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_LOOT)
		controller.queue_behavior(/datum/ai_behavior/regear_from_captive_loot, BB_HUMAN_NPC_CAPTURE_LOOT)
		return SUBTREE_RETURN_FINISH_PLANNING

	if(!istype(captive))
		return

	if(!human_npc_is_valid_delivery_captive(captive))
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_TARGET)
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_DESTINATION)
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE)
		return

	if(human_npc_has_nearby_active_hostiles(pawn, captive))
		return

	controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_DELIVER)
	controller.queue_behavior(/datum/ai_behavior/human_npc_deliver_captive, BB_HUMAN_NPC_CAPTURE_TARGET, BB_HUMAN_NPC_CAPTURE_DESTINATION)
	return SUBTREE_RETURN_FINISH_PLANNING
