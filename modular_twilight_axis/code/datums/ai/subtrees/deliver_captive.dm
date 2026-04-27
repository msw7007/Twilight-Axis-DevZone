/datum/ai_planning_subtree/deliver_captive

/datum/ai_planning_subtree/deliver_captive/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	. = ..()

	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return

	var/mob/living/carbon/human/captive = controller.blackboard[BB_HUMAN_NPC_CAPTURE_TARGET]
	if(!istype(captive))
		return

	if(!human_npc_is_valid_delivery_captive(captive))
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_TARGET)
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_DESTINATION)
		controller.clear_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE)
		return

	var/capture_phase = controller.blackboard[BB_HUMAN_NPC_CAPTURE_PHASE]
	if(capture_phase == HUMAN_NPC_CAPTURE_PHASE_LOOT)
		return

	var/list/captive_loot = controller.blackboard[BB_HUMAN_NPC_CAPTURE_LOOT]
	if(islist(captive_loot) && length(captive_loot) && capture_phase != HUMAN_NPC_CAPTURE_PHASE_CARRYING)
		return

	if(human_npc_has_nearby_active_hostiles(pawn, captive))
		return

	var/turf/destination = controller.blackboard[BB_HUMAN_NPC_CAPTURE_DESTINATION]
	if(!destination)
		destination = human_npc_get_captive_delivery_turf(pawn)
		if(!destination)
			return
		controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_DESTINATION, destination)

	controller.set_blackboard_key(BB_HUMAN_NPC_CAPTURE_PHASE, HUMAN_NPC_CAPTURE_PHASE_DELIVER)
	controller.queue_behavior(/datum/ai_behavior/human_npc_deliver_captive, BB_HUMAN_NPC_CAPTURE_TARGET, BB_HUMAN_NPC_CAPTURE_DESTINATION)
	return SUBTREE_RETURN_FINISH_PLANNING
